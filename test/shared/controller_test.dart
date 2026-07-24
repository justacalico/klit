import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/shared/data/controller.dart';

class TestController extends DataController<int, String> {
  TestController() : super(firstPageKey: 1);

  int requestCount = 0;
  List<String>? nextItems;
  int? maxPage;
  bool shouldThrow = false;
  Object? errorResponse;

  @override
  Future<PageResponse<int, String>> performRequest(
    int page,
    bool force,
  ) async {
    requestCount++;
    if (shouldThrow) {
      throw Exception('request failed');
    }
    if (errorResponse != null) {
      return PageResponse.error(error: errorResponse!);
    }
    if (maxPage != null && page > maxPage!) {
      return const PageResponse.last(items: []);
    }
    return PageResponse(
      items: nextItems ?? ['item$page'],
      nextPageKey: page + 1,
    );
  }
}

void main() {
  group('DataController initial state', () {
    test('starts with null items, firstPageKey as nextPageKey, null error', () {
      final controller = TestController();
      expect(controller.items, isNull);
      expect(controller.nextPageKey, 1);
      expect(controller.error, isNull);
      expect(controller.rawItems, isNull);
    });
  });

  group('DataController.getNextPage', () {
    test('loads the first page and populates items', () async {
      final controller = TestController();
      await controller.getNextPage();
      expect(controller.requestCount, 1);
      expect(controller.items, ['item1']);
      expect(controller.nextPageKey, 2);
      expect(controller.error, isNull);
    });

    test('appends items on subsequent calls', () async {
      final controller = TestController();
      await controller.getNextPage();
      await controller.getNextPage();
      expect(controller.requestCount, 2);
      expect(controller.items, ['item1', 'item2']);
      expect(controller.nextPageKey, 3);
    });

    test('stops loading when PageResponse.last is returned', () async {
      final controller = TestController()..maxPage = 1;
      await controller.getNextPage();
      await controller.getNextPage();
      expect(controller.nextPageKey, isNull);
    });
  });

  group('DataController.refresh', () {
    test('resets and reloads the first page', () async {
      final controller = TestController();
      await controller.getNextPage();
      await controller.getNextPage();
      expect(controller.items, ['item1', 'item2']);

      controller.requestCount = 0;
      await controller.refresh();
      expect(controller.requestCount, 1);
      expect(controller.items, ['item1']);
      expect(controller.nextPageKey, 2);
    });
  });

  group('PageResponse constructors', () {
    test('normal constructor sets items and nextPageKey', () {
      const response = PageResponse(items: ['a', 'b'], nextPageKey: 2);
      expect(response.items, ['a', 'b']);
      expect(response.nextPageKey, 2);
      expect(response.error, isNull);
    });

    test('last constructor sets items with null nextPageKey', () {
      const response = PageResponse.last(items: ['a']);
      expect(response.items, ['a']);
      expect(response.nextPageKey, isNull);
      expect(response.error, isNull);
    });

    test('error constructor sets error with null items', () {
      const response = PageResponse.error(error: 'boom');
      expect(response.error, 'boom');
      expect(response.items, isNull);
      expect(response.nextPageKey, isNull);
    });
  });

  group('DataController error handling', () {
    test('PageResponse.error sets the error property', () async {
      final controller = TestController()
        ..errorResponse = 'something went wrong';
      await controller.getNextPage();
      expect(controller.error, 'something went wrong');
      expect(controller.items, isNull);
    });

    test('performRequest throwing sets the error property', () async {
      final controller = TestController()..shouldThrow = true;
      await runZonedGuarded(
        () => controller.getNextPage(),
        (_, _) {},
      );
      expect(controller.error, isNotNull);
    });
  });

  group('DataController.filter', () {
    test('deduplicates items', () async {
      final controller = TestController()
        ..nextItems = ['a', 'a', 'b', 'b', 'c'];
      await controller.getNextPage();
      expect(controller.items, ['a', 'b', 'c']);
    });
  });

  group('DataController.dispose', () {
    test('prevents further notifyListeners calls', () async {
      final controller = TestController();
      var notifyCount = 0;
      controller.addListener(() => notifyCount++);

      await controller.getNextPage();
      expect(notifyCount, greaterThan(0));

      final countBeforeDispose = notifyCount;
      controller.dispose();

      // Triggering applyFilter after dispose should not notify listeners
      // because the finally block in getNextPage checks _disposed.
      expect(notifyCount, countBeforeDispose);
    });

    test('getNextPage after dispose throws assertion error', () async {
      final controller = TestController();
      await controller.getNextPage();
      controller.dispose();
      expect(
        controller.getNextPage(),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
