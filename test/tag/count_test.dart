import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/tag/tag.dart';

import '../helpers/test_posts.dart';

void main() {
  group('countTags', () {
    test('counts occurrences of each tag', () {
      final counts = countTags(['a', 'b', 'a', 'c', 'a']);
      expect(counts['a'], 3);
      expect(counts['b'], 1);
      expect(counts['c'], 1);
    });

    test('empty list produces empty map', () {
      expect(countTags([]), isEmpty);
    });

    test('accumulates into an existing map', () {
      final existing = {'a': 2};
      final counts = countTags(['a', 'b'], existing);
      expect(counts['a'], 3);
      expect(counts['b'], 1);
    });

    test('returns the same map instance passed in', () {
      final existing = <String, int>{};
      final counts = countTags(['a'], existing);
      expect(identical(counts, existing), isTrue);
    });
  });

  group('CountedTag', () {
    test('holds category, tag, and count', () {
      final tag = CountedTag(category: 'general', tag: 'fox', count: 3);
      expect(tag.category, 'general');
      expect(tag.tag, 'fox');
      expect(tag.count, 3);
    });
  });

  group('countTagsByPosts', () {
    test('counts tags across posts grouped by category', () {
      final posts = [
        makePost(tags: {
          'general': ['fox', 'canine'],
          'species': ['dog'],
        }),
        makePost(tags: {
          'general': ['fox'],
          'species': ['wolf'],
        }),
      ];

      final counted = countTagsByPosts(posts);

      final fox = counted.firstWhere((e) => e.tag == 'fox');
      expect(fox.category, 'general');
      expect(fox.count, 2);

      final canine = counted.firstWhere((e) => e.tag == 'canine');
      expect(canine.category, 'general');
      expect(canine.count, 1);

      final dog = counted.firstWhere((e) => e.tag == 'dog');
      expect(dog.category, 'species');
      expect(dog.count, 1);
    });

    test('empty post list produces empty result', () {
      expect(countTagsByPosts([]), isEmpty);
    });

    test('handles posts with missing categories', () {
      final posts = [
        makePost(tags: {
          'general': ['fox'],
        }),
      ];

      final counted = countTagsByPosts(posts);
      final fox = counted.firstWhere((e) => e.tag == 'fox');
      expect(fox.count, 1);
    });
  });
}
