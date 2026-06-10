import 'dart:io';

import 'package:dio/dio.dart';
import 'package:kilt/client/client.dart';
import 'package:kilt/identity/identity.dart';
import 'package:kilt/logs/logs.dart';
import 'package:kilt/settings/settings.dart';
import 'package:kilt/shared/shared.dart';

/// Create a default [Dio] instance for the given [Identity].
/// Includes user agent, logging and caching.
Dio createDefaultDio(Identity identity, {CacheStore? cache}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: normalizeHostUrl(identity.host),
      headers: {
        HttpHeaders.userAgentHeader: AppInfo.instance.userAgent,
        ...?identity.headers,
      },
      sendTimeout: const Duration(seconds: 30),
      connectTimeout: const Duration(seconds: 30),
      validateStatus: (status) => status != null && status < 400,
    ),
  );
  dio.interceptors.add(NewlineReplaceInterceptor());
  dio.interceptors.add(LoggingDioInterceptor());
  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (err, handler) {
        if (err is ClientException) {
          handler.reject(err);
        } else {
          handler.reject(ClientException.fromDio(err));
        }
      },
    ),
  );
  if (cache != null) {
    dio.interceptors.add(
      ClientCacheInterceptor(
        options: ClientCacheConfig(
          store: cache,
          maxAge: const Duration(minutes: 5),
          pageParam: 'page',
        ),
      ),
    );
  }
  return dio;
}
