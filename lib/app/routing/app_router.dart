import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kilt/app/pages/blacklist_page.dart';
import 'package:kilt/app/pages/feeds_page.dart';
import 'package:kilt/app/pages/finishes_page.dart';
import 'package:kilt/app/pages/history_page.dart';
import 'package:kilt/app/pages/home_page.dart';
import 'package:kilt/app/pages/hot_page.dart';
import 'package:kilt/app/pages/pools_page.dart';
import 'package:kilt/app/pages/profile_page.dart';
import 'package:kilt/app/pages/search_page.dart';
import 'package:kilt/app/pages/settings_page.dart';
import 'package:kilt/app/pages/post/post_loading_page.dart';
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
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: AppRoutes.hot,
            builder: (context, state) => const HotPage(),
          ),
          GoRoute(
            path: AppRoutes.search,
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
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: AppRoutes.pools,
            builder: (context, state) => const PoolsPage(),
          ),
          GoRoute(
            path: AppRoutes.forum,
            builder: (context, state) => const TopicsPage(),
          ),
          GoRoute(
            path: AppRoutes.history,
            builder: (context, state) => const HistoriesPage(),
          ),
          GoRoute(
            path: AppRoutes.finishes,
            builder: (context, state) => const FinishesPage(),
          ),
          GoRoute(
            path: AppRoutes.blacklist,
            builder: (context, state) => const DenyListPage(),
          ),
          GoRoute(
            path: AppRoutes.settings,
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

int? _intParam(GoRouterState state, String key) {
  final s = state.uri.queryParameters[key];
  if (s == null) return null;
  return int.tryParse(s);
}
