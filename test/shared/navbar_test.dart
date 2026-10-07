// SPDX-License-Identifier: AGPL-3.0

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/app/data/storage.dart';
import 'package:kilt/app/routing/app_routes.dart';
import 'package:kilt/identity/identity.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/shared/shared.dart';
import 'package:provider/provider.dart' as provider;

void main() {
  Widget buildNavbar(
    NavbarPlacement placement, {
    double? width,
    List<NavItem>? items,
  }) {
    final identityClient = _TestIdentityClient();
    addTearDown(identityClient.dispose);
    return ProviderScope(
      overrides: [
        if (items != null)
          navigationProvider.overrideWith(() => _TestNavigationNotifier(items)),
      ],
      child: provider.ChangeNotifierProvider<IdentityClient>.value(
        value: identityClient,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ResponsiveNavbar(
              placement: placement,
              layoutWidth: width,
            ),
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

      expect(find.text('Kilt'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('centers icons when sidebar is collapsed', (tester) async {
      await setSize(tester, 700);
      await tester.pumpWidget(
        buildNavbar(NavbarPlacement.sidebar, width: 700),
      );
      await tester.pumpAndSettle();

      const sidebarCenterX = 36.0;
      for (final icon in [
        Icons.home,
        Icons.settings,
        Icons.keyboard_double_arrow_right,
      ]) {
        expect(
          tester.getCenter(find.byIcon(icon)).dx,
          closeTo(sidebarCenterX, 0.01),
        );
      }
    });

    testWidgets('left-aligns icons when sidebar is expanded', (tester) async {
      await setSize(tester, 1000);
      await tester.pumpWidget(
        buildNavbar(NavbarPlacement.sidebar, width: 1000),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getCenter(find.byIcon(Icons.home)).dx,
        lessThan(36.0),
      );
    });
  });
}

String _homeLabel(AppLocalizations l10n) => 'Home';
String _searchLabel(AppLocalizations l10n) => 'Search';
String _feedsLabel(AppLocalizations l10n) => 'Feeds';

class _TestIdentityClient extends IdentityClient {
  _TestIdentityClient()
    : super(database: AppDatabase(NativeDatabase.memory()));

  @override
  Identity get identity => const Identity(
    id: 1,
    host: 'example.com',
    username: null,
    headers: null,
  );

  @override
  Future<void> activate(int? id) async {}

  @override
  void dispose() {
    attachedDatabase.close();
    super.dispose();
  }
}

class _TestNavigationNotifier extends NavigationNotifier {
  _TestNavigationNotifier(this._items);

  final List<NavItem> _items;

  @override
  NavigationState build() => NavigationState(items: _items);
}
