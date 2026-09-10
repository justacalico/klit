// SPDX-License-Identifier: AGPL-3.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kilt/app/pages/blacklist_page.dart';
import 'package:kilt/app/pages/feeds_page.dart';
import 'package:kilt/app/pages/finishes_page.dart';
import 'package:kilt/app/pages/history_page.dart';
import 'package:kilt/app/pages/home_page.dart';
import 'package:kilt/app/pages/hot_page.dart';
import 'package:kilt/app/pages/pools_page.dart';
import 'package:kilt/app/pages/post/post_loading_page.dart';
import 'package:kilt/app/pages/profile_page.dart';
import 'package:kilt/app/pages/search_page.dart';
import 'package:kilt/app/pages/settings_page.dart';
import 'package:kilt/app/pages/topics_page.dart';
import 'package:kilt/app/routing/app_routes.dart';
import 'package:kilt/app/widget/main_shell.dart';

GoRouter createAppRouter(GlobalKey<NavigatorState> navigatorKey) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppRoutes.home,
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainShell(
          location: state.uri.path,
          profileUserId: _intParam(state, 'userId'),
          profileUsername: state.uri.queryParameters['username'],
          child: child,
        ),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: _instantPage,
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: AppRoutes.hot,
            pageBuilder: _instantPage,
            builder: (context, state) => const HotPage(),
          ),
          GoRoute(
            path: AppRoutes.search,
            pageBuilder: _instantPage,
            builder: (context, state) {
              final tags = state.uri.queryParameters['tags'];
              if (tags == null || tags.isEmpty) return const PostsSearchPage();
              return PostsSearchPage(
                key: ValueKey(tags),
                query: {'tags': tags},
              );
            },
          ),
          GoRoute(
            path: AppRoutes.feeds,
            pageBuilder: _instantPage,
            builder: (context, state) => const FeedsPage(),
          ),
          GoRoute(
            path: AppRoutes.favorites,
            redirect: (context, state) => AppRoutes.profile,
          ),
          GoRoute(
            path: AppRoutes.bookmarks,
            redirect: (context, state) => AppRoutes.home,
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: _instantPage,
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: AppRoutes.pools,
            pageBuilder: _instantPage,
            builder: (context, state) => const PoolsPage(),
          ),
          GoRoute(
            path: AppRoutes.forum,
            pageBuilder: _instantPage,
            builder: (context, state) => const TopicsPage(),
          ),
          GoRoute(
            path: AppRoutes.history,
            pageBuilder: _instantPage,
            builder: (context, state) => const HistoriesPage(),
          ),
          GoRoute(
            path: AppRoutes.finishes,
            pageBuilder: _instantPage,
            builder: (context, state) => const FinishesPage(),
          ),
          GoRoute(
            path: AppRoutes.blacklist,
            pageBuilder: _instantPage,
            builder: (context, state) => const DenyListPage(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: _instantPage,
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: '/post/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return PostLoadingPage(int.parse(id));
            },
          ),
        ],
      ),
    ],
  );
}

CustomTransitionPage<void> _instantPage(
  BuildContext context,
  GoRouterState state,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: _pageForPath(state),
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
  );
}

Widget _pageForPath(GoRouterState state) {
  final path = state.uri.path;
  return switch (path) {
    AppRoutes.home => const HomePage(),
    AppRoutes.hot => const HotPage(),
    AppRoutes.search => () {
      final tags = state.uri.queryParameters['tags'];
      if (tags == null || tags.isEmpty) return const PostsSearchPage();
      return PostsSearchPage(
        key: ValueKey(tags),
        query: {'tags': tags},
      );
    }(),
    AppRoutes.feeds => const FeedsPage(),
    AppRoutes.profile => const ProfilePage(),
    AppRoutes.pools => const PoolsPage(),
    AppRoutes.forum => const TopicsPage(),
    AppRoutes.history => const HistoriesPage(),
    AppRoutes.finishes => const FinishesPage(),
    AppRoutes.blacklist => const DenyListPage(),
    AppRoutes.settings => const SettingsPage(),
    _ => const SizedBox(),
  };
}

int? _intParam(GoRouterState state, String key) {
  final s = state.uri.queryParameters[key];
  if (s == null) return null;
  return int.tryParse(s);
}
