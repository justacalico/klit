import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/constants.dart';
import '../models/models.dart';
import 'api_parsing.dart';

/// Service for e926 API communication
class ApiService {
  late final Dio _dio;
  String _baseUrl;
  String? _authHeader;
  ProxyConfig _proxyConfig = const ProxyConfig();

  // Rate limiting
  DateTime? _lastRequestTime;
  static const _minRequestInterval = Duration(milliseconds: 500);

  ApiService({String? baseUrl, ProxyConfig? proxyConfig})
    : _baseUrl = baseUrl ?? ApiConstants.defaultHost {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: ApiConstants.defaultHeaders,
      ),
    );

    // Apply initial proxy config if provided
    if (proxyConfig != null) {
      _proxyConfig = proxyConfig;
      _applyProxyConfig();
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          await _enforceRateLimit();
          // Only set auth header if not already explicitly provided in the request
          if (_authHeader != null &&
              !options.headers.containsKey('Authorization')) {
            options.headers['Authorization'] = _authHeader;
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          // Check for Cloudflare challenge in response
          if (response.data is String &&
              (response.data as String).contains('Just a moment')) {
            handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                error: const ApiException(
                  message:
                      'Service temporarily unavailable. Please try again or sign in.',
                  statusCode: 503,
                ),
                type: DioExceptionType.badResponse,
              ),
            );
            return;
          }
          handler.next(response);
        },
        onError: (error, handler) {
          handler.next(_handleDioError(error));
        },
      ),
    );
  }

  void _applyProxyConfig() {
    // Skip proxy configuration on web platform
    if (kIsWeb) return;

    if (_proxyConfig.enabled && _proxyConfig.host.isNotEmpty) {
      _dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.findProxy = (uri) => _proxyConfig.findProxyString;

          // Set up proxy authentication if enabled
          if (_proxyConfig.useAuthentication &&
              _proxyConfig.username != null &&
              _proxyConfig.username!.isNotEmpty) {
            client.addProxyCredentials(
              _proxyConfig.host,
              _proxyConfig.port,
              'Basic',
              HttpClientBasicCredentials(
                _proxyConfig.username!,
                _proxyConfig.password ?? '',
              ),
            );
          }

          // Allow bad certificates for proxy servers (common for local proxies)
          // In production, you might want to make this configurable
          client.badCertificateCallback = (cert, host, port) => true;

          return client;
        },
      );
    } else {
      // Reset to default adapter when proxy is disabled
      _dio.httpClientAdapter = IOHttpClientAdapter();
    }
  }

  void setProxyConfig(ProxyConfig config) {
    _proxyConfig = config;
    _applyProxyConfig();
  }

  ProxyConfig get proxyConfig => _proxyConfig;

  Future<void> _enforceRateLimit() async {
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest < _minRequestInterval) {
        await Future.delayed(_minRequestInterval - timeSinceLastRequest);
      }
    }
    _lastRequestTime = DateTime.now();
  }

  DioException _handleDioError(DioException error) {
    ApiException apiError;

    // Check for Cloudflare challenge in error response
    final responseData = error.response?.data;
    if (responseData is String && responseData.contains('Just a moment')) {
      apiError = const ApiException(
        message:
            'Service temporarily unavailable. Please try again or sign in.',
        statusCode: 503,
      );
      return DioException(
        requestOptions: error.requestOptions,
        error: apiError,
        response: error.response,
        type: error.type,
      );
    }

    switch (error.response?.statusCode) {
      case 401:
        apiError = ApiException.unauthorized();
        break;
      case 403:
        // Check if it's actually a Cloudflare block
        if (responseData is String &&
            responseData.contains('<!DOCTYPE html>')) {
          apiError = const ApiException(
            message:
                'Service temporarily unavailable. Please try again or sign in.',
            statusCode: 503,
          );
        } else {
          apiError = const ApiException(
            message: 'Access forbidden. Please sign in to continue.',
            statusCode: 403,
          );
        }
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

  /// Current API base URL (e.g. for resolving relative avatar URLs).
  String get baseUrl => _baseUrl;

  void setBaseUrl(String baseUrl) {
    _baseUrl = baseUrl;
    _dio.options.baseUrl = baseUrl;
  }

  void setAuth(String username, String apiKey) {
    _authHeader = Account(
      id: '',
      username: username,
      apiKey: apiKey,
      host: _baseUrl,
      createdAt: DateTime.now(),
    ).basicAuthHeader;
  }

  void clearAuth() {
    _authHeader = null;
  }

  void _restoreState(String baseUrl, String? authHeader) {
    _baseUrl = baseUrl;
    _authHeader = authHeader;
    _dio.options.baseUrl = baseUrl;
  }

  /// Runs [fn] with [hostUrl] and optional [username]/[apiKey], then restores previous base URL and auth.
  Future<T> runWithHost<T>(
    String hostUrl,
    String? username,
    String? apiKey,
    Future<T> Function() fn,
  ) async {
    final savedBase = _baseUrl;
    final savedAuth = _authHeader;
    var u = hostUrl.trim();
    if (u.endsWith('/')) u = u.substring(0, u.length - 1);
    setBaseUrl(u);
    if (username != null && apiKey != null) {
      setAuth(username, apiKey);
    } else {
      clearAuth();
    }
    try {
      return await fn();
    } finally {
      _restoreState(savedBase, savedAuth);
    }
  }

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

  /// Get user by ID (e621/e926: GET /users/{id}.json)
  Future<ApiResult<User>> getUserById(int id) async {
    try {
      final response = await _dio.get('/users/$id.json');

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

      final response = await _dio.get(
        ApiConstants.postsEndpoint,
        queryParameters: queryParams,
        options: Options(responseType: ResponseType.plain),
      );

      if (response.statusCode == 200 && response.data != null) {
        final posts = await compute(
          parsePostsFromJsonString,
          response.data as String,
        );
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

  Future<ApiResult<Post>> getPostById(int id) async {
    try {
      final response = await _dio.get(
        '/posts/$id.json',
        options: Options(responseType: ResponseType.plain),
      );

      if (response.statusCode == 200 && response.data != null) {
        final post = await compute(
          parseSinglePostFromJsonString,
          response.data as String,
        );
        if (post != null) return ApiResult.success(post);
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
  /// If [customDate] is provided, uses that as the starting date instead of now
  Future<ApiResult<List<Post>>> getPopularPosts({
    String scale = 'day',
    int page = 1,
    bool safeMode = false,
    DateTime? customDate,
  }) async {
    try {
      // Build date range tags based on scale
      final baseDate = customDate ?? DateTime.now();
      String dateTags;

      if (customDate != null) {
        // Custom date mode - show posts from that specific period
        final dateStr =
            '${baseDate.year}-${baseDate.month.toString().padLeft(2, '0')}-${baseDate.day.toString().padLeft(2, '0')}';
        switch (scale) {
          case 'week':
            final endDate = baseDate.add(const Duration(days: 7));
            final endStr =
                '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
            dateTags = 'date:>=$dateStr date:<$endStr';
            break;
          case 'month':
            final endDate = DateTime(
              baseDate.year,
              baseDate.month + 1,
              baseDate.day,
            );
            final endStr =
                '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
            dateTags = 'date:>=$dateStr date:<$endStr';
            break;
          case 'day':
          default:
            dateTags = 'date:$dateStr';
            break;
        }
      } else {
        // Normal mode - show posts from now going back
        switch (scale) {
          case 'week':
            final weekAgo = baseDate.subtract(const Duration(days: 7));
            dateTags =
                'date:>=${weekAgo.year}-${weekAgo.month.toString().padLeft(2, '0')}-${weekAgo.day.toString().padLeft(2, '0')}';
            break;
          case 'month':
            final monthAgo = baseDate.subtract(const Duration(days: 30));
            dateTags =
                'date:>=${monthAgo.year}-${monthAgo.month.toString().padLeft(2, '0')}-${monthAgo.day.toString().padLeft(2, '0')}';
            break;
          case 'day':
          default:
            final yesterday = baseDate.subtract(const Duration(days: 1));
            dateTags =
                'date:>=${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
            break;
        }
      }

      // Add rating:safe tag if safe mode is enabled
      final tags = safeMode
          ? '$dateTags order:score rating:safe'
          : '$dateTags order:score';

      final response = await _dio.get(
        ApiConstants.postsEndpoint,
        queryParameters: {
          'tags': tags,
          'limit': ApiConstants.defaultPageSize,
          'page': page,
        },
        options: Options(responseType: ResponseType.plain),
      );

      if (response.statusCode == 200 && response.data != null) {
        final posts = await compute(
          parsePostsFromJsonString,
          response.data as String,
        );
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
        queryParameters: {'tags': tags, 'page': page, 'limit': limit},
        options: Options(responseType: ResponseType.plain),
      );

      if (response.statusCode == 200 && response.data != null) {
        final posts = await compute(
          parsePostsFromJsonString,
          response.data as String,
        );
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
        queryParameters: {'score': score, 'no_unvote': false},
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
  Future<ApiResult<List<Comment>>> getComments(
    int postId, {
    int page = 1,
  }) async {
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
