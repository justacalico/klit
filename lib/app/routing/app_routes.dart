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

  static const List<(String path, String labelKey, IconData icon)> navItems = [
    (home, 'navHome', Icons.home),
    (hot, 'navPopular', Icons.whatshot),
    (search, 'navSearch', Icons.search),
    (feeds, 'navFeeds', Icons.rss_feed),
    (profile, 'navProfile', Icons.person),
    (pools, 'navPools', Icons.collections),
    (forum, 'navForum', Icons.forum),
    (history, 'navHistory', Icons.history),
    (finishes, 'navFinishes', Icons.check_circle),
    (settings, 'navSettings', Icons.settings),
  ];
}
