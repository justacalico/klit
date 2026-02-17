import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../core/constants/platform_config.dart';
import '../core/input/input.dart';
import '../core/theme/ui_style_manager.dart';
import '../providers/providers.dart';

import 'breakpoints.dart';
import 'pages/pages.dart';
import 'shell/nav_bar.dart';
import 'shell/sidebar.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with GamepadInputMixin {
  bool _sidebarCollapsed = false;
  bool _showControllerMode = false;
  PostDetailArguments? _postOverlay;
  String? _searchQuery;
  StreamSubscription<GamepadState>? _gamepadStateSub;

  static const List<int> _desktopOrder = [0, 1, 2, 6, 4, 5, 3];

  @override
  void initState() {
    super.initState();
    _showControllerMode = gamepad.isConnected;
    _gamepadStateSub = gamepad.stateChanges.listen((s) {
      if (mounted && s.isConnected != _showControllerMode) {
        setState(() => _showControllerMode = s.isConnected);
      }
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
    } else if (direction == GamepadDirection.down && pos < _desktopOrder.length - 1) {
      _onNav(_desktopOrder[pos + 1]);
      HapticFeedback.selectionClick();
    }
  }

  @override
  void onGamepadButton(GamepadButton button) {
    if (!mounted || _postOverlay != null) return;
    if (button == GamepadButton.start) {
      setState(() => _sidebarCollapsed = !_sidebarCollapsed);
      HapticFeedback.mediumImpact();
    } else if (button == GamepadButton.select) {
      _openSearch();
      HapticFeedback.mediumImpact();
    }
  }

  void _onNav(int index) {
    context.read<NavigationProvider>().setFromDesktopIndex(index);
    setState(() => _searchQuery = null);
  }

  void _openPostOverlay(PostDetailArguments args) {
    setState(() => _postOverlay = args);
  }

  void _closePostOverlay() {
    setState(() => _postOverlay = null);
  }

  void _openSearch([String? query]) {
    context.read<NavigationProvider>().setFromDesktopIndex(4);
    setState(() {
      _searchQuery = query;
      _postOverlay = null;
    });
  }

  void _onPostTap(PostDetailArguments args) {
    if (_isDesktop) {
      _openPostOverlay(args);
    } else {
      Navigator.of(context).pushNamed(AppRoutes.postDetail, arguments: args);
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
                Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
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

  bool get _isDesktop {
    if (PlatformConfig.forceDesktop) return true;
    if (PlatformConfig.forceMobile) return false;
    final width = MediaQuery.sizeOf(context).width;
    return width >= Breakpoints.desktop;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final nav = context.watch<NavigationProvider>();
    final selected = nav.getDesktopIndex();

    return CupertinoPageScaffold(
      child: Container(
        color: isDark ? const Color(0xFF0A0A0C) : const Color(0xFFF8F8FC),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            if (_isDesktop) _buildDesktopLayout(selected, isDark) else _buildMobileLayout(isDark),
            if (_postOverlay != null && _isDesktop) _buildPostOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(int selected, bool isDark) {
    return Row(
      children: [
        AppSidebar(
          selectedIndex: selected,
          onItemSelected: _onNav,
          isCollapsed: _sidebarCollapsed,
          onToggleCollapse: () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
        ),
        Expanded(
          child: RepaintBoundary(
            child: ClipRect(
              child: _buildContent(selected),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(bool isDark) {
    final nav = context.watch<NavigationProvider>();
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();
    final rawOrder = settings.mobileNavOrder;
    final navOrder = auth.isGuest ? rawOrder.where((id) => id != 3).toList() : rawOrder;
    final mobileIdx = nav.getMobileIndex();
    final pos = navOrder.indexOf(mobileIdx);
    final currentIndex = pos >= 0 ? pos : 0;

    final isLiquidGlass = UIStyleManager.isLiquidGlass(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final navBarHeight = isLiquidGlass ? 68 + 16 + bottomPadding : 56 + bottomPadding;

    return PopScope(
      canPop: false,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(bottom: navBarHeight),
              child: RepaintBoundary(
                child: _buildMobilePage(navOrder[currentIndex]),
              ),
            ),
          ),
          AppNavBar(
            navOrder: navOrder,
            currentIndex: currentIndex,
            onTap: (i) {
              final id = navOrder[i];
              nav.setFromMobileIndex(id);
            },
            isGuest: auth.isGuest,
            onLogout: _handleLogout,
          ),
        ],
      ),
    );
  }

  Widget _buildMobilePage(int pageId) {
    switch (pageId) {
      case 0:
        return UiHomePage(onPostTap: _onPostTap, onSearchTap: () => Navigator.of(context).pushNamed(AppRoutes.search));
      case 1:
        return UiHotPage(onPostTap: _onPostTap, onSearchTap: () => Navigator.of(context).pushNamed(AppRoutes.search));
      case 2:
        return UiPopularPage(onPostTap: _onPostTap, onSearchTap: () => Navigator.of(context).pushNamed(AppRoutes.search));
      case 3:
        return const UiProfilePage();
      case 4:
        return UiSettingsPage(onNavigate: (r) => Navigator.of(context).pushNamed(r));
      default:
        return UiHomePage(onPostTap: _onPostTap, onSearchTap: () => Navigator.of(context).pushNamed(AppRoutes.search));
    }
  }

  Widget _buildContent(int selected) {
    switch (selected) {
      case 0:
        return UiHomePage(onPostTap: _onPostTap, onSearchTap: _openSearch);
      case 1:
        return UiHotPage(onPostTap: _onPostTap, onSearchTap: _openSearch);
      case 2:
        return UiPopularPage(onPostTap: _onPostTap, onSearchTap: _openSearch);
      case 3:
        return UiSettingsPage(onNavigate: (r) => Navigator.of(context).pushNamed(r));
      case 4:
        return UiSearchPage(initialQuery: _searchQuery, onPostTap: _onPostTap);
      case 5:
        return UiProfilePage(onNavigate: (r) => Navigator.of(context).pushNamed(r));
      case 6:
        return UiFavoritesPage(onPostTap: _onPostTap);
      default:
        return UiHomePage(onPostTap: _onPostTap, onSearchTap: _openSearch);
    }
  }

  Widget _buildPostOverlay() {
    final args = _postOverlay!;
    return UiPostDetailOverlay(
      key: ValueKey('${args.postIds.hashCode}_${args.initialIndex}'),
      postIds: args.postIds,
      initialIndex: args.initialIndex,
      onSearchTag: _openSearch,
      onClose: _closePostOverlay,
      onLoadMore: args.onLoadMore,
      hasMore: args.hasMore,
    );
  }
}
