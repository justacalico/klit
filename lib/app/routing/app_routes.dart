import 'package:flutter/material.dart' show IconData, Icons;

abstract class AppRoutes {
  static const String home = '/';
  static const String hot = '/hot';
  static const String search = '/search';
  static const String feeds = '/feeds';
  static const String favorites = '/favorites';
  static const String bookmarks = '/bookmarks';
  static const String pools = '/pools';
  static const String forum = '/forum';
  static const String history = '/history';
  static const String finishes = '/finishes';
  static const String profile = '/profile';
  static const String blacklist = '/blacklist';
  static const String settings = '/settings';

  static const List<(String path, String label, IconData icon)> navItems = [
    (home, 'Home', Icons.home),
    (hot, 'Popular', Icons.whatshot),
    (search, 'Search', Icons.search),
    (feeds, 'Feeds', Icons.rss_feed),
    (profile, 'Profile', Icons.person),
    (pools, 'Pools', Icons.collections),
    (forum, 'Forum', Icons.forum),
    (history, 'History', Icons.history),
    (finishes, 'Finishes', Icons.check_circle),
    (settings, 'Settings', Icons.settings),
  ];
}
