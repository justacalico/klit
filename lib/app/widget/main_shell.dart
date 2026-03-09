import 'package:klit/app/routes/app_routes.dart';
import 'package:klit/client/client.dart';
import 'package:klit/feed/feed.dart';
import 'package:klit/finish/finish.dart';
import 'package:klit/history/history.dart';
import 'package:klit/pool/pool.dart';
import 'package:klit/post/post.dart';
import 'package:klit/settings/settings.dart';
import 'package:klit/shared/shared.dart';
import 'package:klit/topic/topic.dart';
import 'package:klit/user/user.dart';
import 'package:klit/traits/traits.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({
    super.key,
    this.initialPath,
    this.profileUserId,
    this.profileUsername,
    this.searchInitialQuery,
  });

  final String? initialPath;
  final int? profileUserId;
  final String? profileUsername;
  final String? searchInitialQuery;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFromRoute());
  }

  @override
  void didUpdateWidget(MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPath != widget.initialPath ||
        oldWidget.profileUserId != widget.profileUserId ||
        oldWidget.profileUsername != widget.profileUsername ||
        oldWidget.searchInitialQuery != widget.searchInitialQuery) {
      _syncFromRoute();
    }
  }

  void _syncFromRoute() {
    final path = widget.initialPath ?? AppRoutes.home;
    ref.read(navigationProvider.notifier).setPath(
          path,
          profileUserId: widget.profileUserId,
          profileUsername: widget.profileUsername,
        );
    if (widget.searchInitialQuery != null) {
      ref.read(navigationProvider.notifier).setSearchInitialQuery(widget.searchInitialQuery);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nav = ref.watch(navigationProvider);
    final client = context.watch<Client>();
    final settings = context.read<Settings>();
    final showFavorites = client.hasLogin;
    return ValueListenableBuilder<Traits>(
      valueListenable: client.traits,
      builder: (context, traits, child) {
        final showHistory = traits.writeHistory ?? false;
        return ValueListenableBuilder<bool>(
          valueListenable: settings.iFinishedEnabled,
          builder: (context, showFinishes, child) {
            final path = nav.currentPath;
            return AppShell(
              body: _buildContent(path, settings),
              showFavorites: showFavorites,
              showHistory: showHistory,
              showFinishes: showFinishes,
            );
          },
        );
      },
    );
  }

  Widget _buildContent(String path, Settings settings) {
    if (path == AppRoutes.finishes && !settings.iFinishedEnabled.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(AppRoutes.home);
      });
      return const HomePage();
    }
    switch (path) {
      case AppRoutes.home:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(navigationProvider.notifier).clearSearchInitialQuery();
        });
        return const HomePage();
      case AppRoutes.hot:
        return const HotPage();
      case AppRoutes.search:
        final initialTags = ref.read(navigationProvider).searchInitialQuery;
        if (initialTags != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(navigationProvider.notifier).clearSearchInitialQuery();
          });
          return PostsSearchPage(
            key: ValueKey(initialTags),
            query: {'tags': initialTags},
          );
        }
        return const PostsSearchPage();
      case AppRoutes.feeds:
        return const FeedsPage();
      case AppRoutes.pools:
        return const PoolsPage();
      case AppRoutes.forum:
        return const TopicsPage();
      case AppRoutes.history:
        return const HistoriesPage();
      case AppRoutes.finishes:
        return const FinishesPage();
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
