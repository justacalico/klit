import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/user/data/user.dart';

void main() {
  final createdAt = DateTime.parse('2024-01-15T10:30:00.000Z');

  group('UserAbout JSON', () {
    test('roundtrip preserves data with values', () {
      const about = UserAbout(bio: 'hello', comission: 'open');
      final restored = UserAbout.fromJson(about.toJson());
      expect(restored.bio, 'hello');
      expect(restored.comission, 'open');
    });

    test('roundtrip preserves null fields', () {
      const about = UserAbout(bio: null, comission: null);
      final restored = UserAbout.fromJson(about.toJson());
      expect(restored.bio, isNull);
      expect(restored.comission, isNull);
    });
  });

  group('UserStats JSON', () {
    test('roundtrip preserves data with values', () {
      final stats = UserStats(
        createdAt: createdAt,
        levelString: 'Member',
        favoriteCount: 10,
        postUpdateCount: 20,
        postUploadCount: 5,
        forumPostCount: 3,
        commentCount: 50,
      );
      final restored = UserStats.fromJson(stats.toJson());
      expect(restored.createdAt, createdAt);
      expect(restored.levelString, 'Member');
      expect(restored.favoriteCount, 10);
      expect(restored.postUpdateCount, 20);
      expect(restored.postUploadCount, 5);
      expect(restored.forumPostCount, 3);
      expect(restored.commentCount, 50);
    });

    test('roundtrip preserves null fields', () {
      const stats = UserStats(
        createdAt: null,
        levelString: null,
        favoriteCount: null,
        postUpdateCount: null,
        postUploadCount: null,
        forumPostCount: null,
        commentCount: null,
      );
      final restored = UserStats.fromJson(stats.toJson());
      expect(restored.createdAt, isNull);
      expect(restored.levelString, isNull);
      expect(restored.favoriteCount, isNull);
    });
  });

  group('User JSON', () {
    final user = User(
      id: 1,
      name: 'testuser',
      avatarId: 42,
      about: const UserAbout(bio: 'bio text', comission: null),
      stats: UserStats(
        createdAt: createdAt,
        levelString: 'Admin',
        favoriteCount: 100,
        postUpdateCount: null,
        postUploadCount: null,
        forumPostCount: null,
        commentCount: null,
      ),
    );

    test('toJson serializes scalar fields', () {
      final json = user.toJson();
      expect(json['id'], 1);
      expect(json['name'], 'testuser');
      expect(json['avatarId'], 42);
    });

    test('fromJson parses all fields with nested maps', () {
      final json = {
        'id': 1,
        'name': 'testuser',
        'avatarId': 42,
        'about': {'bio': 'bio text', 'comission': null},
        'stats': {
          'createdAt': createdAt.toIso8601String(),
          'levelString': 'Admin',
          'favoriteCount': 100,
          'postUpdateCount': null,
          'postUploadCount': null,
          'forumPostCount': null,
          'commentCount': null,
        },
      };
      final parsed = User.fromJson(json);
      expect(parsed.id, 1);
      expect(parsed.name, 'testuser');
      expect(parsed.avatarId, 42);
      expect(parsed.about?.bio, 'bio text');
      expect(parsed.about?.comission, isNull);
      expect(parsed.stats?.createdAt, createdAt);
      expect(parsed.stats?.levelString, 'Admin');
      expect(parsed.stats?.favoriteCount, 100);
    });

    test('roundtrip preserves data with null about and stats', () {
      final userNull = User(
        id: 2,
        name: 'minimal',
        avatarId: null,
        about: null,
        stats: null,
      );
      final restored = User.fromJson(userNull.toJson());
      expect(restored.id, userNull.id);
      expect(restored.name, userNull.name);
      expect(restored.avatarId, isNull);
      expect(restored.about, isNull);
      expect(restored.stats, isNull);
    });

    test('fromJson handles null about and stats', () {
      final json = {
        'id': 3,
        'name': 'anon',
        'avatarId': null,
        'about': null,
        'stats': null,
      };
      final parsed = User.fromJson(json);
      expect(parsed.avatarId, isNull);
      expect(parsed.about, isNull);
      expect(parsed.stats, isNull);
    });
  });

  group('User.copyWith', () {
    test('changes name and avatarId', () {
      final user = User(
        id: 1,
        name: 'original',
        avatarId: null,
        about: null,
        stats: null,
      );
      final copied = user.copyWith(name: 'newname', avatarId: 99);
      expect(copied.name, 'newname');
      expect(copied.avatarId, 99);
      expect(copied.id, user.id);
    });

    test('changes about and stats', () {
      final user = User(
        id: 1,
        name: 'original',
        avatarId: null,
        about: null,
        stats: null,
      );
      final copied = user.copyWith(
        about: const UserAbout(bio: 'new bio', comission: null),
        stats: UserStats(
          createdAt: createdAt,
          levelString: null,
          favoriteCount: null,
          postUpdateCount: null,
          postUploadCount: null,
          forumPostCount: null,
          commentCount: null,
        ),
      );
      expect(copied.about?.bio, 'new bio');
      expect(copied.stats?.createdAt, createdAt);
    });
  });
}
