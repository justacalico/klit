import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/tag/tag.dart';

void main() {
  group('tagToRaw', () {
    test('removes a leading dash', () {
      expect(tagToRaw('-tag'), 'tag');
    });

    test('removes a leading tilde', () {
      expect(tagToRaw('~tag'), 'tag');
    });

    test('leaves a plain tag untouched', () {
      expect(tagToRaw('tag'), 'tag');
    });

    test('handles multiple tags', () {
      expect(tagToRaw('tag1 tag2'), 'tag1 tag2');
    });

    test('removes prefixes from multiple tags', () {
      expect(tagToRaw('-tag1 ~tag2'), 'tag1 tag2');
    });
  });

  group('tagToName', () {
    test('replaces underscores with spaces', () {
      expect(tagToName('tag_with_underscores'), 'tag with underscores');
    });

    test('joins multiple tags with commas', () {
      expect(tagToName('tag1 tag2'), 'tag1, tag2');
    });

    test('replaces underscores across multiple tags', () {
      expect(tagToName('tag_one tag_two'), 'tag one, tag two');
    });
  });

  group('tagToTitle', () {
    test('removes prefix and underscores', () {
      expect(tagToTitle('-tag_with_underscores'), 'tag with underscores');
    });

    test('removes tilde prefix and underscores', () {
      expect(tagToTitle('~tag_with_underscores'), 'tag with underscores');
    });
  });

  group('TagCategory.byId', () {
    test('0 is general', () {
      expect(TagCategory.byId(0), TagCategory.general);
    });

    test('1 is artist', () {
      expect(TagCategory.byId(1), TagCategory.artist);
    });

    test('2 is contributor', () {
      expect(TagCategory.byId(2), TagCategory.contributor);
    });

    test('3 is copyright', () {
      expect(TagCategory.byId(3), TagCategory.copyright);
    });

    test('4 is character', () {
      expect(TagCategory.byId(4), TagCategory.character);
    });

    test('5 is species', () {
      expect(TagCategory.byId(5), TagCategory.species);
    });

    test('6 is invalid', () {
      expect(TagCategory.byId(6), TagCategory.invalid);
    });

    test('7 is meta', () {
      expect(TagCategory.byId(7), TagCategory.meta);
    });

    test('8 is lore', () {
      expect(TagCategory.byId(8), TagCategory.lore);
    });
  });

  group('TagCategory.byName', () {
    test('finds general', () {
      expect(TagCategory.byName('general'), TagCategory.general);
    });

    test('finds artist', () {
      expect(TagCategory.byName('artist'), TagCategory.artist);
    });

    test('is case insensitive', () {
      expect(TagCategory.byName('ARTIST'), TagCategory.artist);
    });

    test('returns null for unknown name', () {
      expect(TagCategory.byName('nonexistent'), isNull);
    });
  });

  group('TagCategory.names', () {
    test('contains all category names', () {
      final names = TagCategory.names;
      for (final category in TagCategory.values) {
        expect(names, contains(category.name));
      }
      expect(names.length, TagCategory.values.length);
    });
  });

  group('TagCategory.id', () {
    test('every category has the expected id', () {
      const expected = {
        TagCategory.general: 0,
        TagCategory.artist: 1,
        TagCategory.contributor: 2,
        TagCategory.copyright: 3,
        TagCategory.character: 4,
        TagCategory.species: 5,
        TagCategory.invalid: 6,
        TagCategory.meta: 7,
        TagCategory.lore: 8,
      };
      for (final entry in expected.entries) {
        expect(entry.key.id, entry.value);
      }
    });
  });

  group('filterArtists', () {
    test('removes excluded entries', () {
      expect(
        filterArtists(['artist1', 'epilepsy_warning', 'artist2']),
        ['artist1', 'artist2'],
      );
    });

    test('removes avoid_posting', () {
      expect(filterArtists(['avoid_posting']), isEmpty);
    });

    test('empty list stays empty', () {
      expect(filterArtists([]), isEmpty);
    });

    test('removes all excluded tags', () {
      expect(
        filterArtists([
          'epilepsy_warning',
          'conditional_dnp',
          'sound_warning',
          'avoid_posting',
        ]),
        isEmpty,
      );
    });

    test('keeps non-excluded artists', () {
      expect(filterArtists(['real_artist']), ['real_artist']);
    });
  });
}
