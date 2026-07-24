import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/client/client.dart';
import 'package:kilt/post/post.dart';
import 'package:kilt/traits/traits.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  late MockClient mockClient;
  late MockPostClient mockPosts;
  late ValueNotifier<Traits> traits;

  setUpAll(() {
    registerFallbackValue('');
    registerFallbackValue(0);
    registerFallbackValue(false);
    registerFallbackValue(CancelToken());
    registerFallbackValue(<String, String>{});
  });

  setUp(() {
    mockClient = MockClient();
    mockPosts = MockPostClient();
    traits = ValueNotifier(
      Traits(
        id: 1,
        userId: null,
        denylist: [],
        homeTags: '',
        avatar: null,
        perPage: null,
      ),
    );

    when(() => mockClient.traits).thenReturn(traits);
    when(() => mockClient.posts).thenReturn(mockPosts);
    when(
      () => mockPosts.byHot(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        query: any(named: 'query'),
        force: any(named: 'force'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((_) async => []);
    when(
      () => mockPosts.byPopular(
        scale: any(named: 'scale'),
        date: any(named: 'date'),
        force: any(named: 'force'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((_) async => []);
  });

  HotPostController makeController({
    PopularScale scale = PopularScale.day,
    DateTime? referenceDate,
  }) {
    return HotPostController(
      client: mockClient,
      scale: scale,
      referenceDate: referenceDate,
    );
  }

  group('HotPostController date tags', () {
    test('day scale with today produces date:today', () {
      final today = DateUtils.dateOnly(DateTime.now());
      final controller = makeController(
        scale: PopularScale.day,
        referenceDate: today,
      );
      expect(controller.query['tags'], 'date:today');
    });

    test('day scale with yesterday produces date:yesterday', () {
      final yesterday = DateUtils.dateOnly(
        DateTime.now().subtract(const Duration(days: 1)),
      );
      final controller = makeController(
        scale: PopularScale.day,
        referenceDate: yesterday,
      );
      expect(controller.query['tags'], 'date:yesterday');
    });

    test('day scale with a specific date produces date:yyyy-MM-dd', () {
      final controller = makeController(
        scale: PopularScale.day,
        referenceDate: DateTime(2024, 1, 15),
      );
      expect(controller.query['tags'], 'date:2024-01-15');
    });

    test('week scale produces a Monday-to-Sunday range', () {
      // 2024-01-17 is a Wednesday
      final controller = makeController(
        scale: PopularScale.week,
        referenceDate: DateTime(2024, 1, 17),
      );
      expect(controller.query['tags'], 'date:2024-01-15..2024-01-21');
    });

    test('month scale produces a first-to-last-day range', () {
      final controller = makeController(
        scale: PopularScale.month,
        referenceDate: DateTime(2024, 1, 15),
      );
      expect(controller.query['tags'], 'date:2024-01-01..2024-01-31');
    });

    test('hot scale produces order:hot', () {
      final controller = makeController(
        scale: PopularScale.hot,
        referenceDate: DateTime(2024, 1, 15),
      );
      expect(controller.query['tags'], 'order:hot');
    });
  });

  group('HotPostController.setScale', () {
    test('changes the query when the scale changes', () {
      final controller = makeController(
        scale: PopularScale.day,
        referenceDate: DateTime(2024, 1, 15),
      );
      expect(controller.query['tags'], 'date:2024-01-15');

      controller.setScale(PopularScale.hot);
      expect(controller.query['tags'], 'order:hot');
    });

    test('does nothing when the scale stays the same', () {
      final controller = makeController(
        scale: PopularScale.day,
        referenceDate: DateTime(2024, 1, 15),
      );
      final initialQuery = Map.of(controller.query);

      controller.setScale(PopularScale.day);
      expect(controller.query, initialQuery);
    });
  });

  group('HotPostController.setReferenceDate', () {
    test('changes the query when the date changes', () {
      final controller = makeController(
        scale: PopularScale.day,
        referenceDate: DateTime(2024, 1, 15),
      );
      expect(controller.query['tags'], 'date:2024-01-15');

      controller.setReferenceDate(DateTime(2023, 6, 15));
      expect(controller.query['tags'], 'date:2023-06-15');
    });

    test('does nothing when the date stays the same', () {
      final controller = makeController(
        scale: PopularScale.day,
        referenceDate: DateTime(2024, 1, 15),
      );
      final initialQuery = Map.of(controller.query);

      controller.setReferenceDate(DateTime(2024, 1, 15));
      expect(controller.query, initialQuery);
    });
  });

  group('HotPostController.prev', () {
    test('day scale moves back one day', () {
      final controller = makeController(
        scale: PopularScale.day,
        referenceDate: DateTime(2024, 1, 15),
      );
      controller.prev();
      expect(controller.query['tags'], 'date:2024-01-14');
    });

    test('week scale moves back one week', () {
      // 2024-01-17 is a Wednesday
      final controller = makeController(
        scale: PopularScale.week,
        referenceDate: DateTime(2024, 1, 17),
      );
      controller.prev();
      // 2024-01-10 (Wednesday) -> week of 2024-01-08..2024-01-14
      expect(controller.query['tags'], 'date:2024-01-08..2024-01-14');
    });

    test('month scale moves back one month', () {
      final controller = makeController(
        scale: PopularScale.month,
        referenceDate: DateTime(2024, 1, 15),
      );
      controller.prev();
      // December 2023
      expect(controller.query['tags'], 'date:2023-12-01..2023-12-31');
    });
  });

  group('HotPostController.next', () {
    test('day scale moves forward one day', () {
      final controller = makeController(
        scale: PopularScale.day,
        referenceDate: DateTime(2024, 1, 15),
      );
      controller.next();
      expect(controller.query['tags'], 'date:2024-01-16');
    });

    test('week scale moves forward one week', () {
      // 2024-01-17 is a Wednesday
      final controller = makeController(
        scale: PopularScale.week,
        referenceDate: DateTime(2024, 1, 17),
      );
      controller.next();
      // 2024-01-24 (Wednesday) -> week of 2024-01-22..2024-01-28
      expect(controller.query['tags'], 'date:2024-01-22..2024-01-28');
    });

    test('month scale moves forward one month', () {
      final controller = makeController(
        scale: PopularScale.month,
        referenceDate: DateTime(2024, 1, 15),
      );
      controller.next();
      // February 2024 (leap year)
      expect(controller.query['tags'], 'date:2024-02-01..2024-02-29');
    });

    test('does nothing when next would be in the future', () {
      final today = DateUtils.dateOnly(DateTime.now());
      final controller = makeController(
        scale: PopularScale.day,
        referenceDate: today,
      );
      final initialQuery = Map.of(controller.query);

      controller.next();
      expect(controller.query, initialQuery);
    });
  });

  group('HotPostController.canNext', () {
    test('false when the next day is in the future', () {
      final today = DateUtils.dateOnly(DateTime.now());
      final controller = makeController(
        scale: PopularScale.day,
        referenceDate: today,
      );
      expect(controller.canNext, isFalse);
    });

    test('true when the next day is today or earlier', () {
      final yesterday = DateUtils.dateOnly(
        DateTime.now().subtract(const Duration(days: 1)),
      );
      final controller = makeController(
        scale: PopularScale.day,
        referenceDate: yesterday,
      );
      expect(controller.canNext, isTrue);
    });

    test('true for a date far in the past', () {
      final controller = makeController(
        scale: PopularScale.day,
        referenceDate: DateTime(2024, 1, 15),
      );
      expect(controller.canNext, isTrue);
    });
  });
}

class MockClient extends Mock implements Client {}

class MockPostClient extends Mock implements PostClient {}
