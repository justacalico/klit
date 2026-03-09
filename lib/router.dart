import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klit/app/routes/app_routes.dart';
import 'package:klit/app/widget/main_shell.dart';
import 'package:klit/post/post.dart';

const _simpleShellPaths = [
  AppRoutes.hot,
  AppRoutes.feeds,
  AppRoutes.pools,
  AppRoutes.forum,
  AppRoutes.history,
  AppRoutes.finishes,
  AppRoutes.blacklist,
  AppRoutes.settings,
];

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
        path: AppRoutes.profile,
        builder: (context, state) => MainShell(
          initialPath: AppRoutes.profile,
          profileUserId: _intParam(state, 'userId'),
          profileUsername: state.uri.queryParameters['username'],
        ),
      ),
      ..._simpleShellPaths.map(
        (path) => GoRoute(
          path: path,
          builder: (context, state) => MainShell(initialPath: path),
        ),
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
