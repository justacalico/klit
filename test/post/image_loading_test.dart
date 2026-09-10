// SPDX-License-Identifier: AGPL-3.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/post/post.dart';
import 'package:kilt/shared/shared.dart';

import '../helpers/test_posts.dart';

void main() {
  group('PostImageTile defaults', () {
    test('PostImageTile showProgress is null by default (resolved to true in build)', () {
      final post = makePost();
      final tile = PostImageTile(post: post);
      expect(tile.showProgress, isNull);
    });

    test('PostImageTile withLowRes is null by default (resolved to true in build)', () {
      final post = makePost();
      final tile = PostImageTile(post: post);
      expect(tile.withLowRes, isNull);
    });
  });

  group('defaultErrorBuilder', () {
    testWidgets('shows a warning icon', (tester) async {
      late final BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                ctx = context;
                return defaultErrorBuilder(context, 'url', 'error');
              },
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
    });
  });
}
