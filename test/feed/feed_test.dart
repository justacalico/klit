import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/feed/data/feed.dart';

void main() {
  group('Feed.fromJson', () {
    test('complete json', () {
      final json = {
        'id': 'feed1',
        'name': 'My Feed',
        'mediaType': 'image',
        'includeTags': ['tag1', 'tag2'],
        'orTags': ['or1', 'or2'],
        'excludeTags': ['bad1'],
        'rating': 's',
        'order': 'score_asc',
        'excludeFavorites': true,
        'subfeeds': [
          {'id': 'sub1', 'name': 'Sub 1', 'includeTags': ['extra']},
        ],
      };
      final feed = Feed.fromJson(json);
      expect(feed.id, 'feed1');
      expect(feed.name, 'My Feed');
      expect(feed.mediaType, 'image');
      expect(feed.includeTags, ['tag1', 'tag2']);
      expect(feed.orTags, ['or1', 'or2']);
      expect(feed.excludeTags, ['bad1']);
      expect(feed.rating, 's');
      expect(feed.order, 'score_asc');
      expect(feed.excludeFavorites, isTrue);
      expect(feed.subfeeds.length, 1);
      expect(feed.subfeeds.first.id, 'sub1');
      expect(feed.subfeeds.first.includeTags, ['extra']);
    });

    test('missing optional fields default correctly', () {
      final json = {
        'id': 'feed2',
        'name': 'Minimal',
        'mediaType': 'image',
      };
      final feed = Feed.fromJson(json);
      expect(feed.rating, isNull);
      expect(feed.order, 'id_desc');
      expect(feed.excludeFavorites, isFalse);
      expect(feed.includeTags, isEmpty);
      expect(feed.orTags, isEmpty);
      expect(feed.excludeTags, isEmpty);
      expect(feed.subfeeds, isEmpty);
    });

    test('legacy isVideo=true maps to video', () {
      final json = {
        'id': 'feed3',
        'name': 'Video Feed',
        'isVideo': true,
      };
      final feed = Feed.fromJson(json);
      expect(feed.mediaType, Feed.mediaTypeVideo);
    });

    test('legacy isVideo=false maps to image', () {
      final json = {
        'id': 'feed4',
        'name': 'Image Feed',
        'isVideo': false,
      };
      final feed = Feed.fromJson(json);
      expect(feed.mediaType, Feed.mediaTypeImage);
    });

    test('invalid mediaType falls back to isVideo check', () {
      final json = {
        'id': 'feed5',
        'name': 'Invalid',
        'mediaType': 'something_wrong',
        'isVideo': true,
      };
      final feed = Feed.fromJson(json);
      expect(feed.mediaType, Feed.mediaTypeVideo);
    });

    test('invalid mediaType with isVideo=false falls back to image', () {
      final json = {
        'id': 'feed6',
        'name': 'Invalid',
        'mediaType': 'something_wrong',
        'isVideo': false,
      };
      final feed = Feed.fromJson(json);
      expect(feed.mediaType, Feed.mediaTypeImage);
    });

    test('trims and filters empty tags', () {
      final json = {
        'id': 'feed7',
        'name': 'Trim',
        'mediaType': 'image',
        'includeTags': ['  tag1  ', '', '  '],
      };
      final feed = Feed.fromJson(json);
      expect(feed.includeTags, ['tag1']);
    });
  });

  group('Feed.toJson', () {
    test('roundtrip', () {
      const feed = Feed(
        id: 'rt1',
        name: 'Roundtrip',
        mediaType: Feed.mediaTypeAll,
        includeTags: ['a', 'b'],
        orTags: ['c'],
        excludeTags: ['d'],
        rating: 'e',
        order: 'id_asc',
        excludeFavorites: true,
        subfeeds: [
          SubFeed(id: 's1', name: 'S1', includeTags: ['x']),
        ],
      );
      final json = feed.toJson();
      final restored = Feed.fromJson(json);
      expect(restored.id, feed.id);
      expect(restored.name, feed.name);
      expect(restored.mediaType, feed.mediaType);
      expect(restored.includeTags, feed.includeTags);
      expect(restored.orTags, feed.orTags);
      expect(restored.excludeTags, feed.excludeTags);
      expect(restored.rating, feed.rating);
      expect(restored.order, feed.order);
      expect(restored.excludeFavorites, feed.excludeFavorites);
      expect(restored.subfeeds.length, 1);
      expect(restored.subfeeds.first.id, 's1');
    });

    test('omits rating when null', () {
      const feed = Feed(
        id: 'noRating',
        name: 'No Rating',
        mediaType: Feed.mediaTypeImage,
      );
      final json = feed.toJson();
      expect(json.containsKey('rating'), isFalse);
    });
  });

  group('Feed.copyWith', () {
    test('changes each field', () {
      const feed = Feed(
        id: 'orig',
        name: 'Original',
        mediaType: Feed.mediaTypeImage,
        includeTags: ['a'],
        orTags: ['b'],
        excludeTags: ['c'],
        rating: 's',
        subfeeds: [SubFeed(id: 's', name: 'S')],
      );
      final updated = feed.copyWith(
        id: 'new',
        name: 'New',
        mediaType: Feed.mediaTypeVideo,
        includeTags: ['x'],
        orTags: ['y'],
        excludeTags: ['z'],
        rating: 'q',
        order: 'score_asc',
        excludeFavorites: true,
        subfeeds: const [SubFeed(id: 's2', name: 'S2')],
      );
      expect(updated.id, 'new');
      expect(updated.name, 'New');
      expect(updated.mediaType, Feed.mediaTypeVideo);
      expect(updated.includeTags, ['x']);
      expect(updated.orTags, ['y']);
      expect(updated.excludeTags, ['z']);
      expect(updated.rating, 'q');
      expect(updated.order, 'score_asc');
      expect(updated.excludeFavorites, isTrue);
      expect(updated.subfeeds.first.id, 's2');
    });

    test('preserves fields when no args given', () {
      const feed = Feed(
        id: 'orig',
        name: 'Original',
        mediaType: Feed.mediaTypeImage,
      );
      final updated = feed.copyWith();
      expect(updated.id, 'orig');
      expect(updated.name, 'Original');
      expect(updated.mediaType, Feed.mediaTypeImage);
    });
  });

  group('Feed.toSearchQuery', () {
    test('empty tags + image media', () {
      const feed = Feed(
        id: 'f',
        name: 'n',
        mediaType: Feed.mediaTypeImage,
      );
      expect(feed.toSearchQuery(), '( ~type:jpg ~type:png ~type:gif ~type:webp )');
    });

    test('include tags only', () {
      const feed = Feed(
        id: 'f',
        name: 'n',
        mediaType: Feed.mediaTypeImage,
        includeTags: ['tag1', 'tag2'],
      );
      expect(
        feed.toSearchQuery(),
        'tag1 tag2 ( ~type:jpg ~type:png ~type:gif ~type:webp )',
      );
    });

    test('or tags produce or clause', () {
      const feed = Feed(
        id: 'f',
        name: 'n',
        mediaType: Feed.mediaTypeImage,
        orTags: ['tag1', 'tag2'],
      );
      final query = feed.toSearchQuery();
      expect(query, contains('( ~tag1 ~tag2 )'));
    });

    test('exclude tags produce negation', () {
      const feed = Feed(
        id: 'f',
        name: 'n',
        mediaType: Feed.mediaTypeImage,
        excludeTags: ['tag1'],
      );
      final query = feed.toSearchQuery();
      expect(query, contains('-tag1'));
    });

    test('video media', () {
      const feed = Feed(
        id: 'f',
        name: 'n',
        mediaType: Feed.mediaTypeVideo,
      );
      expect(feed.toSearchQuery(), '( ~type:mp4 ~type:webm )');
    });

    test('all media', () {
      const feed = Feed(
        id: 'f',
        name: 'n',
        mediaType: Feed.mediaTypeAll,
      );
      expect(
        feed.toSearchQuery(),
        '( ~type:jpg ~type:png ~type:gif ~type:webp ~type:mp4 ~type:webm )',
      );
    });

    test('combined include + or + exclude + media type', () {
      const feed = Feed(
        id: 'f',
        name: 'n',
        mediaType: Feed.mediaTypeVideo,
        includeTags: ['inc1', 'inc2'],
        orTags: ['or1', 'or2'],
        excludeTags: ['exc1'],
      );
      final query = feed.toSearchQuery();
      expect(query, 'inc1 inc2 ( ~or1 ~or2 ) -exc1 ( ~type:mp4 ~type:webm )');
    });
  });

  group('Feed.toSearchQueryWithPath', () {
    test('empty path equals base query', () {
      const feed = Feed(
        id: 'f',
        name: 'n',
        mediaType: Feed.mediaTypeImage,
        includeTags: ['base'],
      );
      expect(feed.toSearchQueryWithPath([]), feed.toSearchQuery());
    });

    test('path [0] includes first subfeed tags', () {
      const feed = Feed(
        id: 'f',
        name: 'n',
        mediaType: Feed.mediaTypeImage,
        includeTags: ['base'],
        subfeeds: [
          SubFeed(id: 's1', name: 'S1', includeTags: ['sub_inc'], excludeTags: ['sub_exc']),
        ],
      );
      final query = feed.toSearchQueryWithPath([0]);
      expect(query, contains('sub_inc'));
      expect(query, contains('-sub_exc'));
    });

    test('path [0, 0] reaches nested subfeed', () {
      const feed = Feed(
        id: 'f',
        name: 'n',
        mediaType: Feed.mediaTypeImage,
        subfeeds: [
          SubFeed(
            id: 's1',
            name: 'S1',
            subfeeds: [
              SubFeed(id: 'ss1', name: 'SS1', includeTags: ['deep']),
            ],
          ),
        ],
      );
      final query = feed.toSearchQueryWithPath([0, 0]);
      expect(query, contains('deep'));
    });

    test('invalid index [99] returns base query', () {
      const feed = Feed(
        id: 'f',
        name: 'n',
        mediaType: Feed.mediaTypeImage,
        includeTags: ['base'],
        subfeeds: [SubFeed(id: 's1', name: 'S1', includeTags: ['sub'])],
      );
      expect(feed.toSearchQueryWithPath([99]), feed.toSearchQuery());
    });

    test('subfeed exclude cancels feed include', () {
      const feed = Feed(
        id: 'f',
        name: 'n',
        mediaType: Feed.mediaTypeAll,
        includeTags: ['video'],
        subfeeds: [
          SubFeed(id: 's1', name: 'S1', excludeTags: ['video']),
        ],
      );
      final query = feed.toSearchQueryWithPath([0]);
      expect(query, isNot(contains(' video ')));
      expect(query, isNot(contains(' -video')));
      expect(query, isNot(contains('video ')));
    });

    test('subfeed include cancels feed exclude', () {
      const feed = Feed(
        id: 'f',
        name: 'n',
        mediaType: Feed.mediaTypeImage,
        excludeTags: ['gore'],
        subfeeds: [
          SubFeed(id: 's1', name: 'S1', includeTags: ['gore']),
        ],
      );
      final query = feed.toSearchQueryWithPath([0]);
      expect(query, isNot(contains('-gore')));
      expect(query, isNot(contains(' gore ')));
    });

    test('nested subfeed exclude cancels parent subfeed include', () {
      const feed = Feed(
        id: 'f',
        name: 'n',
        mediaType: Feed.mediaTypeAll,
        subfeeds: [
          SubFeed(
            id: 's1',
            name: 'S1',
            includeTags: ['video'],
            subfeeds: [
              SubFeed(id: 'ss1', name: 'SS1', excludeTags: ['video']),
            ],
          ),
        ],
      );
      final query = feed.toSearchQueryWithPath([0, 0]);
      expect(query, isNot(contains('video')));
      expect(query, isNot(contains('-video')));
    });

    test('non-conflicting tags are preserved', () {
      const feed = Feed(
        id: 'f',
        name: 'n',
        mediaType: Feed.mediaTypeImage,
        includeTags: ['cat'],
        excludeTags: ['dog'],
        subfeeds: [
          SubFeed(id: 's1', name: 'S1', includeTags: ['video'], excludeTags: ['gore']),
        ],
      );
      final query = feed.toSearchQueryWithPath([0]);
      expect(query, contains('cat'));
      expect(query, contains('-dog'));
      expect(query, contains('video'));
      expect(query, contains('-gore'));
    });
  });

  group('Feed.toSearchQueryWithSubfeed', () {
    test('null subfeed equals base query', () {
      const feed = Feed(
        id: 'f',
        name: 'n',
        mediaType: Feed.mediaTypeImage,
        includeTags: ['base'],
      );
      expect(feed.toSearchQueryWithSubfeed(null), feed.toSearchQuery());
    });

    test('non-null subfeed includes subfeed tags', () {
      const feed = Feed(
        id: 'f',
        name: 'n',
        mediaType: Feed.mediaTypeImage,
        includeTags: ['base'],
      );
      const sub = SubFeed(
        id: 's',
        name: 'S',
        includeTags: ['extra'],
        excludeTags: ['bad'],
      );
      final query = feed.toSearchQueryWithSubfeed(sub);
      expect(query, contains('extra'));
      expect(query, contains('-bad'));
    });
  });

  group('SubFeed', () {
    test('fromJson with complete json', () {
      final json = {
        'id': 'sub1',
        'name': 'Sub One',
        'includeTags': ['inc1', 'inc2'],
        'excludeTags': ['exc1'],
        'subfeeds': [
          {'id': 'nested', 'name': 'Nested', 'includeTags': ['n1']},
        ],
      };
      final sub = SubFeed.fromJson(json);
      expect(sub.id, 'sub1');
      expect(sub.name, 'Sub One');
      expect(sub.includeTags, ['inc1', 'inc2']);
      expect(sub.excludeTags, ['exc1']);
      expect(sub.subfeeds.length, 1);
      expect(sub.subfeeds.first.id, 'nested');
    });

    test('fromJson with missing fields defaults', () {
      final sub = SubFeed.fromJson({});
      expect(sub.id, '');
      expect(sub.name, '');
      expect(sub.includeTags, isEmpty);
      expect(sub.excludeTags, isEmpty);
      expect(sub.subfeeds, isEmpty);
    });

    test('toJson roundtrip', () {
      const sub = SubFeed(
        id: 'rt',
        name: 'RT',
        includeTags: ['a'],
        excludeTags: ['b'],
        subfeeds: [SubFeed(id: 'nested', name: 'N')],
      );
      final json = sub.toJson();
      final restored = SubFeed.fromJson(json);
      expect(restored.id, 'rt');
      expect(restored.name, 'RT');
      expect(restored.includeTags, ['a']);
      expect(restored.excludeTags, ['b']);
      expect(restored.subfeeds.length, 1);
      expect(restored.subfeeds.first.id, 'nested');
    });

    test('copyWith changes fields', () {
      const sub = SubFeed(id: 'orig', name: 'Orig');
      final updated = sub.copyWith(
        id: 'new',
        name: 'New',
        includeTags: ['x'],
        excludeTags: ['y'],
        subfeeds: const [SubFeed(id: 's', name: 'S')],
      );
      expect(updated.id, 'new');
      expect(updated.name, 'New');
      expect(updated.includeTags, ['x']);
      expect(updated.excludeTags, ['y']);
      expect(updated.subfeeds.first.id, 's');
    });

    test('appendTagParts adds include and exclude tags', () {
      const sub = SubFeed(
        id: 's',
        name: 'S',
        includeTags: ['inc1', 'inc2'],
        excludeTags: ['exc1', 'exc2'],
      );
      final parts = <String>['base'];
      sub.appendTagParts(parts);
      expect(parts, ['base', 'inc1 inc2', '-exc1', '-exc2']);
    });

    test('appendTagParts skips empty exclude tags', () {
      const sub = SubFeed(
        id: 's',
        name: 'S',
        includeTags: ['inc1'],
        excludeTags: ['  ', 'exc1'],
      );
      final parts = <String>[];
      sub.appendTagParts(parts);
      expect(parts, ['inc1', '-exc1']);
    });

    test('appendTagParts with no tags adds nothing', () {
      const sub = SubFeed(id: 's', name: 'S');
      final parts = <String>['existing'];
      sub.appendTagParts(parts);
      expect(parts, ['existing']);
    });
  });
}
