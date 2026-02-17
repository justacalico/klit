import 'package:flutter/cupertino.dart';
import '../presentation/pages/auth/login_page.dart';
import '../presentation/pages/post/post_detail_page.dart';
import '../presentation/pages/post/responsive_post_detail_page.dart';
import '../presentation/pages/settings/account_management_page.dart';
import '../presentation/pages/settings/blacklist_settings_page.dart';
import '../presentation/pages/settings/host_settings_page.dart';
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
          builder: (_) => ResponsivePostDetailPage(
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
        return CupertinoPageRoute(
          builder: (_) => const _ProfileRoutePage(),
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
      child: SafeArea(
        child: UiSearchPage(
          initialQuery: initialQuery,
          onPostTap: (args) => Navigator.of(context).pushNamed(
            AppRoutes.postDetail,
            arguments: args,
          ),
        ),
      ),
    );
  }
}

class _ProfileRoutePage extends StatelessWidget {
  const _ProfileRoutePage();

  @override
  Widget build(BuildContext context) {
    return UiProfilePage(
      onNavigate: (r) => Navigator.of(context).pushNamed(r),
    );
  }
}

class _FavoritesRoutePage extends StatelessWidget {
  const _FavoritesRoutePage();

  @override
  Widget build(BuildContext context) {
    return UiFavoritesPage(
      onPostTap: (args) => Navigator.of(context).pushNamed(
        AppRoutes.postDetail,
        arguments: args,
      ),
    );
  }
}
