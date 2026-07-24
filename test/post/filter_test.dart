import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/client/client.dart';
import 'package:kilt/post/post.dart';
import 'package:kilt/shared/shared.dart';
import 'package:kilt/traits/traits.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_posts.dart';

void main() {
  late MockClient mockClient;
  late ValueNotifier<Traits> traits;

  setUp(() {
    mockClient = MockClient();
    traits = ValueNotifier(
      Traits(
        id: 1,
        userId: null,
        denylist: ['fox'],
        homeTags: '',
        avatar: null,
        perPage: null,
      ),
    );
    when(() => mockClient.traits).thenReturn(traits);
  });

  TestFilterController makeController({
    PostFilterMode filterMode = PostFilterMode.filtering,
    List<String> denylist = const ['fox'],
  }) {
    traits.value = traits.value.copyWith(denylist: denylist);
    return TestFilterController(
      client: mockClient,
      filterMode: filterMode,
    );
  }

  group('PostFilterableController.denying', () {
    test('setter triggers applyFilter and removes denied posts', () {
      final controller = makeController();
      final withFox = makePost(id: 1, tags: const {'general': ['fox']});
      final withoutFox = makePost(id: 2, tags: const {'general': ['dog']});

      controller.rawItems = [withFox, withoutFox];
      expect(controller.items, isNot(contains(withFox)));
      expect(controller.items, contains(withoutFox));

      controller.denying = false;
      expect(controller.items, contains(withFox));
      expect(controller.items, contains(withoutFox));
    });

    test('setter does nothing when value stays the same', () {
      final controller = makeController();
      controller.rawItems = [makePost(id: 1, tags: const {'general': ['fox']})];
      final itemsBefore = List.of(controller.items!);

      controller.denying = true;
      expect(controller.items, itemsBefore);
    });
  });

  group('PostFilterableController.allowedTags', () {
    test('setter triggers applyFilter and exempts allowed tags', () {
      final controller = makeController();
      final withFox = makePost(id: 1, tags: const {'general': ['fox']});
      final withoutFox = makePost(id: 2, tags: const {'general': ['dog']});

      controller.rawItems = [withFox, withoutFox];
      expect(controller.items, isNot(contains(withFox)));

      controller.allowedTags = ['fox'];
      expect(controller.items, contains(withFox));
      expect(controller.items, contains(withoutFox));
    });

    test('setter does nothing when value stays the same', () {
      final controller = makeController();
      controller.rawItems = [makePost(id: 1, tags: const {'general': ['fox']})];
      controller.allowedTags = ['cat'];
      final itemsBefore = List.of(controller.items!);

      controller.allowedTags = ['cat'];
      expect(controller.items, itemsBefore);
    });
  });

  group('PostFilterableController.allow', () {
    test('adds a post to the allowed list', () {
      final controller = makeController();
      final withFox = makePost(id: 1, tags: const {'general': ['fox']});

      controller.rawItems = [withFox];
      expect(controller.isAllowed(withFox), isFalse);

      controller.allow(withFox);
      expect(controller.isAllowed(withFox), isTrue);
    });

    test('keeps an allowed post in items even if it matches the denylist', () {
      final controller = makeController();
      final withFox = makePost(id: 1, tags: const {'general': ['fox']});

      controller.rawItems = [withFox];
      expect(controller.items, isNot(contains(withFox)));

      controller.allow(withFox);
      expect(controller.items, contains(withFox));
    });
  });

  group('PostFilterableController.unallow', () {
    test('removes a post from the allowed list', () {
      final controller = makeController();
      final withFox = makePost(id: 1, tags: const {'general': ['fox']});

      controller.rawItems = [withFox];
      controller.allow(withFox);
      expect(controller.isAllowed(withFox), isTrue);

      controller.unallow(withFox);
      expect(controller.isAllowed(withFox), isFalse);
      expect(controller.items, isNot(contains(withFox)));
    });
  });

  group('PostFilterableController.isAllowed', () {
    test('returns false before allowing and true after', () {
      final controller = makeController();
      final post = makePost(id: 1, tags: const {'general': ['dog']});

      controller.rawItems = [post];
      expect(controller.isAllowed(post), isFalse);

      controller.allow(post);
      expect(controller.isAllowed(post), isTrue);
    });
  });

  group('PostFilterableController.isDenied', () {
    test('returns true for a post that matches the denylist', () {
      final controller = makeController();
      final withFox = makePost(id: 1, tags: const {'general': ['fox']});
      final withoutFox = makePost(id: 2, tags: const {'general': ['dog']});

      controller.rawItems = [withFox, withoutFox];
      expect(controller.isDenied(withFox), isTrue);
      expect(controller.isDenied(withoutFox), isFalse);
    });

    test('returns false for an allowed post that matched the denylist', () {
      final controller = makeController();
      final withFox = makePost(id: 1, tags: const {'general': ['fox']});

      controller.rawItems = [withFox];
      expect(controller.isDenied(withFox), isTrue);

      controller.allow(withFox);
      expect(controller.isDenied(withFox), isFalse);
    });
  });

  group('PostFilterableController.filter', () {
    test('removes denied posts from items', () {
      final controller = makeController();
      final withFox = makePost(id: 1, tags: const {'general': ['fox']});
      final withoutFox = makePost(id: 2, tags: const {'general': ['dog']});

      controller.rawItems = [withFox, withoutFox];
      expect(controller.items, isNot(contains(withFox)));
      expect(controller.items, contains(withoutFox));
    });

    test('keeps allowed posts even if they match the denylist', () {
      final controller = makeController();
      final withFox = makePost(id: 1, tags: const {'general': ['fox']});

      controller.rawItems = [withFox];
      controller.allow(withFox);
      expect(controller.items, contains(withFox));
    });

    test('does not filter when denying is false', () {
      final controller = makeController();
      final withFox = makePost(id: 1, tags: const {'general': ['fox']});

      controller.rawItems = [withFox];
      controller.denying = false;
      expect(controller.items, contains(withFox));
    });

    test('does not filter when filterMode is unavailable', () {
      final controller = makeController(filterMode: PostFilterMode.unavailable);
      final withFox = makePost(id: 1, tags: const {'general': ['fox']});

      controller.rawItems = [withFox];
      expect(controller.items, contains(withFox));
    });

    test('marks denied posts but keeps them in plain mode', () {
      final controller = makeController(filterMode: PostFilterMode.plain);
      final withFox = makePost(id: 1, tags: const {'general': ['fox']});

      controller.rawItems = [withFox];
      expect(controller.items, contains(withFox));
      expect(controller.isDenied(withFox), isTrue);
    });
  });
}

class TestFilterController extends DataController<int, Post>
    with PostFilterableController<int> {
  TestFilterController({
    required this.client,
    this.filterMode = PostFilterMode.filtering,
  }) : super(firstPageKey: 1);

  @override
  final Client client;

  @override
  final PostFilterMode filterMode;

  @override
  Future<PageResponse<int, Post>> performRequest(int page, bool force) async {
    return const PageResponse.last(items: []);
  }
}

class MockClient extends Mock implements Client {}
