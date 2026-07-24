import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/shared/data/dio.dart';

void main() {
  group('forceOptions', () {
    test('force=true uses CachePolicy.refresh', () {
      final options = forceOptions(true);
      final config = options.extra!['@cache_options@'] as ClientCacheConfig;
      expect(config.policy, CachePolicy.refresh);
    });

    test('force=false uses CachePolicy.request', () {
      final options = forceOptions(false);
      final config = options.extra!['@cache_options@'] as ClientCacheConfig;
      expect(config.policy, CachePolicy.request);
    });

    test('force=null uses CachePolicy.request', () {
      final options = forceOptions(null);
      final config = options.extra!['@cache_options@'] as ClientCacheConfig;
      expect(config.policy, CachePolicy.request);
    });
  });

  group('ClientException', () {
    test('constructor sets properties', () {
      final request = RequestOptions(path: '/test');
      final exception = ClientException(
        requestOptions: request,
        message: 'something failed',
        type: DioExceptionType.badResponse,
      );
      expect(exception.requestOptions, same(request));
      expect(exception.message, 'something failed');
      expect(exception.type, DioExceptionType.badResponse);
    });

    test('fromDio copies all fields from a DioException', () {
      final request = RequestOptions(path: '/api');
      final dioException = DioException(
        requestOptions: request,
        message: 'timeout',
        type: DioExceptionType.connectionTimeout,
      );
      final clientException = ClientException.fromDio(dioException);
      expect(clientException.requestOptions, same(request));
      expect(clientException.message, 'timeout');
      expect(clientException.type, DioExceptionType.connectionTimeout);
    });

    test('database factory creates with db path', () {
      final exception = ClientException.database(
        'db error',
        StackTrace.current,
      );
      expect(exception.requestOptions.path, '@db');
      expect(exception.error, 'db error');
      expect(exception.message, 'Database error');
    });

    test('database factory accepts custom message', () {
      final exception = ClientException.database(
        'db error',
        StackTrace.current,
        message: 'custom db message',
      );
      expect(exception.message, 'custom db message');
    });
  });

  group('validateCall', () {
    test('returns true when call succeeds', () async {
      final result = await validateCall(() async {});
      expect(result, isTrue);
    });

    test('returns false when call throws ClientException', () async {
      final result = await validateCall(
        () async => throw ClientException(
          requestOptions: RequestOptions(path: '/test'),
        ),
      );
      expect(result, isFalse);
    });

    test('returns true when call returns a value', () async {
      final result = await validateCall(() async => 42);
      expect(result, isTrue);
    });
  });

  group('rateLimit', () {
    test('returns the result of the call', () async {
      final result = await rateLimit(Future.value(42));
      expect(result, 42);
    });

    test('ensures minimum duration elapses', () async {
      final stopwatch = Stopwatch()..start();
      await rateLimit(
        Future.value('done'),
        const Duration(milliseconds: 100),
      );
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(90));
    });

    test('uses default 500ms duration when not specified', () async {
      final stopwatch = Stopwatch()..start();
      await rateLimit(Future.value('done'));
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(450));
    });
  });

  group('ClientCacheConfig', () {
    test('copyWith preserves existing values', () {
      final config = ClientCacheConfig(
        policy: CachePolicy.refresh,
        pageParam: 'page',
      );
      final copied = config.copyWith(maxAge: const Duration(seconds: 60));
      expect(copied.policy, CachePolicy.refresh);
      expect(copied.pageParam, 'page');
      expect(copied.maxAge, const Duration(seconds: 60));
    });

    test('fromExtra returns null when no cache options present', () {
      final request = RequestOptions(path: '/test');
      expect(ClientCacheConfig.fromExtra(request), isNull);
    });

    test('fromExtra returns config when present', () {
      final config = ClientCacheConfig(policy: CachePolicy.refresh);
      final request = RequestOptions(
        path: '/test',
        extra: config.toExtra(),
      );
      final extracted = ClientCacheConfig.fromExtra(request);
      expect(extracted, isNotNull);
      expect(extracted!.policy, CachePolicy.refresh);
    });
  });
}
