import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/follow/follow.dart';

void main() {
  group('Follow.fromJson', () {
    test('complete json', () {
      final json = {
        'id': 42,
        'tags': 'fox canine',
        'title': 'My Follow',
        'alias': 'my_alias',
        'type': 'notify',
        'latest': 100,
        'unseen': 5,
        'thumbnail': 'https://example.com/thumb.jpg',
        'updated': '2024-01-15T10:30:00.000',
      };
      final follow = Follow.fromJson(json);
      expect(follow.id, 42);
      expect(follow.tags, 'fox canine');
      expect(follow.title, 'My Follow');
      expect(follow.alias, 'my_alias');
      expect(follow.type, FollowType.notify);
      expect(follow.latest, 100);
      expect(follow.unseen, 5);
      expect(follow.thumbnail, 'https://example.com/thumb.jpg');
      expect(follow.updated, DateTime(2024, 1, 15, 10, 30));
    });

    test('missing optional fields', () {
      final json = {
        'id': 10,
        'tags': 'simple_tag',
        'type': 'update',
      };
      final follow = Follow.fromJson(json);
      expect(follow.id, 10);
      expect(follow.tags, 'simple_tag');
      expect(follow.title, isNull);
      expect(follow.alias, isNull);
      expect(follow.type, FollowType.update);
      expect(follow.latest, isNull);
      expect(follow.unseen, isNull);
      expect(follow.thumbnail, isNull);
      expect(follow.updated, isNull);
    });
  });

  group('Follow.toJson', () {
    test('roundtrip', () {
      final follow = Follow(
        id: 99,
        tags: 'wolf',
        title: 'Wolf Posts',
        alias: 'wolves',
        type: FollowType.bookmark,
        latest: 200,
        unseen: 3,
        thumbnail: 'thumb.jpg',
        updated: DateTime(2024, 6, 1, 12),
      );
      final json = follow.toJson();
      final restored = Follow.fromJson(json);
      expect(restored.id, 99);
      expect(restored.tags, 'wolf');
      expect(restored.title, 'Wolf Posts');
      expect(restored.alias, 'wolves');
      expect(restored.type, FollowType.bookmark);
      expect(restored.latest, 200);
      expect(restored.unseen, 3);
      expect(restored.thumbnail, 'thumb.jpg');
      expect(restored.updated, DateTime(2024, 6, 1, 12));
    });

    test('null fields serialize correctly', () {
      const follow = Follow(
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
      final json = follow.toJson();
      expect(json['title'], isNull);
      expect(json['alias'], isNull);
      expect(json['latest'], isNull);
      expect(json['unseen'], isNull);
      expect(json['thumbnail'], isNull);
      expect(json['updated'], isNull);
    });
  });

  group('Follow.copyWith', () {
    test('changes individual fields', () {
      final follow = Follow(
        id: 1,
        tags: 'tag',
        title: 'Old',
        alias: 'old_alias',
        type: FollowType.update,
        latest: 10,
        unseen: 5,
        thumbnail: 'old.jpg',
        updated: DateTime(2024),
      );
      final updated = follow.copyWith(
        title: 'New',
        unseen: 0,
        type: FollowType.notify,
      );
      expect(updated.title, 'New');
      expect(updated.unseen, 0);
      expect(updated.type, FollowType.notify);
      expect(updated.id, 1);
      expect(updated.tags, 'tag');
      expect(updated.alias, 'old_alias');
      expect(updated.latest, 10);
      expect(updated.thumbnail, 'old.jpg');
      expect(updated.updated, DateTime(2024));
    });
  });

  group('FollowRequest', () {
    test('fromJson with complete json', () {
      final json = {
        'tags': 'fox',
        'title': 'Fox',
        'alias': 'foxes',
        'type': 'notify',
      };
      final req = FollowRequest.fromJson(json);
      expect(req.tags, 'fox');
      expect(req.title, 'Fox');
      expect(req.alias, 'foxes');
      expect(req.type, FollowType.notify);
    });

    test('fromJson defaults type to update', () {
      final json = {'tags': 'fox'};
      final req = FollowRequest.fromJson(json);
      expect(req.tags, 'fox');
      expect(req.title, isNull);
      expect(req.alias, isNull);
      expect(req.type, FollowType.update);
    });

    test('toJson roundtrip', () {
      const req = FollowRequest(
        tags: 'wolf',
        title: 'Wolf',
        alias: 'wolves',
        type: FollowType.bookmark,
      );
      final json = req.toJson();
      final restored = FollowRequest.fromJson(json);
      expect(restored.tags, 'wolf');
      expect(restored.title, 'Wolf');
      expect(restored.alias, 'wolves');
      expect(restored.type, FollowType.bookmark);
    });
  });

  group('FollowUpdate', () {
    test('fromJson with complete json', () {
      final json = {
        'id': 5,
        'tags': 'new_tag',
        'title': 'New Title',
        'type': 'bookmark',
      };
      final update = FollowUpdate.fromJson(json);
      expect(update.id, 5);
      expect(update.tags, 'new_tag');
      expect(update.title, 'New Title');
      expect(update.type, FollowType.bookmark);
    });

    test('fromJson with minimal json', () {
      final json = {'id': 5};
      final update = FollowUpdate.fromJson(json);
      expect(update.id, 5);
      expect(update.tags, isNull);
      expect(update.title, isNull);
      expect(update.type, isNull);
    });

    test('toJson roundtrip', () {
      const update = FollowUpdate(
        id: 10,
        tags: 'tag',
        title: 'Title',
        type: FollowType.notify,
      );
      final json = update.toJson();
      final restored = FollowUpdate.fromJson(json);
      expect(restored.id, 10);
      expect(restored.tags, 'tag');
      expect(restored.title, 'Title');
      expect(restored.type, FollowType.notify);
    });

    test('toJson with null optional fields', () {
      const update = FollowUpdate(id: 1);
      final json = update.toJson();
      expect(json['id'], 1);
      expect(json['tags'], isNull);
      expect(json['title'], isNull);
      expect(json['type'], isNull);
    });
  });

  group('FollowType', () {
    test('has update, notify, bookmark values', () {
      expect(FollowType.values.length, 3);
      expect(FollowType.values, contains(FollowType.update));
      expect(FollowType.values, contains(FollowType.notify));
      expect(FollowType.values, contains(FollowType.bookmark));
    });
  });
}
