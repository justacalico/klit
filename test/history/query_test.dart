import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/history/data/history.dart';
import 'package:kilt/history/data/query.dart';

void main() {
  group('HistoryQuery construction', () {
    test('empty query has no search keys', () {
      final query = HistoryQuery();
      expect(query.self['search[date]'], isNull);
      expect(query.self['search[link]'], isNull);
      expect(query.self['search[title]'], isNull);
      expect(query.self['search[subtitle]'], isNull);
      expect(query.self['search[category]'], isNull);
      expect(query.self['search[type]'], isNull);
    });

    test('constructor sets date', () {
      final date = DateTime(2024, 1, 15);
      final query = HistoryQuery(date: date);
      expect(query.date, DateTime(2024, 1, 15));
    });

    test('constructor sets link, title, subtitle', () {
      final query = HistoryQuery(
        link: '/posts/1',
        title: 'Test Title',
        subtitle: 'Test Subtitle',
      );
      expect(query.link, '/posts/1');
      expect(query.title, 'Test Title');
      expect(query.subtitle, 'Test Subtitle');
    });

    test('constructor sets categories', () {
      final query = HistoryQuery(
        categories: [HistoryCategory.items, HistoryCategory.searches],
      );
      expect(query.categories, {
        HistoryCategory.items,
        HistoryCategory.searches,
      });
    });

    test('constructor sets types', () {
      final query = HistoryQuery(
        types: [HistoryType.posts, HistoryType.pools],
      );
      expect(query.types, {HistoryType.posts, HistoryType.pools});
    });

    test('from creates query from existing map', () {
      final map = <String, String>{
        'search[link]': '/posts/42',
        'search[title]': 'Hello',
      };
      final query = HistoryQuery.from(map);
      expect(query.link, '/posts/42');
      expect(query.title, 'Hello');
    });

    test('maybeFrom returns null for null input', () {
      expect(HistoryQuery.maybeFrom(null), isNull);
    });

    test('maybeFrom returns query for valid map', () {
      final map = <String, String>{'search[link]': '/posts/1'};
      final query = HistoryQuery.maybeFrom(map);
      expect(query, isNotNull);
      expect(query!.link, '/posts/1');
    });
  });

  group('HistoryQuery.date', () {
    test('getter returns parsed date for valid format', () {
      final query = HistoryQuery.from({'search[date]': '2024-03-20'});
      expect(query.date, DateTime(2024, 3, 20));
    });

    test('getter returns null for invalid date string', () {
      final query = HistoryQuery.from({'search[date]': 'not-a-date'});
      expect(query.date, isNull);
    });

    test('getter returns null when key is absent', () {
      final query = HistoryQuery();
      expect(query.date, isNull);
    });

    test('setter sets formatted date', () {
      final query = HistoryQuery();
      query.date = DateTime(2024, 6);
      expect(query.self['search[date]'], '2024-06-01');
      expect(query.date, DateTime(2024, 6));
    });

    test('setter removes date when set to null', () {
      final query = HistoryQuery(date: DateTime(2024));
      expect(query.self['search[date]'], isNotNull);
      query.date = null;
      expect(query.self['search[date]'], isNull);
    });
  });

  group('HistoryQuery.categories', () {
    test('getter returns categories for valid values', () {
      final query = HistoryQuery.from({'search[category]': 'items,searches'});
      expect(query.categories, {HistoryCategory.items, HistoryCategory.searches});
    });

    test('getter ignores invalid category names', () {
      final query = HistoryQuery.from({'search[category]': 'items,invalid'});
      expect(query.categories, {HistoryCategory.items});
    });

    test('getter returns null when key is absent', () {
      final query = HistoryQuery();
      expect(query.categories, isNull);
    });

    test('setter sets comma-separated category names', () {
      final query = HistoryQuery();
      query.categories = {HistoryCategory.items, HistoryCategory.searches};
      expect(query.self['search[category]'], 'items,searches');
    });

    test('setter removes key when set to null', () {
      final query = HistoryQuery(categories: [HistoryCategory.items]);
      query.categories = null;
      expect(query.self['search[category]'], isNull);
    });
  });

  group('HistoryQuery.types', () {
    test('getter returns types for valid values', () {
      final query = HistoryQuery.from({
        'search[type]': 'posts,pools,topics',
      });
      expect(query.types, {
        HistoryType.posts,
        HistoryType.pools,
        HistoryType.topics,
      });
    });

    test('getter ignores invalid type names', () {
      final query = HistoryQuery.from({'search[type]': 'posts,bogus'});
      expect(query.types, {HistoryType.posts});
    });

    test('getter returns null when key is absent', () {
      final query = HistoryQuery();
      expect(query.types, isNull);
    });

    test('setter sets comma-separated type names', () {
      final query = HistoryQuery();
      query.types = {HistoryType.posts, HistoryType.users};
      expect(query.self['search[type]'], 'posts,users');
    });

    test('setter removes key when set to null', () {
      final query = HistoryQuery(types: [HistoryType.posts]);
      query.types = null;
      expect(query.self['search[type]'], isNull);
    });
  });

  group('HistoryQuery.link, title, subtitle', () {
    test('link getter and setter', () {
      final query = HistoryQuery();
      query.link = '/pools/5';
      expect(query.link, '/pools/5');
      query.link = null;
      expect(query.link, isNull);
    });

    test('title getter and setter', () {
      final query = HistoryQuery();
      query.title = 'A title';
      expect(query.title, 'A title');
      query.title = null;
      expect(query.title, isNull);
    });

    test('subtitle getter and setter', () {
      final query = HistoryQuery();
      query.subtitle = 'A subtitle';
      expect(query.subtitle, 'A subtitle');
      query.subtitle = null;
      expect(query.subtitle, isNull);
    });
  });

  group('HistoryQuery.copy', () {
    test('creates an independent copy', () {
      final query = HistoryQuery(
        link: '/posts/1',
        title: 'Original',
        date: DateTime(2024),
      );
      final copy = query.copy();

      copy.title = 'Modified';
      copy.link = '/posts/2';

      expect(query.title, 'Original');
      expect(query.link, '/posts/1');
      expect(copy.title, 'Modified');
      expect(copy.link, '/posts/2');
    });

    test('copy preserves all fields', () {
      final query = HistoryQuery(
        date: DateTime(2024, 5, 10),
        link: '/posts/99',
        title: 'Title',
        subtitle: 'Subtitle',
        categories: [HistoryCategory.items],
        types: [HistoryType.posts],
      );
      final copy = query.copy();
      expect(copy.date, DateTime(2024, 5, 10));
      expect(copy.link, '/posts/99');
      expect(copy.title, 'Title');
      expect(copy.subtitle, 'Subtitle');
      expect(copy.categories, {HistoryCategory.items});
      expect(copy.types, {HistoryType.posts});
    });
  });
}
