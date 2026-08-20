// SPDX-License-Identifier: AGPL-3.0

import 'package:kilt/post/post.dart';
import 'package:kilt/tag/tag.dart';

Map<String, int> countTags(List<String> tags, [Map<String, int>? counts]) {
  counts ??= {};

  for (final tag in tags) {
    counts[tag] = (counts[tag] ?? 0) + 1;
  }

  return counts;
}

List<CountedTag> countTagsByPosts(List<Post> posts) {
  final categoryCounts = <String, Map<String, int>>{};
  for (final category in TagCategory.names) {
    categoryCounts[category] = {};
  }
  final counted = <CountedTag>[];

  for (final post in posts) {
    for (final category in TagCategory.names) {
      final tags = post.tags[category] ?? [];
      categoryCounts[category] = countTags(tags, categoryCounts[category]);
    }
  }

  for (final category in categoryCounts.entries) {
    for (final tags in category.value.entries) {
      counted.add(
        CountedTag(category: category.key, tag: tags.key, count: tags.value),
      );
    }
  }

  return counted;
}

class CountedTag {
  CountedTag({required this.category, required this.tag, required this.count});

  final String category;
  final String tag;
  final int count;
}
