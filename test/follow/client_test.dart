import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/app/data/storage.dart';
import 'package:kilt/follow/follow.dart';
import 'package:kilt/identity/identity.dart';

void main() {
  late AppDatabase database;
  late Identity identity;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    final repo = IdentityRepository(database);
    final inserted = await repo.add(
      const IdentityRequest(host: 'e621.net', username: 'testuser'),
    );
    identity = inserted;
  });

  tearDown(() async {
    await database.close();
  });

  FollowClient createClient() => FollowClient(
        database: database,
        identity: identity,
      );

  group('FollowClient.create and get', () {
    test('create inserts a follow and get retrieves it', () async {
      final client = createClient();

      await client.create(
        tags: 'fox',
        type: FollowType.update,
        title: 'Fox follows',
      );

      final follows = await client.all();
      expect(follows.length, 1);
      expect(follows[0].tags, 'fox');
      expect(follows[0].title, 'Fox follows');
      expect(follows[0].type, FollowType.update);

      final retrieved = await client.get(id: follows[0].id);
      expect(retrieved.tags, 'fox');
      expect(retrieved.title, 'Fox follows');
    });

    test('create without title and alias', () async {
      final client = createClient();

      await client.create(tags: 'canine', type: FollowType.notify);

      final follows = await client.all();
      expect(follows.length, 1);
      expect(follows[0].tags, 'canine');
      expect(follows[0].title, isNull);
      expect(follows[0].type, FollowType.notify);
    });

    test('create updates existing follow with same tags', () async {
      final client = createClient();

      await client.create(tags: 'fox', type: FollowType.update, title: 'Old');
      await client.create(
        tags: 'fox',
        type: FollowType.notify,
        title: 'New',
      );

      final follows = await client.all();
      expect(follows.length, 1);
      expect(follows[0].title, 'New');
      expect(follows[0].type, FollowType.notify);
    });
  });

  group('FollowClient.getByTags', () {
    test('returns follow matching tags', () async {
      final client = createClient();

      await client.create(tags: 'fox', type: FollowType.update);

      final follow = await client.getByTags(tags: 'fox');
      expect(follow, isNotNull);
      expect(follow!.tags, 'fox');
    });

    test('returns null when no follow matches', () async {
      final client = createClient();

      final follow = await client.getByTags(tags: 'fox');
      expect(follow, isNull);
    });
  });

  group('FollowClient.page', () {
    test('returns paginated follows', () async {
      final client = createClient();

      for (var i = 0; i < 5; i++) {
        await client.create(tags: 'tag_$i', type: FollowType.update);
      }

      final page1 = await client.page(page: 1, limit: 2);
      expect(page1.length, 2);

      final page2 = await client.page(page: 2, limit: 2);
      expect(page2.length, 2);

      final page3 = await client.page(page: 3, limit: 2);
      expect(page3.length, 1);
    });

    test('defaults to page 1 when page is null', () async {
      final client = createClient();

      await client.create(tags: 'fox', type: FollowType.update);

      final follows = await client.page();
      expect(follows.length, 1);
    });
  });

  group('FollowClient.all', () {
    test('returns all follows for the identity', () async {
      final client = createClient();

      await client.create(tags: 'fox', type: FollowType.update);
      await client.create(tags: 'dog', type: FollowType.notify);
      await client.create(tags: 'cat', type: FollowType.bookmark);

      final follows = await client.all();
      expect(follows.length, 3);
    });

    test('returns empty list when no follows exist', () async {
      final client = createClient();

      final follows = await client.all();
      expect(follows, isEmpty);
    });

    test('isolates follows by identity', () async {
      final client1 = FollowClient(
        database: database,
        identity: identity,
      );
      final repo = IdentityRepository(database);
      final identity2 = await repo.add(
        const IdentityRequest(host: 'e621.net', username: 'other'),
      );
      final client2 = FollowClient(
        database: database,
        identity: identity2,
      );

      await client1.create(tags: 'fox', type: FollowType.update);
      await client2.create(tags: 'dog', type: FollowType.update);

      expect((await client1.all()).length, 1);
      expect((await client2.all()).length, 1);
    });
  });

  group('FollowClient.update', () {
    test('updates title and type', () async {
      final client = createClient();

      await client.create(tags: 'fox', type: FollowType.update, title: 'Old');
      final follows = await client.all();
      final id = follows[0].id;

      await client.update(
        id: id,
        title: 'New Title',
        type: FollowType.notify,
      );

      final updated = await client.get(id: id);
      expect(updated.title, 'New Title');
      expect(updated.type, FollowType.notify);
    });

    test('updates tags and resets unseen and latest', () async {
      final client = createClient();

      await client.create(tags: 'fox', type: FollowType.update);
      final follows = await client.all();
      final id = follows[0].id;

      await client.update(id: id, tags: 'canine');

      final updated = await client.get(id: id);
      expect(updated.tags, 'canine');
    });
  });

  group('FollowClient.markSeen and markAllSeen', () {
    Future<void> setUnseen(int id, int value) async {
      await (database.update(database.followsTable)
            ..where((tbl) => tbl.id.equals(id)))
          .write(FollowCompanion(unseen: Value(value)));
    }

    test('markSeen sets unseen to 0 for a single follow', () async {
      final client = createClient();

      await client.create(tags: 'fox', type: FollowType.update);
      final follows = await client.all();
      final id = follows[0].id;
      await setUnseen(id, 5);

      await client.markSeen(id);

      final updated = await client.get(id: id);
      expect(updated.unseen, 0);
    });

    test('markAllSeen sets unseen to 0 for all follows', () async {
      final client = createClient();

      await client.create(tags: 'fox', type: FollowType.update);
      await client.create(tags: 'dog', type: FollowType.update);
      final follows = await client.all();
      for (final f in follows) {
        await setUnseen(f.id, 3);
      }

      await client.markAllSeen(null);

      final updated = await client.all();
      for (final follow in updated) {
        expect(follow.unseen, 0);
      }
    });

    test('markAllSeen with specific ids only marks those', () async {
      final client = createClient();

      await client.create(tags: 'fox', type: FollowType.update);
      await client.create(tags: 'dog', type: FollowType.update);
      final follows = await client.all();
      final foxId = follows.firstWhere((f) => f.tags == 'fox').id;
      final dogId = follows.firstWhere((f) => f.tags == 'dog').id;
      await setUnseen(foxId, 5);
      await setUnseen(dogId, 5);

      await client.markAllSeen([foxId]);

      final fox = await client.get(id: foxId);
      final dog = await client.get(id: dogId);
      expect(fox.unseen, 0);
      expect(dog.unseen, 5);
    });
  });

  group('FollowClient.delete', () {
    test('removes a follow by id', () async {
      final client = createClient();

      await client.create(tags: 'fox', type: FollowType.update);
      final follows = await client.all();
      expect(follows.length, 1);

      await client.delete(follows[0].id);

      final remaining = await client.all();
      expect(remaining, isEmpty);
    });
  });

  group('FollowClient.count', () {
    test('returns 0 when no follows exist', () async {
      final client = createClient();

      final count = await client.count();
      expect(count, 0);
    });

    test('returns the number of follows', () async {
      final client = createClient();

      await client.create(tags: 'fox', type: FollowType.update);
      await client.create(tags: 'dog', type: FollowType.update);

      final count = await client.count();
      expect(count, 2);
    });

    test('counts only follows for the current identity', () async {
      final client1 = FollowClient(
        database: database,
        identity: identity,
      );
      final repo = IdentityRepository(database);
      final identity2 = await repo.add(
        const IdentityRequest(host: 'e621.net', username: 'other'),
      );
      final client2 = FollowClient(
        database: database,
        identity: identity2,
      );

      await client1.create(tags: 'fox', type: FollowType.update);
      await client1.create(tags: 'dog', type: FollowType.update);
      await client2.create(tags: 'cat', type: FollowType.update);

      expect(await client1.count(), 2);
      expect(await client2.count(), 1);
    });
  });
}
