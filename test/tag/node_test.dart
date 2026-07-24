import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/tag/tag.dart';

void main() {
  group('TagValue.parse', () {
    test('simple tag has empty value', () {
      final tag = TagValue.parse('simple');
      expect(tag.name, 'simple');
      expect(tag.value, '');
    });

    test('namespaced tag splits on first colon', () {
      final tag = TagValue.parse('namespace:value');
      expect(tag.name, 'namespace');
      expect(tag.value, 'value');
    });

    test('only the first colon splits', () {
      final tag = TagValue.parse('a:b:c');
      expect(tag.name, 'a');
      expect(tag.value, 'b:c');
    });
  });

  group('TagValue.toString', () {
    test('simple tag', () {
      expect(TagValue('tag').toString(), 'tag');
    });

    test('tag with value', () {
      expect(TagValue('key', 'value').toString(), 'key:value');
    });

    test('value with spaces is quoted', () {
      expect(TagValue('key', 'value with spaces').toString(), 'key:"value with spaces"');
    });

    test('quotes inside values are escaped', () {
      expect(TagValue('key', 'value "with" quotes').toString(), 'key:"value \\"with\\" quotes"');
    });

    test('isRoot parameter is accepted', () {
      expect(TagValue('key', 'value').toString(isRoot: false), 'key:value');
    });
  });

  group('TagValue equality', () {
    test('equal when name and value match', () {
      expect(TagValue('a', 'b'), TagValue('a', 'b'));
    });

    test('not equal when value differs', () {
      expect(TagValue('a', 'b') == TagValue('a', 'c'), isFalse);
    });

    test('not equal when name differs', () {
      expect(TagValue('a', 'b') == TagValue('c', 'b'), isFalse);
    });

    test('hashCode matches for equal values', () {
      expect(TagValue('a', 'b').hashCode, TagValue('a', 'b').hashCode);
    });
  });

  group('TagValue.compareTo', () {
    test('values sort before non-values', () {
      expect(TagValue('a', 'b').compareTo(TagValue('a')), -1);
      expect(TagValue('a').compareTo(TagValue('a', 'b')), 1);
    });

    test('alphabetical by name', () {
      expect(TagValue('a').compareTo(TagValue('b')), lessThan(0));
      expect(TagValue('b').compareTo(TagValue('a')), greaterThan(0));
    });

    test('falls back to value when names equal', () {
      expect(TagValue('a', 'b').compareTo(TagValue('a', 'c')), lessThan(0));
    });

    test('equal tags compare as zero', () {
      expect(TagValue('a', 'b').compareTo(TagValue('a', 'b')), 0);
    });
  });

  group('TagGroup', () {
    test('name joins prefix and children', () {
      final group = TagGroup('', [TagValue('a'), TagValue('b')]);
      expect(group.name, '( a b )');
    });

    test('name includes prefix', () {
      final group = TagGroup('-', [TagValue('a'), TagValue('b')]);
      expect(group.name, '-( a b )');
    });

    test('value is always empty', () {
      final group = TagGroup('-', [TagValue('a')]);
      expect(group.value, '');
    });

    test('toString equals name', () {
      final group = TagGroup('~', [TagValue('a'), TagValue('b')]);
      expect(group.toString(), '~( a b )');
    });

    test('equality compares prefix and children', () {
      expect(
        TagGroup('-', [TagValue('a'), TagValue('b')]),
        TagGroup('-', [TagValue('a'), TagValue('b')]),
      );
    });

    test('not equal when prefix differs', () {
      expect(
        TagGroup('-', [TagValue('a')]) == TagGroup('~', [TagValue('a')]),
        isFalse,
      );
    });

    test('not equal when children differ', () {
      expect(
        TagGroup('-', [TagValue('a')]) == TagGroup('-', [TagValue('b')]),
        isFalse,
      );
    });

    test('hashCode matches for equal groups', () {
      expect(
        TagGroup('-', [TagValue('a'), TagValue('b')]).hashCode,
        TagGroup('-', [TagValue('a'), TagValue('b')]).hashCode,
      );
    });
  });

  group('TagComment', () {
    test('name is prefixed with hash', () {
      expect(TagComment('hello').name, '#hello');
    });

    test('value is always empty', () {
      expect(TagComment('hello').value, '');
    });

    test('toString equals name', () {
      expect(TagComment('hello').toString(), '#hello');
    });

    test('equality compares comment text', () {
      expect(TagComment('a'), TagComment('a'));
      expect(TagComment('a') == TagComment('b'), isFalse);
    });

    test('hashCode matches for equal comments', () {
      expect(TagComment('a').hashCode, TagComment('a').hashCode);
    });
  });
}
