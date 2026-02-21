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
  static const String accountManagement = '/settings/accounts';
  static const String hostSettings = '/settings/host';
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
          ),
          settings: settings,
        );

      case AppRoutes.search:
        final initialQuery = settings.arguments as String?;
        return CupertinoPageRoute(
          builder: (_) => _SearchRoutePage(initialQuery: initialQuery),
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

      case AppRoutes.accountManagement:
        return CupertinoPageRoute(
          builder: (_) => const AccountManagementPage(),
          settings: settings,
        );

      case AppRoutes.hostSettings:
        return CupertinoPageRoute(
          builder: (_) => const HostSettingsPage(),
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
  final String? initialQuery;

  const _SearchRoutePage({this.initialQuery});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.back),
        ),
        middle: Text(
          initialQuery != null && initialQuery!.isNotEmpty
              ? initialQuery!
              : 'Search',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      child: SafeArea(
        top: false,
        child: UiSearchPage(
          initialQuery: initialQuery,
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
