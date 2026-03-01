import 'package:flutter/cupertino.dart';
import '../core/types/navigation_args.dart';
import '../data/models/models.dart';
import '../ui/app_shell.dart';
import '../ui/pages/pages.dart';

/// App route names
class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String main = '/main';
  static const String postDetail = '/post';
  static const String search = '/search';
  static const String profile = '/profile';
  static const String favorites = '/favorites';
  static const String settings = '/settings';
  static const String blacklistSettings = '/settings/blacklist';
  static const String feeds = '/feeds';
  static const String feedEdit = '/feeds/edit';
}

/// App router configuration
class AppRouter {
  AppRouter._();

  /// Generate route based on settings
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return CupertinoPageRoute(
          builder: (_) => const LoginPage(),
          settings: settings,
        );

      case AppRoutes.main:
        return CupertinoPageRoute(
          builder: (_) => const AppShell(),
          settings: settings,
        );

      case AppRoutes.postDetail:
        final args = settings.arguments as PostDetailArguments;
        return CupertinoPageRoute(
          builder: (_) => PostDetailPage(
            postIds: args.postIds,
            initialIndex: args.initialIndex,
            onLoadMore: args.onLoadMore,
            hasMore: args.hasMore,
            postHostUrls: args.postHostUrls,
            initialPosts: args.initialPosts,
          ),
          settings: settings,
        );

      case AppRoutes.search:
        final args = settings.arguments;
        final String? initialQuery;
        final String? feedTitle;
        final List<String>? hostUrls;
        final String? initialRating;
        final String? initialOrder;
        if (args is SearchRouteArguments) {
          initialQuery = args.query;
          feedTitle = args.feedTitle;
          hostUrls = args.hostUrls;
          initialRating = args.initialRating;
          initialOrder = args.initialOrder;
        } else {
          initialQuery = args as String?;
          feedTitle = null;
          hostUrls = null;
          initialRating = null;
          initialOrder = null;
        }
        return CupertinoPageRoute(
          builder: (_) => _SearchRoutePage(
            initialQuery: initialQuery,
            feedTitle: feedTitle,
            hostUrls: hostUrls,
            initialRating: initialRating,
            initialOrder: initialOrder,
          ),
          settings: settings,
        );

      case AppRoutes.profile:
        final profileUsername = settings.arguments as String?;
        return CupertinoPageRoute(
          builder: (_) => _ProfileRoutePage(username: profileUsername),
          settings: settings,
        );

      case AppRoutes.favorites:
        return CupertinoPageRoute(
          builder: (_) => const _FavoritesRoutePage(),
          settings: settings,
        );

      case AppRoutes.settings:
        final initialCategory = settings.arguments as String?;
        return CupertinoPageRoute(
          builder: (ctx) => SafeArea(
            child: UiSettingsPage(
              key: ValueKey('settings-${initialCategory ?? "main"}'),
              onNavigate: (r) => Navigator.of(ctx).pushNamed(r),
              initialCategory: initialCategory,
            ),
          ),
          settings: settings,
        );

      case AppRoutes.blacklistSettings:
        return CupertinoPageRoute(
          builder: (_) => const BlacklistSettingsPage(),
          settings: settings,
        );

      case AppRoutes.feeds:
        return CupertinoPageRoute(
          builder: (_) => const _FeedsRoutePage(),
          settings: settings,
        );

      case AppRoutes.feedEdit:
        final feed = settings.arguments as Feed?;
        return CupertinoPageRoute(
          builder: (_) => FeedEditPage(feed: feed),
          settings: settings,
        );

      default:
        return CupertinoPageRoute(
          builder: (_) => const LoginPage(),
          settings: settings,
        );
    }
  }
}

/// Full-page wrappers for routes pushed from shell (e.g. mobile).
class _SearchRoutePage extends StatelessWidget {
  const _SearchRoutePage({
    this.initialQuery,
    this.feedTitle,
    this.hostUrls,
    this.initialRating,
    this.initialOrder,
  });

  final String? initialQuery;
  final String? feedTitle;
  final List<String>? hostUrls;
  final String? initialRating;
  final String? initialOrder;

  @override
  Widget build(BuildContext context) {
    final isFeedMode = feedTitle != null && feedTitle!.isNotEmpty;

    // No separate nav bar: search page is a widget with its own toolbar. When pushed as route,
    // toolbar gets a back button via onBack so we don't duplicate a top bar that hides the search bar.
    return CupertinoPageScaffold(
      child: SafeArea(
        child: UiSearchPage(
          initialQuery: initialQuery,
          feedMode: isFeedMode,
          feedTitle: feedTitle,
          hostUrls: hostUrls,
          initialRating: initialRating,
          initialOrder: initialOrder,
          onBack: () => Navigator.of(context).pop(),
          onPostTap: (args) => Navigator.of(
            context,
          ).pushNamed(AppRoutes.postDetail, arguments: args),
        ),
      ),
    );
  }
}

class _ProfileRoutePage extends StatelessWidget {
  const _ProfileRoutePage({this.username});

  final String? username;

  @override
  Widget build(BuildContext context) {
    return UiProfilePage(
      username: username,
      onNavigate: (r) => Navigator.of(context).pushNamed(r),
      onPostTap: (args) => Navigator.of(
        context,
      ).pushNamed(AppRoutes.postDetail, arguments: args),
    );
  }
}

class _FavoritesRoutePage extends StatelessWidget {
  const _FavoritesRoutePage();

  @override
  Widget build(BuildContext context) {
    return UiFavoritesPage(
      onPostTap: (args) => Navigator.of(
        context,
      ).pushNamed(AppRoutes.postDetail, arguments: args),
    );
  }
}

class _FeedsRoutePage extends StatelessWidget {
  const _FeedsRoutePage();

  @override
  Widget build(BuildContext context) {
    return UiFeedsPage();
  }
}
