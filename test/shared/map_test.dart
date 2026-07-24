import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/shared/data/map.dart';

enum _TestEnum { foo, bar }

void main() {
  group('QueryMapping.toQuery', () {
    test('serializes flat map', () {
      final result = <String, dynamic>{'a': '1', 'b': '2'}.toQuery();
      expect(result, {'a': '1', 'b': '2'});
    });

    test('serializes nested map with bracket notation', () {
      final result = <String, dynamic>{
        'outer': {'inner': 'value'},
      }.toQuery();
      expect(result, {'outer[inner]': 'value'});
    });

    test('serializes deeply nested maps', () {
      final result = <String, dynamic>{
        'a': {'b': {'c': 'd'}},
      }.toQuery();
      expect(result, {'a[b][c]': 'd'});
    });

    test('serializes iterable values as comma-joined', () {
      final result = <String, dynamic>{'tags': ['foo', 'bar']}.toQuery();
      expect(result, {'tags': 'foo,bar'});
    });

    test('serializes enum values using name', () {
      final result = <String, dynamic>{'mode': _TestEnum.foo}.toQuery();
      expect(result, {'mode': 'foo'});
    });

    test('serializes iterable with enum values', () {
      final result = <String, dynamic>{
        'modes': [_TestEnum.foo, _TestEnum.bar],
      }.toQuery();
      expect(result, {'modes': 'foo,bar'});
    });

    test('skips null values', () {
      final result = <String, dynamic>{'a': null, 'b': '2'}.toQuery();
      expect(result, {'b': '2'});
    });

    test('skips null values inside iterables', () {
      final result = <String, dynamic>{
        'tags': [null, 'foo', null, 'bar'],
      }.toQuery();
      expect(result, {'tags': 'foo,bar'});
    });

    test('skips empty iterables', () {
      final result = <String, dynamic>{'tags': <String>[]}.toQuery();
      expect(result, <String, String>{});
    });

    test('returns empty map for empty input', () {
      final result = <String, dynamic>{}.toQuery();
      expect(result, <String, String>{});
    });

    test('sorts output by key', () {
      final result = <String, dynamic>{
        'zebra': '1',
        'apple': '2',
        'mango': '3',
      }.toQuery();
      expect(result.keys.toList(), ['apple', 'mango', 'zebra']);
    });

    test('sorts nested keys', () {
      final result = <String, dynamic>{
        'z': {'a': '1'},
        'a': {'b': '2'},
      }.toQuery();
      expect(result.keys.toList(), ['a[b]', 'z[a]']);
    });

    test('handles mixed content', () {
      final result = <String, dynamic>{
        'a': '1',
        'b': null,
        'c': ['x', 'y'],
        'd': {'e': 'f'},
        'g': _TestEnum.bar,
      }.toQuery();
      expect(result, {
        'a': '1',
        'c': 'x,y',
        'd[e]': 'f',
        'g': 'bar',
      });
    });

    test('serializes integer values', () {
      final result = <String, dynamic>{'count': 42}.toQuery();
      expect(result, {'count': '42'});
    });
  });

  group('QueryMapHandling.clone', () {
    test('creates an equal but independent copy', () {
      final original = <String, String>{'a': '1', 'b': '2'};
      final cloned = original.clone();
      expect(cloned, original);
      cloned['c'] = '3';
      expect(original.containsKey('c'), isFalse);
    });

    test('clone of empty map is empty', () {
      final cloned = <String, String>{}.clone();
      expect(cloned, <String, String>{});
    });
  });

  group('QueryMapHandling.setOrRemove', () {
    test('sets a value', () {
      final map = <String, String>{};
      map.setOrRemove('a', '1');
      expect(map, {'a': '1'});
    });

    test('removes a key when value is null', () {
      final map = <String, String>{'a': '1', 'b': '2'};
      map.setOrRemove('a', null);
      expect(map, {'b': '2'});
    });

    test('does nothing when removing absent key', () {
      final map = <String, String>{'a': '1'};
      map.setOrRemove('z', null);
      expect(map, {'a': '1'});
    });

    test('overwrites existing value', () {
      final map = <String, String>{'a': '1'};
      map.setOrRemove('a', '2');
      expect(map, {'a': '2'});
    });
  });

  group('MappableListExtension.toMap', () {
    test('converts entries to a map', () {
      final entries = [
        const MapEntry('a', 1),
        const MapEntry('b', 2),
      ];
      expect(entries.toMap(), {'a': 1, 'b': 2});
    });

    test('handles empty iterable', () {
      final entries = <MapEntry<String, int>>[];
      expect(entries.toMap(), <String, int>{});
    });

    test('later entries overwrite earlier ones', () {
      final entries = [
        const MapEntry('a', 1),
        const MapEntry('a', 2),
      ];
      expect(entries.toMap(), {'a': 2});
    });
  });
}
