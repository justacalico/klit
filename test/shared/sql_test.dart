import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/shared/data/sql.dart';

void main() {
  group('JsonSqlConverter.list', () {
    test('roundtrips a list of strings', () {
      final converter = JsonSqlConverter.list<String>();
      const value = ['a', 'b', 'c'];
      final sql = converter.toSql(value);
      final result = converter.fromSql(sql);
      expect(result, value);
    });

    test('roundtrips a list of integers', () {
      final converter = JsonSqlConverter.list<int>();
      const value = [1, 2, 3];
      final sql = converter.toSql(value);
      final result = converter.fromSql(sql);
      expect(result, value);
    });

    test('roundtrips an empty list', () {
      final converter = JsonSqlConverter.list<String>();
      const value = <String>[];
      final sql = converter.toSql(value);
      final result = converter.fromSql(sql);
      expect(result, value);
    });

    test('toSql encodes as JSON array', () {
      final converter = JsonSqlConverter.list<String>();
      expect(converter.toSql(['a', 'b']), '["a","b"]');
    });

    test('fromSql decodes JSON array', () {
      final converter = JsonSqlConverter.list<int>();
      expect(converter.fromSql('[1,2,3]'), [1, 2, 3]);
    });
  });

  group('JsonSqlConverter.map', () {
    test('roundtrips a map of string to int', () {
      final converter = JsonSqlConverter.map<int>();
      const value = {'a': 1, 'b': 2};
      final sql = converter.toSql(value);
      final result = converter.fromSql(sql);
      expect(result, value);
    });

    test('roundtrips a map of string to string', () {
      final converter = JsonSqlConverter.map<String>();
      const value = {'a': 'x', 'b': 'y'};
      final sql = converter.toSql(value);
      final result = converter.fromSql(sql);
      expect(result, value);
    });

    test('roundtrips an empty map', () {
      final converter = JsonSqlConverter.map<int>();
      const value = <String, int>{};
      final sql = converter.toSql(value);
      final result = converter.fromSql(sql);
      expect(result, value);
    });

    test('toSql encodes as JSON object', () {
      final converter = JsonSqlConverter.map<int>();
      expect(converter.toSql({'a': 1}), '{"a":1}');
    });

    test('fromSql decodes JSON object', () {
      final converter = JsonSqlConverter.map<String>();
      expect(converter.fromSql('{"a":"x"}'), {'a': 'x'});
    });
  });

  group('JsonSqlConverter default', () {
    test('roundtrips an integer', () {
      const converter = JsonSqlConverter<int>();
      const value = 42;
      final sql = converter.toSql(value);
      final result = converter.fromSql(sql);
      expect(result, value);
    });

    test('roundtrips a string', () {
      const converter = JsonSqlConverter<String>();
      const value = 'hello';
      final sql = converter.toSql(value);
      final result = converter.fromSql(sql);
      expect(result, value);
    });

    test('roundtrips a boolean', () {
      const converter = JsonSqlConverter<bool>();
      const value = true;
      final sql = converter.toSql(value);
      final result = converter.fromSql(sql);
      expect(result, value);
    });

    test('roundtrips a double', () {
      const converter = JsonSqlConverter<double>();
      const value = 3.14;
      final sql = converter.toSql(value);
      final result = converter.fromSql(sql);
      expect(result, value);
    });

    test('toSql encodes integer as JSON number', () {
      const converter = JsonSqlConverter<int>();
      expect(converter.toSql(42), '42');
    });

    test('toSql encodes string as JSON string', () {
      const converter = JsonSqlConverter<String>();
      expect(converter.toSql('hello'), '"hello"');
    });
  });
}
