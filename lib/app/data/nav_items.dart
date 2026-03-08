import 'package:klit/app/routes/app_routes.dart';
import 'package:klit/shared/controller/navigation_controller.dart';
import 'package:flutter/material.dart';

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
