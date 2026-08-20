// SPDX-License-Identifier: AGPL-3.0

import 'package:flutter/material.dart';
import 'package:kilt/app/routing/app_routes.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';

class NavItem {
  const NavItem(this.path, this.label, this.icon);
  final String path;
  final String Function(AppLocalizations l10n) label;
  final IconData icon;
}

String Function(AppLocalizations) _navLabel(String key) {
  return switch (key) {
    'navHome' => (l10n) => l10n.navHome,
    'navPopular' => (l10n) => l10n.navPopular,
    'navSearch' => (l10n) => l10n.navSearch,
    'navFeeds' => (l10n) => l10n.navFeeds,
    'navProfile' => (l10n) => l10n.navProfile,
    'navPools' => (l10n) => l10n.navPools,
    'navForum' => (l10n) => l10n.navForum,
    'navHistory' => (l10n) => l10n.navHistory,
    'navFinishes' => (l10n) => l10n.navFinishes,
    'navSettings' => (l10n) => l10n.navSettings,
    _ => (_) => key,
  };
}

final List<NavItem> appNavItems = [
  for (final e in AppRoutes.navItems) NavItem(e.$1, _navLabel(e.$2), e.$3),
];
