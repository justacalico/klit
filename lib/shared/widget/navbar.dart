// SPDX-License-Identifier: AGPL-3.0

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kilt/app/routing/app_routes.dart';
import 'package:kilt/identity/identity.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/settings/widget/icon.dart';
import 'package:kilt/shared/controller/navigation_controller.dart';
import 'package:kilt/shared/data/provider.dart';
import 'package:kilt/shared/widget/glass.dart';
import 'package:kilt/shared/widget/popups.dart';
import 'package:kilt/user/user.dart';

part 'navbar/bottom.dart';
part 'navbar/sidebar.dart';
part 'navbar/top.dart';

const double mobileBreakpoint = 600;
const double compactBreakpoint = 900;
const double sidebarAutoCollapseBreakpoint = 800;
const String _historyPath = '/history';
const String _profilePath = '/profile';

enum NavbarPlacement { top, bottom, sidebar }

class _NavAdapter {
  _NavAdapter(this._ref, this._context);

  final WidgetRef _ref;
  final BuildContext _context;

  NavigationState get state => _ref.watch(navigationProvider);
  List<NavItem> get items => state.items;
  int get mobilePrimaryCount => state.mobilePrimaryCount;
  int get currentIndex => state.currentIndex;
  bool get sidebarCollapsed => state.sidebarCollapsed;

  void goTo(int index) {
    final path = _ref.read(navigationProvider.notifier).goTo(index);
    _context.go(path);
  }

  void toggleSidebar() =>
      _ref.read(navigationProvider.notifier).toggleSidebar();
  void setSidebarCollapsed(bool v) =>
      _ref.read(navigationProvider.notifier).setSidebarCollapsed(v);
  void autoExpandSidebar() =>
      _ref.read(navigationProvider.notifier).autoExpandSidebar();
}

class ResponsiveNavbar extends ConsumerWidget {
  const ResponsiveNavbar({
    super.key,
    required this.placement,
    this.showFavorites = true,
    this.showHistory = true,
    this.showFinishes = true,
    this.layoutWidth,
  });

  final NavbarPlacement placement;
  final bool showFavorites;
  final bool showHistory;
  final bool showFinishes;
  final double? layoutWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = _NavAdapter(ref, context);
    if (placement == NavbarPlacement.bottom) {
      return _BottomNavBar(
        controller: nav,
        showFavorites: showFavorites,
        showHistory: showHistory,
        showFinishes: showFinishes,
      );
    }
    if (placement == NavbarPlacement.sidebar) {
      return _Sidebar(
        controller: nav,
        showFavorites: showFavorites,
        showHistory: showHistory,
        showFinishes: showFinishes,
        layoutWidth: layoutWidth,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        if (w < compactBreakpoint) {
          return _CompactNavBar(
            controller: nav,
            showFavorites: showFavorites,
            showHistory: showHistory,
            showFinishes: showFinishes,
          );
        }
        return _FullNavBar(
          controller: nav,
          showFavorites: showFavorites,
          showHistory: showHistory,
          showFinishes: showFinishes,
        );
      },
    );
  }
}

List<({int index, NavItem item})> _visibleNavEntries(
  List<NavItem> items,
  bool showFavorites,
  bool showHistory,
  bool showFinishes,
) {
  return items
      .asMap()
      .entries
      .where((e) {
        if (e.value.path == _historyPath && !showHistory) return false;
        if (e.value.path == _profilePath && !showFavorites) return false;
        if (e.value.path == AppRoutes.finishes && !showFinishes) return false;
        return true;
      })
      .map((e) => (index: e.key, item: e.value))
      .toList();
}
