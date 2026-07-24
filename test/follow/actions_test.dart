import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/follow/follow.dart';
import 'package:kilt/pool/pool.dart';
import 'package:kilt/post/post.dart';
import 'package:kilt/shared/shared.dart';

void main() {
  group('Updating.name', () {
    test('returns title when set', () {
      final follow = Follow(
        id: 1,
        tags: 'some_tag',
        title: 'My Title',
        alias: null,
        type: FollowType.update,
        latest: null,
        unseen: null,
        thumbnail: null,
        updated: null,
      );
      expect(follow.name, 'My Title');
    });

    test('returns tagToName(tags) when title is null', () {
      final follow = Follow(
        id: 1,
        tags: 'fox canine',
        title: null,
        alias: null,
        type: FollowType.update,
        latest: null,
        unseen: null,
        thumbnail: null,
        updated: null,
      );
      expect(follow.name, 'fox, canine');
    });

    test('tagToName replaces underscores with spaces', () {
      final follow = Follow(
        id: 1,
        tags: 'red_fox',
        title: null,
        alias: null,
        type: FollowType.update,
        latest: null,
        unseen: null,
        thumbnail: null,
        updated: null,
      );
      expect(follow.name, 'red fox');
    });
  });

  group('Updating.isSingle', () {
    Follow makeFollow(String tags) => Follow(
          id: 1,
          tags: tags,
          title: null,
          alias: null,
          type: FollowType.update,
          latest: null,
          unseen: null,
          thumbnail: null,
          updated: null,
        );

    test('true for a single simple tag', () {
      expect(makeFollow('simple_tag').isSingle, isTrue);
    });

    test('false for tags with spaces', () {
      expect(makeFollow('tag with spaces').isSingle, isFalse);
    });

    test('false for namespaced tag', () {
      expect(makeFollow('namespaced:tag').isSingle, isFalse);
    });
  });

  group('Updating.withTitle', () {
    test('updates title when different', () {
      final follow = Follow(
        id: 1,
        tags: 'tag',
        title: 'Old',
        alias: null,
        type: FollowType.update,
        latest: null,
        unseen: null,
        thumbnail: null,
        updated: null,
      );
      final updated = follow.withTitle('New');
      expect(updated.title, 'New');
    });

    test('no change when title is the same', () {
      final follow = Follow(
        id: 1,
        tags: 'tag',
        title: 'Same',
        alias: null,
        type: FollowType.update,
        latest: null,
        unseen: null,
        thumbnail: null,
        updated: null,
      );
      final updated = follow.withTitle('Same');
      expect(updated.title, 'Same');
      expect(identical(updated, follow), isTrue);
    });
  });

  group('Updating.withAlias', () {
    test('updates alias when different', () {
      final follow = Follow(
        id: 1,
        tags: 'tag',
        title: null,
        alias: 'old_alias',
        type: FollowType.update,
        latest: null,
        unseen: null,
        thumbnail: null,
        updated: null,
      );
      final updated = follow.withAlias('new_alias');
      expect(updated.alias, 'new_alias');
    });

    test('no change when alias is the same', () {
      final follow = Follow(
        id: 1,
        tags: 'tag',
        title: null,
        alias: 'same',
        type: FollowType.update,
        latest: null,
        unseen: null,
        thumbnail: null,
        updated: null,
      );
      final updated = follow.withAlias('same');
      expect(updated.alias, 'same');
      expect(identical(updated, follow), isTrue);
    });
  });

  group('Updating.withPool', () {
    Pool makePool({required String name, required bool active}) => Pool(
          id: 1,
          name: name,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
          description: '',
          postIds: const [],
          postCount: 0,
          active: active,
        );

    test('sets title from pool name', () {
      final follow = Follow(
        id: 1,
        tags: 'tag',
        title: null,
        alias: null,
        type: FollowType.update,
        latest: null,
        unseen: null,
        thumbnail: null,
        updated: null,
      );
      final pool = makePool(name: 'best_pool', active: true);
      final updated = follow.withPool(pool);
      expect(updated.title, 'best pool');
    });

    test('sets bookmark type when pool is inactive', () {
      final follow = Follow(
        id: 1,
        tags: 'tag',
        title: null,
        alias: null,
        type: FollowType.update,
        latest: null,
        unseen: null,
        thumbnail: null,
        updated: null,
      );
      final pool = makePool(name: 'inactive_pool', active: false);
      final updated = follow.withPool(pool);
      expect(updated.type, FollowType.bookmark);
    });

    test('does not change type when pool is active', () {
      final follow = Follow(
        id: 1,
        tags: 'tag',
        title: null,
        alias: null,
        type: FollowType.notify,
        latest: null,
        unseen: null,
        thumbnail: null,
        updated: null,
      );
      final pool = makePool(name: 'active_pool', active: true);
      final updated = follow.withPool(pool);
      expect(updated.type, FollowType.notify);
    });
  });

  group('Updating.withSeen', () {
    test('sets unseen to 0 when positive', () {
      final follow = Follow(
        id: 1,
        tags: 'tag',
        title: null,
        alias: null,
        type: FollowType.update,
        latest: null,
        unseen: 5,
        thumbnail: null,
        updated: null,
      );
      final updated = follow.withSeen();
      expect(updated.unseen, 0);
    });

    test('no change when unseen is already 0', () {
      final follow = Follow(
        id: 1,
        tags: 'tag',
        title: null,
        alias: null,
        type: FollowType.update,
        latest: null,
        unseen: 0,
        thumbnail: null,
        updated: null,
      );
      final updated = follow.withSeen();
      expect(updated.unseen, 0);
      expect(identical(updated, follow), isTrue);
    });

    test('no change when unseen is null', () {
      final follow = Follow(
        id: 1,
        tags: 'tag',
        title: null,
        alias: null,
        type: FollowType.update,
        latest: null,
        unseen: null,
        thumbnail: null,
        updated: null,
      );
      final updated = follow.withSeen();
      expect(updated.unseen, isNull);
      expect(identical(updated, follow), isTrue);
    });
  });

  group('Updating.withLatest', () {
    Follow makeFollow({int? latest, int? unseen, String? thumbnail}) => Follow(
          id: 1,
          tags: 'tag',
          title: null,
          alias: null,
          type: FollowType.update,
          latest: latest,
          unseen: unseen,
          thumbnail: thumbnail,
          updated: null,
        );

    test('updates latest and thumbnail when post is newer', () {
      final follow = makeFollow(latest: 5, unseen: 3, thumbnail: 'old.jpg');
      final post = Post(
        id: 10,
        file: null,
        sample: 'sample.jpg',
        preview: 'preview.jpg',
        width: 100,
        height: 100,
        ext: 'jpg',
        size: 1000,
        variants: null,
        tags: const {},
        uploaderId: 1,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: null,
        vote: const VoteInfo(score: 0),
        isDeleted: false,
        rating: Rating.s,
        favCount: 0,
        isFavorited: false,
        commentCount: 0,
        description: '',
        sources: const [],
        pools: null,
        relationships: const Relationships(
          parentId: null,
          hasActiveChildren: false,
          children: [],
        ),
      );
      final updated = follow.withLatest(post);
      expect(updated.latest, 10);
      expect(updated.thumbnail, 'sample.jpg');
    });

    test('uses preview when sample is null', () {
      final follow = makeFollow(latest: 5, unseen: 0, thumbnail: null);
      final post = Post(
        id: 10,
        file: null,
        sample: null,
        preview: 'preview.jpg',
        width: 100,
        height: 100,
        ext: 'jpg',
        size: 1000,
        variants: null,
        tags: const {},
        uploaderId: 1,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: null,
        vote: const VoteInfo(score: 0),
        isDeleted: false,
        rating: Rating.s,
        favCount: 0,
        isFavorited: false,
        commentCount: 0,
        description: '',
        sources: const [],
        pools: null,
        relationships: const Relationships(
          parentId: null,
          hasActiveChildren: false,
          children: [],
        ),
      );
      final updated = follow.withLatest(post);
      expect(updated.thumbnail, 'preview.jpg');
    });

    test('no change to latest when post is null', () {
      final follow = makeFollow(latest: 5, unseen: 0, thumbnail: 'thumb.jpg');
      final updated = follow.withLatest(null);
      expect(updated.latest, 5);
      expect(updated.thumbnail, 'thumb.jpg');
    });

    test('foreground resets unseen to 0', () {
      final follow = makeFollow(latest: 5, unseen: 7, thumbnail: 'old.jpg');
      final post = Post(
        id: 10,
        file: null,
        sample: 'sample.jpg',
        preview: 'preview.jpg',
        width: 100,
        height: 100,
        ext: 'jpg',
        size: 1000,
        variants: null,
        tags: const {},
        uploaderId: 1,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: null,
        vote: const VoteInfo(score: 0),
        isDeleted: false,
        rating: Rating.s,
        favCount: 0,
        isFavorited: false,
        commentCount: 0,
        description: '',
        sources: const [],
        pools: null,
        relationships: const Relationships(
          parentId: null,
          hasActiveChildren: false,
          children: [],
        ),
      );
      final updated = follow.withLatest(post, foreground: true);
      expect(updated.unseen, 0);
    });

    test('does not update latest when post id is older', () {
      final follow = makeFollow(latest: 10, unseen: 0, thumbnail: 'old.jpg');
      final post = Post(
        id: 5,
        file: null,
        sample: 'new_thumb.jpg',
        preview: 'preview.jpg',
        width: 100,
        height: 100,
        ext: 'jpg',
        size: 1000,
        variants: null,
        tags: const {},
        uploaderId: 1,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: null,
        vote: const VoteInfo(score: 0),
        isDeleted: false,
        rating: Rating.s,
        favCount: 0,
        isFavorited: false,
        commentCount: 0,
        description: '',
        sources: const [],
        pools: null,
        relationships: const Relationships(
          parentId: null,
          hasActiveChildren: false,
          children: [],
        ),
      );
      final updated = follow.withLatest(post);
      expect(updated.latest, 10);
      expect(updated.thumbnail, 'new_thumb.jpg');
    });
  });

  group('Updating.withUnseen', () {
    Post makePost(int id, {String? sample}) => Post(
          id: id,
          file: null,
          sample: sample,
          preview: 'prev_$id.jpg',
          width: 100,
          height: 100,
          ext: 'jpg',
          size: 1000,
          variants: null,
          tags: const {},
          uploaderId: 1,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: null,
          vote: const VoteInfo(score: 0),
          isDeleted: false,
          rating: Rating.s,
          favCount: 0,
          isFavorited: false,
          commentCount: 0,
          description: '',
          sources: const [],
          pools: null,
          relationships: const Relationships(
            parentId: null,
            hasActiveChildren: false,
            children: [],
          ),
        );

    test('counts new posts and updates unseen', () {
      final follow = Follow(
        id: 1,
        tags: 'tag',
        title: null,
        alias: null,
        type: FollowType.update,
        latest: 5,
        unseen: 2,
        thumbnail: null,
        updated: null,
      );
      final posts = [makePost(6), makePost(7), makePost(8)];
      final updated = follow.withUnseen(posts);
      expect(updated.unseen, 5);
      expect(updated.latest, 8);
    });

    test('sets unseen to 0 when latest is null', () {
      final follow = Follow(
        id: 1,
        tags: 'tag',
        title: null,
        alias: null,
        type: FollowType.update,
        latest: null,
        unseen: null,
        thumbnail: null,
        updated: null,
      );
      final posts = [makePost(1), makePost(2)];
      final updated = follow.withUnseen(posts);
      expect(updated.unseen, 0);
      expect(updated.latest, 2);
    });

    test('no change when posts is empty', () {
      final follow = Follow(
        id: 1,
        tags: 'tag',
        title: null,
        alias: null,
        type: FollowType.update,
        latest: 5,
        unseen: 3,
        thumbnail: 'thumb.jpg',
        updated: null,
      );
      final updated = follow.withUnseen([]);
      expect(updated.unseen, 3);
      expect(updated.latest, 5);
    });

    test('only counts posts newer than latest', () {
      final follow = Follow(
        id: 1,
        tags: 'tag',
        title: null,
        alias: null,
        type: FollowType.update,
        latest: 7,
        unseen: 1,
        thumbnail: null,
        updated: null,
      );
      final posts = [makePost(5), makePost(6), makePost(8), makePost(9)];
      final updated = follow.withUnseen(posts);
      expect(updated.unseen, 3);
      expect(updated.latest, 9);
    });
  });

  group('getFollowRefreshRate', () {
    test('returns minimum duration for 0 items', () {
      expect(getFollowRefreshRate(0), const Duration(minutes: 30));
    });

    test('returns clamped duration for mid-range items', () {
      expect(getFollowRefreshRate(50), const Duration(minutes: 120));
    });

    test('returns maximum duration for 100 items', () {
      expect(getFollowRefreshRate(100), const Duration(minutes: 240));
    });

    test('returns maximum duration for 1000 items', () {
      expect(getFollowRefreshRate(1000), const Duration(minutes: 240));
    });
  });
}
