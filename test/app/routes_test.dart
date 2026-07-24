import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/app/routing/app_routes.dart';

void main() {
  group('AppRoutes', () {
    test('home route is root', () {
      expect(AppRoutes.home, '/');
    });

    test('hot route', () {
      expect(AppRoutes.hot, '/hot');
    });

    test('search route', () {
      expect(AppRoutes.search, '/search');
    });

    test('feeds route', () {
      expect(AppRoutes.feeds, '/feeds');
    });

    test('favorites route', () {
      expect(AppRoutes.favorites, '/favorites');
    });

    test('bookmarks route', () {
      expect(AppRoutes.bookmarks, '/bookmarks');
    });

    test('pools route', () {
      expect(AppRoutes.pools, '/pools');
    });

    test('forum route', () {
      expect(AppRoutes.forum, '/forum');
    });

    test('history route', () {
      expect(AppRoutes.history, '/history');
    });

    test('finishes route', () {
      expect(AppRoutes.finishes, '/finishes');
    });

    test('profile route', () {
      expect(AppRoutes.profile, '/profile');
    });

    test('blacklist route', () {
      expect(AppRoutes.blacklist, '/blacklist');
    });

    test('settings route', () {
      expect(AppRoutes.settings, '/settings');
    });

    test('all routes are unique strings starting with /', () {
      final routes = [
        AppRoutes.home,
        AppRoutes.hot,
        AppRoutes.search,
        AppRoutes.feeds,
        AppRoutes.favorites,
        AppRoutes.bookmarks,
        AppRoutes.pools,
        AppRoutes.forum,
        AppRoutes.history,
        AppRoutes.finishes,
        AppRoutes.profile,
        AppRoutes.blacklist,
        AppRoutes.settings,
      ];
      expect(routes.toSet().length, routes.length);
      for (final route in routes) {
        expect(route.startsWith('/'), isTrue);
      }
    });
  });

  group('AppRoutes.navItems', () {
    test('has 10 items', () {
      expect(AppRoutes.navItems.length, 10);
    });

    test('each item has path, labelKey, and icon', () {
      for (final item in AppRoutes.navItems) {
        expect(item.$1, isNotEmpty);
        expect(item.$1.startsWith('/'), isTrue);
        expect(item.$2, isNotEmpty);
        expect(item.$3, isA<IconData>());
      }
    });

    test('contains home route', () {
      expect(
        AppRoutes.navItems.any((e) => e.$1 == AppRoutes.home),
        isTrue,
      );
    });

    test('contains hot route', () {
      expect(
        AppRoutes.navItems.any((e) => e.$1 == AppRoutes.hot),
        isTrue,
      );
    });

    test('contains search route', () {
      expect(
        AppRoutes.navItems.any((e) => e.$1 == AppRoutes.search),
        isTrue,
      );
    });

    test('contains feeds route', () {
      expect(
        AppRoutes.navItems.any((e) => e.$1 == AppRoutes.feeds),
        isTrue,
      );
    });

    test('contains profile route', () {
      expect(
        AppRoutes.navItems.any((e) => e.$1 == AppRoutes.profile),
        isTrue,
      );
    });

    test('contains pools route', () {
      expect(
        AppRoutes.navItems.any((e) => e.$1 == AppRoutes.pools),
        isTrue,
      );
    });

    test('contains forum route', () {
      expect(
        AppRoutes.navItems.any((e) => e.$1 == AppRoutes.forum),
        isTrue,
      );
    });

    test('contains history route', () {
      expect(
        AppRoutes.navItems.any((e) => e.$1 == AppRoutes.history),
        isTrue,
      );
    });

    test('contains finishes route', () {
      expect(
        AppRoutes.navItems.any((e) => e.$1 == AppRoutes.finishes),
        isTrue,
      );
    });

    test('contains settings route', () {
      expect(
        AppRoutes.navItems.any((e) => e.$1 == AppRoutes.settings),
        isTrue,
      );
    });

    test('does not contain favorites route', () {
      expect(
        AppRoutes.navItems.any((e) => e.$1 == AppRoutes.favorites),
        isFalse,
      );
    });

    test('does not contain bookmarks route', () {
      expect(
        AppRoutes.navItems.any((e) => e.$1 == AppRoutes.bookmarks),
        isFalse,
      );
    });

    test('does not contain blacklist route', () {
      expect(
        AppRoutes.navItems.any((e) => e.$1 == AppRoutes.blacklist),
        isFalse,
      );
    });

    test('all nav item paths are unique', () {
      final paths = AppRoutes.navItems.map((e) => e.$1).toList();
      expect(paths.toSet().length, paths.length);
    });

    test('all label keys are unique', () {
      final keys = AppRoutes.navItems.map((e) => e.$2).toList();
      expect(keys.toSet().length, keys.length);
    });

    test('first nav item is home', () {
      expect(AppRoutes.navItems.first.$1, AppRoutes.home);
      expect(AppRoutes.navItems.first.$2, 'navHome');
    });

    test('last nav item is settings', () {
      expect(AppRoutes.navItems.last.$1, AppRoutes.settings);
      expect(AppRoutes.navItems.last.$2, 'navSettings');
    });
  });
}
