import 'package:flutter/material.dart';
import 'package:kilt/app/routing/app_routes.dart';

class NavItem {
  const NavItem(this.path, this.label, this.icon);
  final String path;
  final String label;
  final IconData icon;
}

final List<NavItem> appNavItems = [
  for (final e in AppRoutes.navItems) NavItem(e.$1, e.$2, e.$3),
];
