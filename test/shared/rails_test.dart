import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/shared/data/rails.dart';

Response _response(dynamic data) =>
    Response(requestOptions: RequestOptions(path: '/test'), data: data);

void main() {
  group('unwrapRailsArray', () {
    test('replaces empty object with empty list', () {
      final response = _response(<String, dynamic>{});
      final result = unwrapRailsArray(response);
      expect(result.data, <dynamic>[]);
    });

    test('extracts value from single-key object', () {
      final response = _response(<String, dynamic>{
        'posts': [1, 2, 3],
      });
      final result = unwrapRailsArray(response);
      expect(result.data, [1, 2, 3]);
    });

    test('leaves multi-key object unchanged', () {
      final data = <String, dynamic>{
        'posts': [1, 2],
        'meta': {'count': 2},
      };
      final response = _response(data);
      final result = unwrapRailsArray(response);
      expect(result.data, data);
    });

    test('leaves non-object data unchanged', () {
      final response = _response([1, 2, 3]);
      final result = unwrapRailsArray(response);
      expect(result.data, [1, 2, 3]);
    });

    test('leaves string data unchanged', () {
      final response = _response('hello');
      final result = unwrapRailsArray(response);
      expect(result.data, 'hello');
    });

    test('extracts single value from single-key object', () {
      final response = _response(<String, dynamic>{'value': 42});
      final result = unwrapRailsArray(response);
      expect(result.data, 42);
    });

    test('returns the same response instance', () {
      final response = _response(<String, dynamic>{});
      final result = unwrapRailsArray(response);
      expect(identical(result, response), isTrue);
    });
  });
}
