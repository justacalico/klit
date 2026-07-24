import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/app/data/nav_items.dart';
import 'package:kilt/app/routing/app_routes.dart';
import 'package:kilt/l10n/gen/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();

  group('appNavItems', () {
    test('has same count as AppRoutes.navItems', () {
      expect(appNavItems.length, AppRoutes.navItems.length);
    });

    test('each item has path, label function, and icon', () {
      for (final item in appNavItems) {
        expect(item.path, isNotEmpty);
        expect(item.label, isA<Function>());
        expect(item.icon, isA<IconData>());
      }
    });

    test('paths match AppRoutes.navItems', () {
      for (var i = 0; i < appNavItems.length; i++) {
        expect(appNavItems[i].path, AppRoutes.navItems[i].$1);
      }
    });

    test('icons match AppRoutes.navItems', () {
      for (var i = 0; i < appNavItems.length; i++) {
        expect(appNavItems[i].icon, AppRoutes.navItems[i].$3);
      }
    });

    test('label functions return expected strings', () {
      final expectedLabels = [
        l10n.navHome,
        l10n.navPopular,
        l10n.navSearch,
        l10n.navFeeds,
        l10n.navProfile,
        l10n.navPools,
        l10n.navForum,
        l10n.navHistory,
        l10n.navFinishes,
        l10n.navSettings,
      ];

      for (var i = 0; i < appNavItems.length; i++) {
        expect(appNavItems[i].label(l10n), expectedLabels[i]);
      }
    });

    test('first item is Home', () {
      expect(appNavItems.first.path, AppRoutes.home);
      expect(appNavItems.first.label(l10n), 'Home');
    });

    test('last item is Settings', () {
      expect(appNavItems.last.path, AppRoutes.settings);
      expect(appNavItems.last.label(l10n), 'Settings');
    });

    test('all paths are unique', () {
      final paths = appNavItems.map((e) => e.path).toList();
      expect(paths.toSet().length, paths.length);
    });

    test('all labels are unique', () {
      final labels = appNavItems.map((e) => e.label(l10n)).toList();
      expect(labels.toSet().length, labels.length);
    });
  });

  group('NavItem', () {
    test('constructor sets fields correctly', () {
      final item = NavItem(
        '/test',
        (l10n) => 'Test Label',
        Icons.star,
      );
      expect(item.path, '/test');
      expect(item.label(l10n), 'Test Label');
      expect(item.icon, Icons.star);
    });

    test('label function can be called with AppLocalizations', () {
      final item = NavItem(
        '/custom',
        (l) => l.navSearch,
        Icons.search,
      );
      expect(item.label(l10n), l10n.navSearch);
    });
  });
}
