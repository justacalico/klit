import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klit/app/routes/app_routes.dart';
import 'package:klit/app/widget/main_shell.dart';
import 'package:klit/post/post.dart';

GoRouter createAppRouter(GlobalKey<NavigatorState> navigatorKey) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => MainShell(
          initialPath: AppRoutes.home,
          profileUserId: _intParam(state, 'userId'),
          profileUsername: state.uri.queryParameters['username'],
        ),
      ),
      GoRoute(
        path: AppRoutes.hot,
        builder: (context, state) =>
            MainShell(initialPath: AppRoutes.hot),
      ),
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) {
          final tags = state.uri.queryParameters['tags'];
          return MainShell(
            initialPath: AppRoutes.search,
            searchInitialQuery: tags,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.feeds,
        builder: (context, state) =>
            MainShell(initialPath: AppRoutes.feeds),
      ),
      GoRoute(
        path: AppRoutes.favorites,
        builder: (context, state) =>
            MainShell(initialPath: AppRoutes.profile),
      ),
      GoRoute(
        path: AppRoutes.bookmarks,
        builder: (context, state) =>
            MainShell(initialPath: AppRoutes.home),
      ),
      GoRoute(
        path: AppRoutes.pools,
        builder: (context, state) =>
            MainShell(initialPath: AppRoutes.pools),
      ),
      GoRoute(
        path: AppRoutes.forum,
        builder: (context, state) =>
            MainShell(initialPath: AppRoutes.forum),
      ),
      GoRoute(
        path: AppRoutes.history,
        builder: (context, state) =>
            MainShell(initialPath: AppRoutes.history),
      ),
      GoRoute(
        path: AppRoutes.finishes,
        builder: (context, state) =>
            MainShell(initialPath: AppRoutes.finishes),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => MainShell(
          initialPath: AppRoutes.profile,
          profileUserId: _intParam(state, 'userId'),
          profileUsername: state.uri.queryParameters['username'],
        ),
      ),
      GoRoute(
        path: AppRoutes.blacklist,
        builder: (context, state) =>
            MainShell(initialPath: AppRoutes.blacklist),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) =>
            MainShell(initialPath: AppRoutes.settings),
      ),
      GoRoute(
        path: '/post/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PostLoadingPage(int.parse(id));
        },
      ),
    ],
  );
}

int? _intParam(GoRouterState state, String key) {
  final s = state.uri.queryParameters[key];
  if (s == null) return null;
  return int.tryParse(s);
}
