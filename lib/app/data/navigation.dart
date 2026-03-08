import 'package:klit/feed/feed.dart';
import 'package:klit/finish/finish.dart';
import 'package:klit/history/history.dart';
import 'package:klit/user/user.dart';
import 'package:klit/pool/pool.dart';
import 'package:klit/post/post.dart';
import 'package:klit/settings/settings.dart';
import 'package:klit/shared/shared.dart';
import 'package:klit/topic/topic.dart';
import 'package:klit/traits/traits.dart';
import 'package:flutter/material.dart';

const String _drawerSearchGroup = 'search';
const String _drawerFollowsGroup = 'follows';
const String _drawerCollectionsGroup = 'collections';
const String _drawerSettingsGroup = 'settings';

final List<RouterDrawerDestination> rootDestintations = [
  NamedRouterDrawerDestination(
    path: '/',
    name: 'Home',
    icon: const Icon(Icons.home),
    builder: (context) => const HomePage(),
    unique: true,
    group: _drawerSearchGroup,
  ),
  NamedRouterDrawerDestination(
    path: '/hot',
    name: 'Popular',
    icon: const Icon(Icons.whatshot),
    builder: (context) => const HotPage(),
    unique: true,
    group: _drawerSearchGroup,
  ),
  NamedRouterDrawerDestination(
    path: '/search',
    name: 'Search',
    icon: const Icon(Icons.search),
    builder: (context) => const PostsSearchPage(),
    group: _drawerSearchGroup,
  ),
  NamedRouterDrawerDestination(
    path: '/feeds',
    name: 'Feeds',
    icon: const Icon(Icons.rss_feed),
    builder: (context) => const FeedsPage(),
    group: _drawerSearchGroup,
  ),
  NamedRouterDrawerDestination(
    path: '/profile',
    name: 'Profile',
    icon: const Icon(Icons.person),
    builder: (context) => const ProfilePage(),
    unique: true,
    group: _drawerFollowsGroup,
  ),
  NamedRouterDrawerDestination(
    path: '/pools',
    name: 'Pools',
    icon: const Icon(Icons.collections),
    builder: (context) => const PoolsPage(),
    unique: true,
    group: _drawerCollectionsGroup,
  ),
  NamedRouterDrawerDestination(
    path: '/forum',
    name: 'Forum',
    icon: const Icon(Icons.forum),
    builder: (context) => const TopicsPage(),
    unique: true,
    group: _drawerCollectionsGroup,
  ),
  NamedRouterDrawerDestination(
    path: '/history',
    name: 'History',
    icon: const Icon(Icons.history),
    builder: (context) => const HistoriesPage(),
    group: _drawerSettingsGroup,
  ),
  NamedRouterDrawerDestination(
    path: '/finishes',
    name: 'Finishes',
    icon: const Icon(Icons.check_circle),
    builder: (context) => const FinishesPage(),
    visible: (context) => context.read<Settings>().iFinishedEnabled.value,
    group: _drawerSettingsGroup,
  ),
  RouterDrawerDestination(
    path: '/blacklist',
    builder: (context) => const DenyListPage(),
  ),
  NamedRouterDrawerDestination(
    path: '/settings',
    name: 'Settings',
    icon: const Icon(Icons.settings),
    builder: (context) => const SettingsPage(),
    enabled: _nonRecursive<SettingsPage>,
    group: _drawerSettingsGroup,
  ),
];

bool _nonRecursive<T extends Widget>(BuildContext context) =>
    context.findAncestorWidgetOfExactType<T>() == null;
