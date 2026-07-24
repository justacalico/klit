import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/tag/tag.dart';

void main() {
  group('TagMap parsing', () {
    test('empty string produces no entries', () {
      final map = TagMap('');
      expect(map.entries, isEmpty);
    });

    test('null produces no entries', () {
      final map = TagMap();
      expect(map.entries, isEmpty);
    });

    test('two simple tags', () {
      final map = TagMap('tag1 tag2');
      expect(map.keys.toList(), ['tag1', 'tag2']);
      expect(map.values.toList(), ['', '']);
    });

    test('namespaced tag', () {
      final map = TagMap('namespace:value');
      expect(map['namespace'], 'value');
    });

    test('mixed namespaced and simple', () {
      final map = TagMap('key:value other');
      expect(map['key'], 'value');
      expect(map['other'], '');
    });
  });

  group('TagMap.from', () {
    test('builds from a map', () {
      final map = TagMap.from({'a': 'b', 'c': null});
      expect(map['a'], 'b');
      expect(map['c'], '');
    });

    test('empty when given null', () {
      final map = TagMap.from();
      expect(map.entries, isEmpty);
    });
  });

  group('TagMap.fromIterable', () {
    test('builds from entries', () {
      final map = TagMap.fromIterable([
        const MapEntry('a', 'b'),
        const MapEntry('c', null),
      ]);
      expect(map['a'], 'b');
      expect(map['c'], '');
    });

    test('empty when given empty iterable', () {
      final map = TagMap.fromIterable([]);
      expect(map.entries, isEmpty);
    });
  });

  group('operator []', () {
    test('returns value for known key', () {
      final map = TagMap('key:value');
      expect(map['key'], 'value');
    });

    test('returns null for unknown key', () {
      final map = TagMap('key:value');
      expect(map['missing'], isNull);
    });
  });

  group('operator []=', () {
    test('sets a new value', () {
      final map = TagMap('');
      map['key'] = 'value';
      expect(map['key'], 'value');
    });

    test('updates an existing value', () {
      final map = TagMap('key:old');
      map['key'] = 'new';
      expect(map['key'], 'new');
    });

    test('setting null removes the entry', () {
      final map = TagMap('key:value');
      map['key'] = null;
      expect(map.containsKey('key'), isFalse);
    });

    test('setting empty string removes the entry', () {
      final map = TagMap('key:value');
      map['key'] = '';
      expect(map.containsKey('key'), isFalse);
    });
  });

  group('add', () {
    test('adds a new key', () {
      final map = TagMap('');
      map.add('key', 'value');
      expect(map['key'], 'value');
    });

    test('adds a key without value', () {
      final map = TagMap('');
      map.add('key');
      expect(map['key'], '');
    });
  });

  group('remove', () {
    test('returns the removed value', () {
      final map = TagMap('key:value');
      expect(map.remove('key'), 'value');
      expect(map.containsKey('key'), isFalse);
    });

    test('returns null for unknown key', () {
      final map = TagMap('key:value');
      expect(map.remove('missing'), isNull);
    });
  });

  group('clear', () {
    test('removes all entries', () {
      final map = TagMap('a b c');
      map.clear();
      expect(map.entries, isEmpty);
    });
  });

  group('getters', () {
    test('entries', () {
      final map = TagMap('a:1 b:2');
      final entries = map.entries.toList();
      expect(entries.length, 2);
      expect(entries[0].key, 'a');
      expect(entries[0].value, '1');
      expect(entries[1].key, 'b');
      expect(entries[1].value, '2');
    });

    test('keys', () {
      final map = TagMap('a:1 b:2');
      expect(map.keys.toList(), ['a', 'b']);
    });

    test('values', () {
      final map = TagMap('a:1 b:2');
      expect(map.values.toList(), ['1', '2']);
    });

    test('tags', () {
      final map = TagMap('a:1 b');
      expect(map.tags, ['a:1', 'b']);
    });
  });

  group('toString', () {
    test('roundtrips simple tags', () {
      expect(TagMap('tag1 tag2').toString(), 'tag1 tag2');
    });

    test('roundtrips namespaced tags', () {
      expect(TagMap('a:b c:d').toString(), 'a:b c:d');
    });

    test('empty string', () {
      expect(TagMap('').toString(), '');
    });

    test('quoted values with spaces', () {
      final map = TagMap('key:"value with spaces"');
      expect(map['key'], 'value with spaces');
      expect(map.toString(), 'key:"value with spaces"');
    });
  });
}
