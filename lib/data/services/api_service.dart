import 'dart:async';
import 'package:dio/dio.dart';
import '../../core/constants/constants.dart';
import '../models/models.dart';

/// Service for e621 API communication
class ApiService {
  late final Dio _dio;
  String _baseUrl;
  String? _authHeader;

  // Rate limiting
  DateTime? _lastRequestTime;
  static const _minRequestInterval = Duration(milliseconds: 500);

  ApiService({String? baseUrl})
      : _baseUrl = baseUrl ?? ApiConstants.defaultHost {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: ApiConstants.defaultHeaders,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          await _enforceRateLimit();
          if (_authHeader != null) {
            options.headers['Authorization'] = _authHeader;
          }
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(_handleDioError(error));
        },
      ),
    );
  }

  /// Enforce rate limiting
  Future<void> _enforceRateLimit() async {
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest < _minRequestInterval) {
        await Future.delayed(_minRequestInterval - timeSinceLastRequest);
      }
    }
    _lastRequestTime = DateTime.now();
  }

  /// Handle Dio errors and convert to ApiException
  DioException _handleDioError(DioException error) {
    ApiException apiError;

    switch (error.response?.statusCode) {
      case 401:
        apiError = ApiException.unauthorized();
        break;
      case 403:
        apiError = const ApiException(
          message: 'Access forbidden. Check your permissions.',
          statusCode: 403,
        );
        break;
      case 404:
        apiError = ApiException.notFound();
        break;
      case 429:
        apiError = ApiException.rateLimit();
        break;
      case 500:
      case 502:
      case 503:
        apiError = ApiException.server();
        break;
      default:
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.connectionError) {
          apiError = ApiException.network();
        } else {
          apiError = ApiException.unknown(error);
        }
    }

    return DioException(
      requestOptions: error.requestOptions,
      error: apiError,
      response: error.response,
      type: error.type,
    );
  }

  /// Update the base URL
  void setBaseUrl(String baseUrl) {
    _baseUrl = baseUrl;
    _dio.options.baseUrl = baseUrl;
  }

  /// Set authentication credentials
  void setAuth(String username, String apiKey) {
    _authHeader = Account(
      id: '',
      username: username,
      apiKey: apiKey,
      host: _baseUrl,
      createdAt: DateTime.now(),
    ).basicAuthHeader;
  }

  /// Clear authentication
  void clearAuth() {
    _authHeader = null;
  }

  /// Verify credentials by making a test request
  Future<ApiResult<bool>> verifyCredentials(
    String username,
    String apiKey,
  ) async {
    try {
      final tempAuth = Account(
        id: '',
        username: username,
        apiKey: apiKey,
        host: _baseUrl,
        createdAt: DateTime.now(),
      ).basicAuthHeader;

      final response = await _dio.get(
        '/users/$username.json',
        options: Options(headers: {'Authorization': tempAuth}),
      );

      if (response.statusCode == 200 && response.data != null) {
        return ApiResult.success(true);
      }
      return ApiResult.failure(ApiException.unauthorized());
    } on DioException catch (e) {
      if (e.error is ApiException) {
        return ApiResult.failure(e.error as ApiException);
      }
      return ApiResult.failure(ApiException.unknown(e));
    } catch (e) {
      return ApiResult.failure(ApiException.unknown(e));
    }
  }

  /// Get posts with optional search parameters
  Future<ApiResult<List<Post>>> getPosts({
    int page = 1,
    int limit = 50,
    String? tags,
    String? rating,
    String? order,
  }) async {
    try {
      final params = PostSearchParams(
        tags: tags,
        rating: rating,
        order: order,
        page: page,
        limit: limit,
      );

      final queryParams = params.toQueryParams();
      print('Making request to ${ApiConstants.postsEndpoint} with params: $queryParams');

      final response = await _dio.get(
        ApiConstants.postsEndpoint,
        queryParameters: queryParams,
      );

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final postsData = response.data['posts'] as List<dynamic>;
        print('Got ${postsData.length} posts');
        final posts = postsData
            .map((e) => Post.fromJson(e as Map<String, dynamic>))
            .where((p) => p.file.url != null) // Filter out posts without URLs
            .toList();
        print('After filtering: ${posts.length} posts with URLs');
        return ApiResult.success(posts);
      }
      return ApiResult.failure(ApiException.unknown());
    } on DioException catch (e) {
      print('API Error: ${e.message}');
      print('Response: ${e.response?.data}');
      if (e.error is ApiException) {
        return ApiResult.failure(e.error as ApiException);
      }
      return ApiResult.failure(ApiException.unknown(e));
    } catch (e) {
      print('Exception: $e');
      return ApiResult.failure(ApiException.unknown(e));
    }
  }

  /// Get a single post by ID
  Future<ApiResult<Post>> getPostById(int id) async {
    try {
      final response = await _dio.get('/posts/$id.json');

      if (response.statusCode == 200 && response.data != null) {
        final post = Post.fromJson(response.data['post'] as Map<String, dynamic>);
        return ApiResult.success(post);
      }
      return ApiResult.failure(ApiException.notFound('Post'));
    } on DioException catch (e) {
      if (e.error is ApiException) {
        return ApiResult.failure(e.error as ApiException);
      }
      return ApiResult.failure(ApiException.unknown(e));
    } catch (e) {
      return ApiResult.failure(ApiException.unknown(e));
    }
  }

  /// Get popular posts
  Future<ApiResult<List<Post>>> getPopularPosts({
    String scale = 'day',
    int page = 1,
  }) async {
    try {
      // Popular endpoint uses 'date' parameter with format YYYY-MM-DD
      // Or we can use the posts endpoint with order:score and date filter
      final response = await _dio.get(
        ApiConstants.postsEndpoint,
        queryParameters: {
          'tags': 'order:score',
          'limit': ApiConstants.defaultPageSize,
          'page': page,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final postsData = response.data['posts'] as List<dynamic>;
        final posts = postsData
            .map((e) => Post.fromJson(e as Map<String, dynamic>))
            .where((p) => p.file.url != null)
            .toList();
        return ApiResult.success(posts);
      }
      return ApiResult.failure(ApiException.unknown());
    } on DioException catch (e) {
      print('Popular posts error: ${e.message}');
      print('Response: ${e.response?.data}');
      if (e.error is ApiException) {
        return ApiResult.failure(e.error as ApiException);
      }
      return ApiResult.failure(ApiException.unknown(e));
    } catch (e) {
      print('Popular posts exception: $e');
      return ApiResult.failure(ApiException.unknown(e));
    }
  }

  /// Search for tags
  Future<ApiResult<List<Tag>>> searchTags({
    required String query,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.tagsEndpoint,
        queryParameters: {
          'search[name_matches]': '$query*',
          'search[order]': 'count',
          'limit': limit,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final tagsData = response.data as List<dynamic>;
        final tags = tagsData
            .map((e) => Tag.fromJson(e as Map<String, dynamic>))
            .toList();
        return ApiResult.success(tags);
      }
      return ApiResult.failure(ApiException.unknown());
    } on DioException catch (e) {
      if (e.error is ApiException) {
        return ApiResult.failure(e.error as ApiException);
      }
      return ApiResult.failure(ApiException.unknown(e));
    } catch (e) {
      return ApiResult.failure(ApiException.unknown(e));
    }
  }

  /// Add a post to favorites
  Future<ApiResult<bool>> addFavorite(int postId) async {
    try {
      final response = await _dio.post(
        ApiConstants.favoritesEndpoint,
        data: {'post_id': postId},
      );

      return ApiResult.success(response.statusCode == 201);
    } on DioException catch (e) {
      if (e.error is ApiException) {
        return ApiResult.failure(e.error as ApiException);
      }
      return ApiResult.failure(ApiException.unknown(e));
    } catch (e) {
      return ApiResult.failure(ApiException.unknown(e));
    }
  }

  /// Remove a post from favorites
  Future<ApiResult<bool>> removeFavorite(int postId) async {
    try {
      final response = await _dio.delete('/favorites/$postId.json');
      return ApiResult.success(response.statusCode == 204);
    } on DioException catch (e) {
      if (e.error is ApiException) {
        return ApiResult.failure(e.error as ApiException);
      }
      return ApiResult.failure(ApiException.unknown(e));
    } catch (e) {
      return ApiResult.failure(ApiException.unknown(e));
    }
  }
}
