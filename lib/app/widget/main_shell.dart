import 'package:kilt/app/routing/app_routes.dart';
import 'package:kilt/client/client.dart';
import 'package:kilt/post/post.dart';
import 'package:kilt/settings/settings.dart';
import 'package:kilt/shared/shared.dart';
import 'package:kilt/traits/traits.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({
    super.key,
    required this.location,
    required this.child,
    this.profileUserId,
    this.profileUsername,
  });

  final String location;
  final Widget child;
  final int? profileUserId;
  final String? profileUsername;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  bool _queuedFinishesRedirect = false;
  bool _syncQueued = false;

  @override
  void initState() {
    super.initState();
    _queueSyncFromRoute();
  }

  @override
  void didUpdateWidget(MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location ||
        oldWidget.profileUserId != widget.profileUserId ||
        oldWidget.profileUsername != widget.profileUsername) {
      _queueSyncFromRoute();
    }
  }

  void _queueSyncFromRoute() {
    if (_syncQueued) return;
    _syncQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncQueued = false;
      _syncFromRoute();
    });
  }

  void _syncFromRoute() {
    final settings = context.read<Settings>();
    if (widget.location == AppRoutes.finishes &&
        !settings.iFinishedEnabled.value) {
      ref.read(navigationProvider.notifier).setPath(AppRoutes.home);
      if (!_queuedFinishesRedirect) {
        _queuedFinishesRedirect = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.go(AppRoutes.home);
        });
      }
      return;
    }

    _queuedFinishesRedirect = false;
    ref.read(navigationProvider.notifier).setPath(
          widget.location,
          profileUserId: widget.profileUserId,
          profileUsername: widget.profileUsername,
        );
  }

  @override
  Widget build(BuildContext context) {
    final client = context.watch<Client>();
    final settings = context.read<Settings>();
    final showFavorites = client.hasLogin;
    return ValueListenableBuilder<Traits>(
      valueListenable: client.traits,
      builder: (context, traits, child) {
        final showHistory = traits.writeHistory ?? false;
        return ValueListenableBuilder<bool>(
          valueListenable: settings.iFinishedEnabled,
          builder: (context, showFinishes, _) {
            if (showFinishes || widget.location != AppRoutes.finishes) {
              _queuedFinishesRedirect = false;
            }
            if (!showFinishes &&
                widget.location == AppRoutes.finishes &&
                !_queuedFinishesRedirect) {
              _queuedFinishesRedirect = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                ref.read(navigationProvider.notifier).setPath(AppRoutes.home);
                context.go(AppRoutes.home);
              });
            }
            return AppShell(
              body: !showFinishes && widget.location == AppRoutes.finishes
                  ? const HomePage()
                  : widget.child,
              showFavorites: showFavorites,
              showHistory: showHistory,
              showFinishes: showFinishes,
            );
          },
        );
      },
    );
  }
}
