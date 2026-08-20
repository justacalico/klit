// SPDX-License-Identifier: AGPL-3.0

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/app/data/nav_items.dart';
import 'package:kilt/app/routing/app_routes.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/shared/controller/navigation_controller.dart';
import 'package:kilt/shared/shared.dart';

void main() {
  Widget buildNavbar(
    NavbarPlacement placement, {
    double? width,
    List<NavItem>? items,
  }) {
    final overrides = <Override>[];
    if (items != null) {
      overrides.add(
        navigationProvider.overrideWith(() => _TestNavigationNotifier(items)),
      );
    }

    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ResponsiveNavbar(
            placement: placement,
            showFavorites: true,
            showHistory: true,
            showFinishes: true,
            layoutWidth: width,
          ),
        ),
      ),
    );
  }

  Future<void> setSize(WidgetTester tester, double width) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = Size(width, 800);
    addTearDown(tester.view.reset);
  }

  const home = NavItem(AppRoutes.home, _homeLabel, Icons.home);
  const search = NavItem(AppRoutes.search, _searchLabel, Icons.search);
  const feeds = NavItem(AppRoutes.feeds, _feedsLabel, Icons.rss_feed);

  group('ResponsiveNavbar', () {
    testWidgets('renders bottom nav with primary labels and more button',
        (tester) async {
      await setSize(tester, 400);
      await tester.pumpWidget(buildNavbar(NavbarPlacement.bottom));
      await tester.pumpAndSettle();

      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Feeds'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);
    });

    testWidgets('renders top full nav with labels when width is wide',
        (tester) async {
      await setSize(tester, 1200);
      await tester.pumpWidget(
        buildNavbar(NavbarPlacement.top, items: const [home, search, feeds]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Feeds'), findsOneWidget);
    });

    testWidgets('renders compact top nav without labels when width is narrow',
        (tester) async {
      await setSize(tester, 700);
      await tester.pumpWidget(
        buildNavbar(NavbarPlacement.top, items: const [home, search, feeds]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsNothing);
      expect(find.byIcon(Icons.home), findsOneWidget);
    });

    testWidgets('renders sidebar without crashing', (tester) async {
      await setSize(tester, 1000);
      await tester.pumpWidget(
        buildNavbar(NavbarPlacement.sidebar, width: 1000),
      );
      await tester.pumpAndSettle();

      expect(find.text('Klit'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });
  });
}

String _homeLabel(AppLocalizations l10n) => 'Home';
String _searchLabel(AppLocalizations l10n) => 'Search';
String _feedsLabel(AppLocalizations l10n) => 'Feeds';

class _TestNavigationNotifier extends NavigationNotifier {
  _TestNavigationNotifier(this._items);

  final List<NavItem> _items;

  @override
  NavigationState build() => NavigationState(items: _items);
}
