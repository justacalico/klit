import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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

  /// Get user profile by username
  Future<ApiResult<User>> getUserProfile(String username) async {
    try {
      final response = await _dio.get('/users/$username.json');

      if (response.statusCode == 200 && response.data != null) {
        final user = User.fromJson(response.data as Map<String, dynamic>);
        return ApiResult.success(user);
      }
      return ApiResult.failure(ApiException.notFound());
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
  /// If [safeMode] is true, only safe-rated posts will be returned
  Future<ApiResult<List<Post>>> getPosts({
    int page = 1,
    int limit = 50,
    String? tags,
    String? rating,
    String? order,
    bool safeMode = false,
  }) async {
    try {
      // If safe mode is enabled, override rating to safe
      final effectiveRating = safeMode ? 's' : rating;
      
      final params = PostSearchParams(
        tags: tags,
        rating: effectiveRating,
        order: order,
        page: page,
        limit: limit,
      );

      final queryParams = params.toQueryParams();
      if (kDebugMode) {
        print('Making request to ${ApiConstants.postsEndpoint} with params: $queryParams');
      }

      final response = await _dio.get(
        ApiConstants.postsEndpoint,
        queryParameters: queryParams,
      );

      if (kDebugMode) {
        print('Response status: ${response.statusCode}');
      }

      if (response.statusCode == 200 && response.data != null) {
        final postsData = response.data['posts'] as List<dynamic>;
        if (kDebugMode) {
          print('Got ${postsData.length} posts');
        }
        final posts = postsData
            .map((e) => Post.fromJson(e as Map<String, dynamic>))
            .where((p) => p.file.url != null) // Filter out posts without URLs
            .toList();
        if (kDebugMode) {
          print('After filtering: ${posts.length} posts with URLs');
        }
        return ApiResult.success(posts);
      }
      return ApiResult.failure(ApiException.unknown());
    } on DioException catch (e) {
      if (kDebugMode) {
        print('API Error: ${e.message}');
      }
      if (kDebugMode) {
        print('Response: ${e.response?.data}');
      }
      if (e.error is ApiException) {
        return ApiResult.failure(e.error as ApiException);
      }
      return ApiResult.failure(ApiException.unknown(e));
    } catch (e) {
      if (kDebugMode) {
        print('Exception: $e');
      }
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

  /// Get popular posts - uses posts endpoint with order:score and date range
  /// If [safeMode] is true, only safe-rated posts will be returned
  Future<ApiResult<List<Post>>> getPopularPosts({
    String scale = 'day',
    int page = 1,
    bool safeMode = false,
  }) async {
    try {
      // Build date range tags based on scale
      final now = DateTime.now();
      String dateTags;
      
      switch (scale) {
        case 'week':
          final weekAgo = now.subtract(const Duration(days: 7));
          dateTags = 'date:>=${weekAgo.year}-${weekAgo.month.toString().padLeft(2, '0')}-${weekAgo.day.toString().padLeft(2, '0')}';
          break;
        case 'month':
          final monthAgo = now.subtract(const Duration(days: 30));
          dateTags = 'date:>=${monthAgo.year}-${monthAgo.month.toString().padLeft(2, '0')}-${monthAgo.day.toString().padLeft(2, '0')}';
          break;
        case 'day':
        default:
          final yesterday = now.subtract(const Duration(days: 1));
          dateTags = 'date:>=${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
          break;
      }
      
      // Add rating:safe tag if safe mode is enabled
      final tags = safeMode ? '$dateTags order:score rating:safe' : '$dateTags order:score';
      
      final response = await _dio.get(
        ApiConstants.postsEndpoint,
        queryParameters: {
          'tags': tags,
          'limit': ApiConstants.defaultPageSize,
          'page': page,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final postsData = response.data['posts'] as List<dynamic>;
        final posts = postsData
            .where((e) => e != null && e is Map<String, dynamic>)
            .map((e) => Post.fromJson(e as Map<String, dynamic>))
            .where((p) => p.file.url != null)
            .toList();
        return ApiResult.success(posts);
      }
      return ApiResult.failure(ApiException.unknown());
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Popular posts error: ${e.message}');
      }
      if (kDebugMode) {
        print('Response: ${e.response?.data}');
      }
      if (e.error is ApiException) {
        return ApiResult.failure(e.error as ApiException);
      }
      return ApiResult.failure(ApiException.unknown(e));
    } catch (e) {
      if (kDebugMode) {
        print('Popular posts exception: $e');
      }
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

  /// Get user's favorite posts
  /// If [safeMode] is true, only safe-rated posts will be returned
  Future<ApiResult<List<Post>>> getFavorites({
    required String username,
    int page = 1,
    int limit = 50,
    bool safeMode = false,
  }) async {
    try {
      // Add rating:safe tag if safe mode is enabled
      final tags = safeMode ? 'fav:$username rating:safe' : 'fav:$username';
      
      final response = await _dio.get(
        ApiConstants.postsEndpoint,
        queryParameters: {
          'tags': tags,
          'page': page,
          'limit': limit,
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
        data: FormData.fromMap({'post_id': postId}),
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

  /// Vote on a post (1 for upvote, -1 for downvote)
  Future<ApiResult<PostScore>> votePost(int postId, int score) async {
    try {
      final response = await _dio.post(
        '/posts/$postId/votes.json',
        queryParameters: {
          'score': score,
          'no_unvote': false,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final scoreData = PostScore(
          up: response.data['up'] as int? ?? 0,
          down: response.data['down'] as int? ?? 0,
          total: response.data['score'] as int? ?? 0,
        );
        return ApiResult.success(scoreData);
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

  /// Get comments for a post
  Future<ApiResult<List<Comment>>> getComments(int postId, {int page = 1}) async {
    try {
      final response = await _dio.get(
        '/comments.json',
        queryParameters: {
          'search[post_id]': postId,
          'group_by': 'comment',
          'page': page,
          'limit': 50,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final commentsData = response.data as List<dynamic>;
        final comments = commentsData
            .map((e) => Comment.fromJson(e as Map<String, dynamic>))
            .toList();
        return ApiResult.success(comments);
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

  /// Post a comment on a post
  Future<ApiResult<Comment>> postComment(int postId, String body) async {
    try {
      final response = await _dio.post(
        '/comments.json',
        data: FormData.fromMap({
          'comment[post_id]': postId,
          'comment[body]': body,
        }),
      );

      if (response.statusCode == 201 && response.data != null) {
        final comment = Comment.fromJson(response.data as Map<String, dynamic>);
        return ApiResult.success(comment);
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
}
