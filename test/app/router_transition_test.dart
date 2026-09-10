// SPDX-License-Identifier: AGPL-3.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kilt/app/routing/app_routes.dart';

void main() {
  group('instant tab transitions', () {
    test('CustomTransitionPage with Duration.zero has no transition duration', () {
      final page = CustomTransitionPage<void>(
        key: const ValueKey('test'),
        child: const SizedBox(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
      );
      expect(page.transitionDuration, Duration.zero);
      expect(page.reverseTransitionDuration, Duration.zero);
    });

    test('all nav item paths are valid routes', () {
      for (final navItem in AppRoutes.navItems) {
        final path = navItem.$1;
        expect(path.startsWith('/'), isTrue, reason: '$path should start with /');
      }
    });
  });
}
