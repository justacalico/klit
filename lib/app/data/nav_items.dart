import 'package:flutter/material.dart';
import 'package:klit/app/routing/app_routes.dart';

class NavItem {
  const NavItem(this.path, this.label, this.icon);
  final String path;
  final String label;
  final IconData icon;
}

const List<NavItem> appNavItems = [
  NavItem(AppRoutes.home, 'Home', Icons.home),
  NavItem(AppRoutes.hot, 'Popular', Icons.whatshot),
  NavItem(AppRoutes.search, 'Search', Icons.search),
  NavItem(AppRoutes.feeds, 'Feeds', Icons.rss_feed),
  NavItem(AppRoutes.profile, 'Profile', Icons.person),
  NavItem(AppRoutes.pools, 'Pools', Icons.collections),
  NavItem(AppRoutes.forum, 'Forum', Icons.forum),
  NavItem(AppRoutes.history, 'History', Icons.history),
  NavItem(AppRoutes.finishes, 'Finishes', Icons.check_circle),
  NavItem(AppRoutes.settings, 'Settings', Icons.settings),
];
