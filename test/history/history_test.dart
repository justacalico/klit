import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/history/data/history.dart';

void main() {
  group('HistoryCategory', () {
    test('has items and searches values', () {
      expect(HistoryCategory.values, contains(HistoryCategory.items));
      expect(HistoryCategory.values, contains(HistoryCategory.searches));
      expect(HistoryCategory.values.length, 2);
    });

    test('name property matches enum name', () {
      expect(HistoryCategory.items.name, 'items');
      expect(HistoryCategory.searches.name, 'searches');
    });
  });

  group('HistoryType', () {
    test('has all expected values', () {
      expect(HistoryType.values, contains(HistoryType.posts));
      expect(HistoryType.values, contains(HistoryType.pools));
      expect(HistoryType.values, contains(HistoryType.topics));
      expect(HistoryType.values, contains(HistoryType.users));
      expect(HistoryType.values, contains(HistoryType.wikis));
      expect(HistoryType.values.length, 5);
    });

    test('name property matches enum name', () {
      expect(HistoryType.posts.name, 'posts');
      expect(HistoryType.pools.name, 'pools');
      expect(HistoryType.topics.name, 'topics');
      expect(HistoryType.users.name, 'users');
      expect(HistoryType.wikis.name, 'wikis');
    });
  });

  group('History', () {
    final visitedAt = DateTime(2024, 6, 15, 10, 30);

    final history = History(
      id: 1,
      visitedAt: visitedAt,
      link: '/posts/123',
      category: HistoryCategory.items,
      type: HistoryType.posts,
      title: 'Test Post',
      subtitle: 'Some subtitle',
      thumbnails: ['thumb1.jpg', 'thumb2.jpg'],
    );

    test('fromJson creates correct History', () {
      final json = {
        'id': 42,
        'visitedAt': '2024-01-20T12:00:00.000',
        'link': '/pools/5',
        'category': 'searches',
        'type': 'pools',
        'title': 'Pool Title',
        'subtitle': null,
        'thumbnails': <String>[],
      };

      final fromJson = History.fromJson(json);
      expect(fromJson.id, 42);
      expect(fromJson.visitedAt, DateTime(2024, 1, 20, 12));
      expect(fromJson.link, '/pools/5');
      expect(fromJson.category, HistoryCategory.searches);
      expect(fromJson.type, HistoryType.pools);
      expect(fromJson.title, 'Pool Title');
      expect(fromJson.subtitle, isNull);
      expect(fromJson.thumbnails, isEmpty);
    });

    test('toJson produces correct map', () {
      final json = history.toJson();
      expect(json['id'], 1);
      expect(json['visitedAt'], visitedAt.toIso8601String());
      expect(json['link'], '/posts/123');
      expect(json['category'], 'items');
      expect(json['type'], 'posts');
      expect(json['title'], 'Test Post');
      expect(json['subtitle'], 'Some subtitle');
      expect(json['thumbnails'], ['thumb1.jpg', 'thumb2.jpg']);
    });

    test('fromJson/toJson roundtrip preserves data', () {
      final json = history.toJson();
      final restored = History.fromJson(json);

      expect(restored.id, history.id);
      expect(restored.visitedAt, history.visitedAt);
      expect(restored.link, history.link);
      expect(restored.category, history.category);
      expect(restored.type, history.type);
      expect(restored.title, history.title);
      expect(restored.subtitle, history.subtitle);
      expect(restored.thumbnails, history.thumbnails);
    });

    test('equality works correctly', () {
      final copy = History(
        id: 1,
        visitedAt: visitedAt,
        link: '/posts/123',
        category: HistoryCategory.items,
        type: HistoryType.posts,
        title: 'Test Post',
        subtitle: 'Some subtitle',
        thumbnails: ['thumb1.jpg', 'thumb2.jpg'],
      );
      expect(history, copy);
    });

    test('different histories are not equal', () {
      final other = History(
        id: 2,
        visitedAt: visitedAt,
        link: '/posts/123',
        category: HistoryCategory.items,
        type: HistoryType.posts,
        title: 'Test Post',
        subtitle: 'Some subtitle',
        thumbnails: ['thumb1.jpg', 'thumb2.jpg'],
      );
      expect(history == other, isFalse);
    });

    test('handles null title and subtitle', () {
      final h = History(
        id: 10,
        visitedAt: visitedAt,
        link: '/posts/1',
        category: HistoryCategory.items,
        type: HistoryType.posts,
        title: null,
        subtitle: null,
        thumbnails: [],
      );
      final json = h.toJson();
      expect(json['title'], isNull);
      expect(json['subtitle'], isNull);

      final restored = History.fromJson(json);
      expect(restored.title, isNull);
      expect(restored.subtitle, isNull);
    });
  });

  group('HistoryRequest', () {
    final visitedAt = DateTime(2024, 3, 1, 8);

    test('creates with required fields', () {
      final request = HistoryRequest(
        visitedAt: visitedAt,
        link: '/posts/100',
        category: HistoryCategory.items,
        type: HistoryType.posts,
      );
      expect(request.visitedAt, visitedAt);
      expect(request.link, '/posts/100');
      expect(request.category, HistoryCategory.items);
      expect(request.type, HistoryType.posts);
      expect(request.title, isNull);
      expect(request.subtitle, isNull);
      expect(request.thumbnails, isEmpty);
    });

    test('creates with optional fields', () {
      final request = HistoryRequest(
        visitedAt: visitedAt,
        link: '/posts/100',
        category: HistoryCategory.searches,
        type: HistoryType.users,
        title: 'Title',
        subtitle: 'Sub',
        thumbnails: ['t.jpg'],
      );
      expect(request.title, 'Title');
      expect(request.subtitle, 'Sub');
      expect(request.thumbnails, ['t.jpg']);
    });

    test('fromJson/toJson roundtrip', () {
      final request = HistoryRequest(
        visitedAt: visitedAt,
        link: '/posts/100',
        category: HistoryCategory.items,
        type: HistoryType.posts,
        title: 'Title',
        thumbnails: ['a.jpg', 'b.jpg'],
      );
      final json = request.toJson();
      final restored = HistoryRequest.fromJson(json);

      expect(restored.visitedAt, request.visitedAt);
      expect(restored.link, request.link);
      expect(restored.category, request.category);
      expect(restored.type, request.type);
      expect(restored.title, request.title);
      expect(restored.subtitle, request.subtitle);
      expect(restored.thumbnails, request.thumbnails);
    });

    test('fromJson handles missing thumbnails with default', () {
      final json = {
        'visitedAt': '2024-01-01T00:00:00.000',
        'link': '/posts/1',
        'category': 'items',
        'type': 'posts',
      };
      final restored = HistoryRequest.fromJson(json);
      expect(restored.thumbnails, isEmpty);
    });
  });
}
