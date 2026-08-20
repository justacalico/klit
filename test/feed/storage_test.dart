import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/feed/data/feed.dart';
import 'package:kilt/feed/data/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('getFeeds', () {
    test('returns empty list when nothing is stored', () async {
      final feeds = await getFeeds();
      expect(feeds, isEmpty);
    });

    test('returns empty list when stored value is empty string', () async {
      SharedPreferences.setMockInitialValues({'feeds': ''});
      final feeds = await getFeeds();
      expect(feeds, isEmpty);
    });

    test('returns parsed feeds from valid json', () async {
      const feed = Feed(
        id: 'f1',
        name: 'Feed One',
        mediaType: Feed.mediaTypeImage,
        includeTags: ['tag1'],
      );
      final json = jsonEncode([feed.toJson()]);
      SharedPreferences.setMockInitialValues({'feeds': json});
      final feeds = await getFeeds();
      expect(feeds.length, 1);
      expect(feeds.first.id, 'f1');
      expect(feeds.first.name, 'Feed One');
      expect(feeds.first.includeTags, ['tag1']);
    });

    test('returns empty list on invalid json', () async {
      SharedPreferences.setMockInitialValues({'feeds': '{invalid json}'});
      final feeds = await getFeeds();
      expect(feeds, isEmpty);
    });

    test('filters out non-map entries', () async {
      SharedPreferences.setMockInitialValues({
        'feeds': jsonEncode(['not a map', 42, null]),
      });
      final feeds = await getFeeds();
      expect(feeds, isEmpty);
    });
  });

  group('setFeeds', () {
    test('stores feeds and roundtrips through getFeeds', () async {
      final feeds = [
        const Feed(
          id: 'f1',
          name: 'Feed One',
          mediaType: Feed.mediaTypeVideo,
          includeTags: ['a', 'b'],
          excludeTags: ['c'],
        ),
        const Feed(
          id: 'f2',
          name: 'Feed Two',
          mediaType: Feed.mediaTypeImage,
        ),
      ];
      await setFeeds(feeds);
      final restored = await getFeeds();
      expect(restored.length, 2);
      expect(restored[0].id, 'f1');
      expect(restored[0].mediaType, Feed.mediaTypeVideo);
      expect(restored[0].includeTags, ['a', 'b']);
      expect(restored[0].excludeTags, ['c']);
      expect(restored[1].id, 'f2');
      expect(restored[1].mediaType, Feed.mediaTypeImage);
    });

    test('stores empty list', () async {
      await setFeeds([]);
      final restored = await getFeeds();
      expect(restored, isEmpty);
    });
  });
}
