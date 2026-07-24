import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/client/data/newline.dart';
import 'package:mocktail/mocktail.dart';

class _MockResponseInterceptorHandler extends Mock
    implements ResponseInterceptorHandler {}

void main() {
  late NewlineReplaceInterceptor interceptor;
  late _MockResponseInterceptorHandler handler;

  setUp(() {
    interceptor = NewlineReplaceInterceptor();
    handler = _MockResponseInterceptorHandler();
    registerFallbackValue(
      Response<dynamic>(requestOptions: RequestOptions(path: '')),
    );
    when(() => handler.next(any())).thenAnswer((_) {});
  });

  Response<String> makeResponse(String data) => Response<String>(
        data: data,
        requestOptions: RequestOptions(path: ''),
      );

  group('NewlineReplaceInterceptor.onResponse', () {
    test('replaces \\r\\n with \\n in string response', () {
      final response = makeResponse('line1\r\nline2\r\nline3');
      interceptor.onResponse(response, handler);
      expect(response.data, 'line1\nline2\nline3');
    });

    test('leaves string without \\r\\n unchanged', () {
      final response = makeResponse('line1\nline2\nline3');
      interceptor.onResponse(response, handler);
      expect(response.data, 'line1\nline2\nline3');
    });

    test('handles empty string', () {
      final response = makeResponse('');
      interceptor.onResponse(response, handler);
      expect(response.data, '');
    });

    test('handles single \\r\\n', () {
      final response = makeResponse('a\r\nb');
      interceptor.onResponse(response, handler);
      expect(response.data, 'a\nb');
    });

    test('does not modify non-string response data', () {
      final response = Response<Map<String, dynamic>>(
        data: {'key': 'value\r\nmore'},
        requestOptions: RequestOptions(path: ''),
      );
      interceptor.onResponse(response, handler);
      expect(response.data, {'key': 'value\r\nmore'});
    });

    test('calls handler.next', () {
      final response = makeResponse('test\r\ndata');
      interceptor.onResponse(response, handler);
      verify(() => handler.next(any())).called(1);
    });
  });
}
