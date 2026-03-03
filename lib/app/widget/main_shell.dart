import 'package:klit/app/routes/app_routes.dart';
import 'package:klit/client/client.dart';
import 'package:klit/feed/feed.dart';
import 'package:klit/follow/follow.dart';
import 'package:klit/history/history.dart';
import 'package:klit/pool/pool.dart';
import 'package:klit/post/post.dart';
import 'package:klit/settings/settings.dart';
import 'package:klit/shared/shared.dart';
import 'package:klit/topic/topic.dart';
import 'package:klit/user/user.dart';
import 'package:klit/traits/traits.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialPath});

  final String? initialPath;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  @override
  void initState() {
    super.initState();
    final nav = Get.find<NavigationController>();
    final args = Get.arguments as Map<String, dynamic>?;
    if (args?['path'] != null) {
      nav.currentPath.value = args!['path'] as String;
      if (nav.currentPath.value == AppRoutes.profile) {
        if (args['userId'] != null) {
          nav.profileViewUserId.value = args['userId'] as int;
        }
        if (args['username'] != null) {
          nav.profileViewUsername.value = args['username'] as String;
        }
      }
    } else if (widget.initialPath != null) {
      nav.currentPath.value = widget.initialPath!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nav = Get.find<NavigationController>();
    final client = context.watch<Client>();
    final showFavorites = client.hasLogin;
    return ValueListenableBuilder<Traits>(
      valueListenable: client.traits,
      builder: (context, traits, child) {
        final showHistory = traits.writeHistory ?? false;
        return Obx(
          () => AppShell(
            body: _buildContent(nav.currentPath.value),
            showFavorites: showFavorites,
            showHistory: showHistory,
          ),
        );
      },
    );
  }

  Widget _buildContent(String path) {
    switch (path) {
      case AppRoutes.home:
        Get.find<NavigationController>().searchInitialQuery.value = null;
        return const HomePage();
      case AppRoutes.hot:
        return const HotPage();
      case AppRoutes.search:
        final nav = Get.find<NavigationController>();
        final initialTags = nav.searchInitialQuery.value;
        if (initialTags != null) {
          nav.searchInitialQuery.value = null;
          return PostsSearchPage(query: {'tags': initialTags});
        }
        return const PostsSearchPage();
      case AppRoutes.feeds:
        return const FeedsPage();
      case AppRoutes.timeline:
        return const FollowsTimelinePage();
      case AppRoutes.subscriptions:
        return const FollowsSubscriptionsPage();
      case AppRoutes.pools:
        return const PoolsPage();
      case AppRoutes.forum:
        return const TopicsPage();
      case AppRoutes.history:
        return const HistoriesPage();
      case AppRoutes.profile:
        return const ProfilePage();
      case AppRoutes.blacklist:
        return const DenyListPage();
      case AppRoutes.settings:
        return const SettingsPage();
      default:
        return const HomePage();
    }
  }
}
