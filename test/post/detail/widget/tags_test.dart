import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kilt/post/post.dart';
import 'package:kilt/tag/tag.dart';

import '../../../helpers/test_posts.dart';

void main() {
  group('TagDisplay', () {
    testWidgets('bounds the tag list and makes it scrollable', (tester) async {
      final post = makePost(tags: {
        'general': ['fox', 'canine', 'furry'],
        'species': ['dog'],
      });

      await tester.pumpWidget(
        MaterialApp(
          home: TagDisplay(post: post),
        ),
      );
      await tester.pumpAndSettle();

      final box = tester.widget<ConstrainedBox>(
        find.byWidgetPredicate(
          (widget) =>
              widget is ConstrainedBox && widget.constraints.maxHeight == 400,
        ),
      );
      expect(box.constraints.maxHeight, 400);

      final scrollView = tester.widget<SingleChildScrollView>(
        find.descendant(
          of: find.byType(TagDisplay),
          matching: find.byType(SingleChildScrollView),
        ),
      );
      expect(scrollView.primary, isFalse);

      expect(find.text('General'), findsOneWidget);
      expect(find.text('Species'), findsOneWidget);
      expect(find.byType(TagCard), findsNWidgets(4));
    });

    testWidgets('hides when there are no tags', (tester) async {
      final post = makePost(tags: {});

      await tester.pumpWidget(
        MaterialApp(
          home: TagDisplay(post: post),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TagCard), findsNothing);
      expect(
        find.descendant(
          of: find.byType(TagDisplay),
          matching: find.byType(SingleChildScrollView),
        ),
        findsOneWidget,
      );
    });

    testWidgets('tapping a tag navigates to search', (tester) async {
      final post = makePost(tags: {
        'general': ['fox'],
      });

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => TagDisplay(post: post),
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) =>
                const SizedBox.shrink(key: ValueKey('search')),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('fox'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('search')), findsOneWidget);
    });
  });
}
