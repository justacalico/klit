import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../core/input/input.dart';
import '../core/theme/ui_style_manager.dart';
import '../core/types/navigation_args.dart';
import '../providers/providers.dart';

import 'layout/layout_scope.dart';
import 'pages/pages.dart';
import 'shell/nav_bar.dart';
import 'shell/sidebar.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with GamepadInputMixin {
  PostDetailArguments? _postOverlay;
  StreamSubscription<GamepadState>? _gamepadStateSub;
  /// True while the post detail route we pushed from mobile is on the stack.
  bool _postDetailRoutePushed = false;
  /// Previous layout mode to detect desktop <-> mobile transitions.
  LayoutMode? _previousMode;

  static const List<int> _desktopOrder = [0, 1, 2, 6, 4, 5, 3];

  @override
  void initState() {
    super.initState();
    _gamepadStateSub = gamepad.stateChanges.listen((s) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _gamepadStateSub?.cancel();
    super.dispose();
  }

  @override
  void onGamepadDirection(GamepadDirection direction) {
    if (!mounted || _postOverlay != null) return;
    final nav = context.read<NavigationProvider>();
    final idx = nav.getDesktopIndex();
    final pos = _desktopOrder.indexOf(idx);
    if (direction == GamepadDirection.up && pos > 0) {
      _onNav(_desktopOrder[pos - 1]);
      HapticFeedback.selectionClick();
    } else if (direction == GamepadDirection.down &&
        pos < _desktopOrder.length - 1) {
      _onNav(_desktopOrder[pos + 1]);
      HapticFeedback.selectionClick();
    }
  }

  @override
  void onGamepadButton(GamepadButton button) {
    if (!mounted || _postOverlay != null) return;
    if (button == GamepadButton.start) {
      context.read<NavigationProvider>().toggleSidebar();
      HapticFeedback.mediumImpact();
    } else if (button == GamepadButton.select) {
      _openSearch();
      HapticFeedback.mediumImpact();
    }
  }

  void _onNav(int index) {
    final nav = context.read<NavigationProvider>();
    nav.setFromDesktopIndex(index);
    nav.clearSearch();
  }

  void _openPostOverlay(PostDetailArguments args) {
    setState(() => _postOverlay = args);
  }

  void _closePostOverlay() {
    setState(() => _postOverlay = null);
  }

  void _openSearch([String? query]) {
    final nav = context.read<NavigationProvider>();
    nav.openSearch(query);
    setState(() => _postOverlay = null);
  }

  void _onPostTap(PostDetailArguments args) {
    if (LayoutScope.of(context).isDesktop) {
      _openPostOverlay(args);
    } else {
      setState(() => _postOverlay = args);
      Navigator.of(context).push(
        CupertinoPageRoute(
          settings: RouteSettings(
            name: AppRoutes.postDetail,
            arguments: args,
          ),
          builder: (ctx) => PostDetailPage(
            postIds: args.postIds,
            initialIndex: args.initialIndex,
            onLoadMore: args.onLoadMore,
            hasMore: args.hasMore,
            onCurrentIndexChanged: (index) {
              if (!mounted) return;
              setState(() {
                _postOverlay = PostDetailArguments(
                  postIds: _postOverlay!.postIds,
                  initialIndex: index,
                  onLoadMore: _postOverlay!.onLoadMore,
                  hasMore: _postOverlay!.hasMore,
                );
              });
            },
            onClose: () => Navigator.of(context).pop(),
          ),
        ),
      ).then((_) {
        if (mounted) {
          setState(() {
            _postDetailRoutePushed = false;
            _postOverlay = null;
          });
        }
      });
      setState(() => _postDetailRoutePushed = true);
    }
  }

  void _handleLogout() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of guest mode?'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(ctx).pop();
              await context.read<AuthProvider>().logout();
              if (mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
              }
            },
            child: const Text('Sign Out'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final mode = LayoutScope.of(context);
    final nav = context.watch<NavigationProvider>();
    final selected = nav.getDesktopIndex();

    // When switching desktop -> mobile with overlay open, push post detail so user keeps viewing the same post.
    if (_previousMode != null &&
        _previousMode!.isDesktop &&
        mode.isMobile &&
        _postOverlay != null &&
        !_postDetailRoutePushed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final overlay = _postOverlay;
        if (overlay == null) return;
        setState(() => _postDetailRoutePushed = true);
        Navigator.of(context).push(
          CupertinoPageRoute(
            settings: RouteSettings(
              name: AppRoutes.postDetail,
              arguments: overlay,
            ),
            builder: (ctx) => PostDetailPage(
              postIds: overlay.postIds,
              initialIndex: overlay.initialIndex,
              onLoadMore: overlay.onLoadMore,
              hasMore: overlay.hasMore,
              onCurrentIndexChanged: (index) {
                if (!mounted) return;
                setState(() {
                  _postOverlay = PostDetailArguments(
                    postIds: _postOverlay!.postIds,
                    initialIndex: index,
                    onLoadMore: _postOverlay!.onLoadMore,
                    hasMore: _postOverlay!.hasMore,
                  );
                });
              },
              onClose: () => Navigator.of(context).pop(),
            ),
          ),
        ).then((_) {
          if (mounted) {
            setState(() {
              _postDetailRoutePushed = false;
              _postOverlay = null;
            });
          }
        });
      });
    }
    // When switching mobile -> desktop with post detail route on stack, pop so overlay can show (same post).
    if (_previousMode != null &&
        _previousMode!.isMobile &&
        mode.isDesktop &&
        _postDetailRoutePushed &&
        _postOverlay != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          setState(() => _postDetailRoutePushed = false);
        }
      });
    }
    _previousMode = mode;

    final content = KeyedSubtree(
      key: ValueKey('shell-content-$selected'),
      child: RepaintBoundary(child: ClipRect(child: _buildContent(selected))),
    );

    final navBarHeight = _getMobileNavBarHeight(context);
    final sidebarWidth = nav.sidebarCollapsed ? 72.0 : 240.0;

    return CupertinoPageScaffold(
      child: Container(
        color: isDark ? const Color(0xFF0A0A0C) : const Color(0xFFF8F8FC),
        child: PopScope(
          canPop: false,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: mode.isDesktop ? sidebarWidth : 0,
                top: 0,
                right: 0,
                bottom: mode.isDesktop ? 0 : navBarHeight,
                child: content,
              ),
              if (mode.isDesktop)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Material(
                    type: MaterialType.transparency,
                    elevation: 12,
                    child: AppSidebar(
                      selectedIndex: selected,
                      onItemSelected: _onNav,
                      isCollapsed: nav.sidebarCollapsed,
                      onToggleCollapse: nav.toggleSidebar,
                    ),
                  ),
                ),
              if (!mode.isDesktop)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ColoredBox(
                    color: isDark
                        ? const Color(0xFF0A0A0C)
                        : const Color(0xFFF8F8FC),
                    child: SizedBox(
                      height: navBarHeight,
                      child: Material(
                        type: MaterialType.transparency,
                        elevation: 12,
                        child: _buildMobileNavBarContent(isDark),
                      ),
                    ),
                  ),
                ),
              if (_postOverlay != null && mode.isDesktop)
                Material(
                  type: MaterialType.transparency,
                  elevation: 16,
                  child: _buildPostOverlay(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  double _getMobileNavBarHeight(BuildContext context) {
    final isLiquidGlass = UIStyleManager.isLiquidGlass(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return isLiquidGlass ? 68 + 16 + bottomPadding : 56 + bottomPadding;
  }

  Widget _buildMobileNavBarContent(bool isDark) {
    final nav = context.watch<NavigationProvider>();
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();
    final rawOrder = settings.mobileNavOrder;
    final navOrder = auth.isGuest
        ? rawOrder.where((id) => id != 3).toList()
        : rawOrder;
    final mobileIdx = nav.getMobileIndex();
    final pos = navOrder.indexOf(mobileIdx);
    final currentIndex = pos >= 0 ? pos : 0;

    return AppNavBar(
      navOrder: navOrder,
      currentIndex: currentIndex,
      onTap: (i) {
        final id = navOrder[i];
        nav.setFromMobileIndex(id);
      },
      isGuest: auth.isGuest,
      onLogout: _handleLogout,
    );
  }

  Widget _buildContent(int selected) {
    final nav = context.watch<NavigationProvider>();
    switch (selected) {
      case 0:
        return UiHomePage(onPostTap: _onPostTap, onSearchTap: _openSearch);
      case 1:
        return UiHotPage(onPostTap: _onPostTap, onSearchTap: _openSearch);
      case 2:
        return UiPopularPage(onPostTap: _onPostTap, onSearchTap: _openSearch);
      case 3:
        return UiSettingsPage(
          onNavigate: (r) => Navigator.of(context).pushNamed(r),
        );
      case 4:
        return UiSearchPage(
          initialQuery: nav.searchQuery,
          onPostTap: _onPostTap,
        );
      case 5:
        return UiProfilePage(
          onNavigate: (r) => Navigator.of(context).pushNamed(r),
        );
      case 6:
        return UiFavoritesPage(onPostTap: _onPostTap);
      default:
        return UiHomePage(onPostTap: _onPostTap, onSearchTap: _openSearch);
    }
  }

  void _onOverlayCurrentIndexChanged(int index) {
    if (_postOverlay == null) return;
    setState(() {
      _postOverlay = PostDetailArguments(
        postIds: _postOverlay!.postIds,
        initialIndex: index,
        onLoadMore: _postOverlay!.onLoadMore,
        hasMore: _postOverlay!.hasMore,
      );
    });
  }

  Widget _buildPostOverlay() {
    final args = _postOverlay!;
    return UiPostDetailOverlay(
      key: ValueKey('overlay-${args.postIds.hashCode}'),
      postIds: args.postIds,
      initialIndex: args.initialIndex,
      onSearchTag: _openSearch,
      onCurrentIndexChanged: _onOverlayCurrentIndexChanged,
      onClose: _closePostOverlay,
      onLoadMore: args.onLoadMore,
      hasMore: args.hasMore,
    );
  }
}
