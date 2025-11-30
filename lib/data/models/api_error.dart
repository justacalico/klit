/// API error class
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  const ApiException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';

  /// Factory for network errors
  factory ApiException.network([String? message]) {
    return ApiException(
      message: message ?? 'Network error. Please check your connection.',
      statusCode: null,
    );
  }

  /// Factory for unauthorized errors
  factory ApiException.unauthorized() {
    return const ApiException(
      message: 'Invalid credentials. Please check your username and API key.',
      statusCode: 401,
    );
  }

  /// Factory for rate limit errors
  factory ApiException.rateLimit() {
    return const ApiException(
      message: 'Rate limit exceeded. Please wait before making more requests.',
      statusCode: 429,
    );
  }

  /// Factory for not found errors
  factory ApiException.notFound([String? resource]) {
    return ApiException(
      message: '${resource ?? 'Resource'} not found.',
      statusCode: 404,
    );
  }

  /// Factory for server errors
  factory ApiException.server([String? message]) {
    return ApiException(
      message: message ?? 'Server error. Please try again later.',
      statusCode: 500,
    );
  }

  /// Factory for unknown errors
  factory ApiException.unknown([dynamic error]) {
    return ApiException(
      message: 'An unexpected error occurred.',
      originalError: error,
    );
  }
}

/// Result wrapper for API operations
class ApiResult<T> {
  final T? data;
  final ApiException? error;

  const ApiResult._({this.data, this.error});

  factory ApiResult.success(T data) => ApiResult._(data: data);
  factory ApiResult.failure(ApiException error) => ApiResult._(error: error);

  bool get isSuccess => error == null;
  bool get isFailure => error != null;

  R when<R>({
    required R Function(T data) success,
    required R Function(ApiException error) failure,
  }) {
    if (isSuccess) {
      return success(data as T);
    } else {
      return failure(error!);
    }
  }
}
