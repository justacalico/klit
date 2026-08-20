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
      expect(const TagValue('tag').toString(), 'tag');
    });

    test('tag with value', () {
      expect(const TagValue('key', 'value').toString(), 'key:value');
    });

    test('value with spaces is quoted', () {
      expect(const TagValue('key', 'value with spaces').toString(), 'key:"value with spaces"');
    });

    test('quotes inside values are escaped', () {
      expect(const TagValue('key', 'value "with" quotes').toString(), r'key:"value \"with\" quotes"');
    });

    test('isRoot parameter is accepted', () {
      expect(const TagValue('key', 'value').toString(isRoot: false), 'key:value');
    });
  });

  group('TagValue equality', () {
    test('equal when name and value match', () {
      expect(const TagValue('a', 'b'), const TagValue('a', 'b'));
    });

    test('not equal when value differs', () {
      expect(const TagValue('a', 'b') == const TagValue('a', 'c'), isFalse);
    });

    test('not equal when name differs', () {
      expect(const TagValue('a', 'b') == const TagValue('c', 'b'), isFalse);
    });

    test('hashCode matches for equal values', () {
      expect(const TagValue('a', 'b').hashCode, const TagValue('a', 'b').hashCode);
    });
  });

  group('TagValue.compareTo', () {
    test('values sort before non-values', () {
      expect(const TagValue('a', 'b').compareTo(const TagValue('a')), -1);
      expect(const TagValue('a').compareTo(const TagValue('a', 'b')), 1);
    });

    test('alphabetical by name', () {
      expect(const TagValue('a').compareTo(const TagValue('b')), lessThan(0));
      expect(const TagValue('b').compareTo(const TagValue('a')), greaterThan(0));
    });

    test('falls back to value when names equal', () {
      expect(const TagValue('a', 'b').compareTo(const TagValue('a', 'c')), lessThan(0));
    });

    test('equal tags compare as zero', () {
      expect(const TagValue('a', 'b').compareTo(const TagValue('a', 'b')), 0);
    });
  });

  group('TagGroup', () {
    test('name joins prefix and children', () {
      const group = TagGroup('', [TagValue('a'), TagValue('b')]);
      expect(group.name, '( a b )');
    });

    test('name includes prefix', () {
      const group = TagGroup('-', [TagValue('a'), TagValue('b')]);
      expect(group.name, '-( a b )');
    });

    test('value is always empty', () {
      const group = TagGroup('-', [TagValue('a')]);
      expect(group.value, '');
    });

    test('toString equals name', () {
      const group = TagGroup('~', [TagValue('a'), TagValue('b')]);
      expect(group.toString(), '~( a b )');
    });

    test('equality compares prefix and children', () {
      expect(
        const TagGroup('-', [TagValue('a'), TagValue('b')]),
        const TagGroup('-', [TagValue('a'), TagValue('b')]),
      );
    });

    test('not equal when prefix differs', () {
      expect(
        const TagGroup('-', [TagValue('a')]) == const TagGroup('~', [TagValue('a')]),
        isFalse,
      );
    });

    test('not equal when children differ', () {
      expect(
        const TagGroup('-', [TagValue('a')]) == const TagGroup('-', [TagValue('b')]),
        isFalse,
      );
    });

    test('hashCode matches for equal groups', () {
      expect(
        const TagGroup('-', [TagValue('a'), TagValue('b')]).hashCode,
        const TagGroup('-', [TagValue('a'), TagValue('b')]).hashCode,
      );
    });
  });

  group('TagComment', () {
    test('name is prefixed with hash', () {
      expect(const TagComment('hello').name, '#hello');
    });

    test('value is always empty', () {
      expect(const TagComment('hello').value, '');
    });

    test('toString equals name', () {
      expect(const TagComment('hello').toString(), '#hello');
    });

    test('equality compares comment text', () {
      expect(const TagComment('a'), const TagComment('a'));
      expect(const TagComment('a') == const TagComment('b'), isFalse);
    });

    test('hashCode matches for equal comments', () {
      expect(const TagComment('a').hashCode, const TagComment('a').hashCode);
    });
  });
}
