import 'package:flutter/cupertino.dart';
import '../presentation/desktop/responsive_layout.dart';
import '../presentation/pages/auth/login_page.dart';
import '../presentation/pages/favorites/responsive_favorites_page.dart';
import '../presentation/pages/post/post_detail_page.dart';
import '../presentation/pages/post/responsive_post_detail_page.dart';
import '../presentation/pages/profile/responsive_profile_page.dart';
import '../presentation/pages/search/responsive_search_page.dart';
import '../presentation/pages/settings/account_management_page.dart';
import '../presentation/pages/settings/host_settings_page.dart';

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
          builder: (_) => const ResponsiveLayout(),
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
          builder: (_) => ResponsiveSearchPage(initialQuery: initialQuery),
          settings: settings,
        );

      case AppRoutes.profile:
        return CupertinoPageRoute(
          builder: (_) => const ResponsiveProfilePage(),
          settings: settings,
        );

      case AppRoutes.favorites:
        return CupertinoPageRoute(
          builder: (_) => const ResponsiveFavoritesPage(),
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

      default:
        return CupertinoPageRoute(
          builder: (_) => const LoginPage(),
          settings: settings,
        );
    }
  }
}
