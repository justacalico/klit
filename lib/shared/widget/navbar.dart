import 'package:go_router/go_router.dart';
import 'package:kilt/app/routing/app_routes.dart';
import 'package:kilt/shared/controller/navigation_controller.dart';
import 'package:kilt/shared/data/provider.dart';
import 'package:kilt/shared/widget/glass.dart';
import 'package:kilt/settings/widget/icon.dart';
import 'package:kilt/identity/identity.dart';
import 'package:kilt/user/user.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const double mobileBreakpoint = 600;
const double compactBreakpoint = 900;
const double sidebarAutoCollapseBreakpoint = 800;
const String _historyPath = '/history';
const String _profilePath = '/profile';

enum NavbarPlacement { top, bottom, sidebar }

class _NavAdapter {
  _NavAdapter(this._ref, this._context);

  final WidgetRef _ref;
  final BuildContext _context;

  NavigationState get state => _ref.watch(navigationProvider);
  List<NavItem> get items => state.items;
  int get mobilePrimaryCount => state.mobilePrimaryCount;
  int get currentIndex => state.currentIndex;
  bool get sidebarCollapsed => state.sidebarCollapsed;

  void goTo(int index) {
    final path = _ref.read(navigationProvider.notifier).goTo(index);
    _context.go(path);
  }

  void toggleSidebar() => _ref.read(navigationProvider.notifier).toggleSidebar();
  void setSidebarCollapsed(bool v) =>
      _ref.read(navigationProvider.notifier).setSidebarCollapsed(v);
}

class ResponsiveNavbar extends ConsumerWidget {
  const ResponsiveNavbar({
    super.key,
    required this.placement,
    this.showFavorites = true,
    this.showHistory = true,
    this.showFinishes = true,
    this.layoutWidth,
  });

  final NavbarPlacement placement;
  final bool showFavorites;
  final bool showHistory;
  final bool showFinishes;
  final double? layoutWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = _NavAdapter(ref, context);
    if (placement == NavbarPlacement.bottom) {
      return _BottomNavBar(
        controller: nav,
        showFavorites: showFavorites,
        showHistory: showHistory,
        showFinishes: showFinishes,
      );
    }
    if (placement == NavbarPlacement.sidebar) {
      return _Sidebar(
        controller: nav,
        showFavorites: showFavorites,
        showHistory: showHistory,
        showFinishes: showFinishes,
        layoutWidth: layoutWidth,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        if (w < compactBreakpoint) {
          return _CompactNavBar(
            controller: nav,
            showFavorites: showFavorites,
            showHistory: showHistory,
            showFinishes: showFinishes,
          );
        }
        return _FullNavBar(
          controller: nav,
          showFavorites: showFavorites,
          showHistory: showHistory,
          showFinishes: showFinishes,
        );
      },
    );
  }
}

List<({int index, NavItem item})> _visibleNavEntries(
  List<NavItem> items,
  bool showFavorites,
  bool showHistory,
  bool showFinishes,
) {
  return items
      .asMap()
      .entries
      .where((e) {
        if (e.value.path == _historyPath && !showHistory) return false;
        if (e.value.path == _profilePath && !showFavorites) return false;
        if (e.value.path == AppRoutes.finishes && !showFinishes) return false;
        return true;
      })
      .map((e) => (index: e.key, item: e.value))
      .toList();
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.controller,
    required this.showFavorites,
    required this.showHistory,
    required this.showFinishes,
  });

  final _NavAdapter controller;
  final bool showFavorites;
  final bool showHistory;
  final bool showFinishes;

  @override
  Widget build(BuildContext context) {
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final bottomOffset = viewPadding.bottom > 0 ? viewPadding.bottom + 8 : 12.0;
    final visible = _visibleNavEntries(
        controller.items,
        showFavorites,
        showHistory,
        showFinishes,
      );
      final primaryCount = controller.mobilePrimaryCount.clamp(
        0,
        visible.length,
      );
      final primaryVisible = visible.take(primaryCount).toList();
      final moreVisible = visible.skip(primaryCount).toList();
      final selectedVisibleIndex = visible
          .indexWhere((e) => e.index == controller.currentIndex)
          .clamp(0, visible.isEmpty ? 0 : visible.length - 1);
      final isOnPrimary = selectedVisibleIndex < primaryCount;
      final selectedIndex = isOnPrimary ? selectedVisibleIndex : primaryCount;

      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      final isDark = theme.brightness == Brightness.dark;
      final barBg = isDark
          ? theme.canvasColor
          : colorScheme.surfaceContainerHigh;
      final barBgTranslucent = barBg.withValues(alpha: 0.55);

      final destinationCount =
          primaryVisible.length + (moreVisible.isNotEmpty ? 1 : 0);
      return GlassSurface(
        margin: EdgeInsets.fromLTRB(16, 0, 16, bottomOffset),
        borderRadius: 28,
        padding: EdgeInsets.zero,
        color: barBgTranslucent,
        child: SafeArea(
          top: false,
          bottom: false,
          child: _AnimatedBottomNavBar(
            selectedIndex: selectedIndex,
            destinationCount: destinationCount,
            barBg: barBg,
            child: Row(
              children: [
                for (var i = 0; i < primaryVisible.length; i++)
                  Expanded(
                    child: _BottomNavDestination(
                      icon: primaryVisible[i].item.icon,
                      label: primaryVisible[i].item.label,
                      selected: selectedIndex == i,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        controller.goTo(primaryVisible[i].index);
                      },
                    ),
                  ),
                if (moreVisible.isNotEmpty)
                  Expanded(
                    child: _BottomNavDestination(
                      icon: CupertinoIcons.ellipsis,
                      label: 'More',
                      selected: selectedIndex == primaryCount,
                        onTap: () {
                        HapticFeedback.selectionClick();
                        _showMoreMenu(context, moreVisible, controller);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
  }
}

class _AnimatedBottomNavBar extends StatefulWidget {
  const _AnimatedBottomNavBar({
    required this.selectedIndex,
    required this.destinationCount,
    required this.barBg,
    required this.child,
  });

  final int selectedIndex;
  final int destinationCount;
  final Color barBg;
  final Widget child;

  @override
  State<_AnimatedBottomNavBar> createState() => _AnimatedBottomNavBarState();
}

class _AnimatedBottomNavBarState extends State<_AnimatedBottomNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.selectedIndex.toDouble();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 220),
      vsync: this,
    );
    _animation =
        Tween<double>(
          begin: _currentIndex,
          end: widget.selectedIndex.toDouble(),
        ).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
        );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _currentIndex = widget.selectedIndex.toDouble());
      }
    });
  }

  @override
  void didUpdateWidget(_AnimatedBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _controller.stop();
      _controller.reset();
      _animation =
          Tween<double>(
            begin: _currentIndex,
            end: widget.selectedIndex.toDouble(),
          ).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
          );
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final count = widget.destinationCount;
        if (count <= 0) return widget.child;
        final itemWidth = width / count;
        const padding = 8.0;
        final pillWidth = itemWidth - padding * 2;

        return Stack(
          alignment: Alignment.centerLeft,
          children: [
            AnimatedBuilder(
              animation: _animation,
              builder: (context, _) {
                final value = _animation.value;
                return Positioned(
                  left: value * itemWidth + padding,
                  top: 6,
                  bottom: 6,
                  width: pillWidth,
                  child: Material(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(12),
                    clipBehavior: Clip.antiAlias,
                    child: const SizedBox.expand(),
                  ),
                );
              },
            ),
            widget.child,
          ],
        );
      },
    );
  }
}

class _BottomNavDestination extends StatelessWidget {
  const _BottomNavDestination({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = selected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      minimumSize: Size.zero,
      onPressed: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

void _showMoreMenu(
  BuildContext context,
  List<({int index, NavItem item})> entries,
  _NavAdapter nav,
) {
  final theme = Theme.of(context);
  final cupertinoTheme = CupertinoTheme.of(context);

  showCupertinoModalPopup<void>(
    context: context,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: SafeArea(
        top: false,
        child: GlassSurface(
          borderRadius: 20,
          blurSigma: 20,
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              ...entries.map((e) {
                final selected = nav.state.currentIndex == e.index;
                return CupertinoListTile(
                  leading: Icon(
                    e.item.icon,
                    color: selected
                        ? cupertinoTheme.primaryColor
                        : CupertinoColors.label.resolveFrom(context),
                  ),
                  title: Text(
                    e.item.label,
                    style: TextStyle(
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: selected ? cupertinoTheme.primaryColor : null,
                    ),
                  ),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).pop();
                    nav.goTo(e.index);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    ),
  );
}

const double _sidebarExpandedWidth = 240;
const double _sidebarCollapsedWidth = 72;
const Duration _sidebarAnimationDuration = Duration(milliseconds: 200);

class _Sidebar extends StatefulWidget {
  const _Sidebar({
    required this.controller,
    required this.showFavorites,
    required this.showHistory,
    required this.showFinishes,
    this.layoutWidth,
  });

  final _NavAdapter controller;
  final bool showFavorites;
  final bool showHistory;
  final bool showFinishes;
  final double? layoutWidth;

  @override
  State<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<_Sidebar> {
  double? _lastLayoutWidth;

  @override
  void initState() {
    super.initState();
    _lastLayoutWidth = widget.layoutWidth;
  }

  bool _isAutoCollapseWidth(double width) {
    return width < sidebarAutoCollapseBreakpoint && width >= mobileBreakpoint;
  }

  @override
  void didUpdateWidget(covariant _Sidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previousWidth = _lastLayoutWidth ?? oldWidget.layoutWidth;
    final newWidth = widget.layoutWidth;

    if (previousWidth != null &&
        newWidth != null &&
        previousWidth != newWidth) {
      final wasNarrow = previousWidth < sidebarAutoCollapseBreakpoint;
      final isNarrow = _isAutoCollapseWidth(newWidth);

      if (newWidth >= sidebarAutoCollapseBreakpoint && wasNarrow) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          widget.controller.setSidebarCollapsed(false);
        });
      } else if (!wasNarrow && isNarrow) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          widget.controller.setSidebarCollapsed(true);
        });
      }
    }

    final transitioningToWide =
        newWidth != null &&
        previousWidth != null &&
        previousWidth < sidebarAutoCollapseBreakpoint &&
        newWidth >= sidebarAutoCollapseBreakpoint;
    if (!transitioningToWide) {
      _lastLayoutWidth = newWidth;
    }
  }

  @override
  Widget build(BuildContext context) {
    final layoutWidth = widget.layoutWidth;
    if (layoutWidth != null &&
        layoutWidth >= sidebarAutoCollapseBreakpoint &&
        _lastLayoutWidth != null &&
        _lastLayoutWidth! < sidebarAutoCollapseBreakpoint) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.controller.setSidebarCollapsed(false);
        setState(() => _lastLayoutWidth = layoutWidth);
      });
    }

    final controllerCollapsed = widget.controller.sidebarCollapsed;
      final forceCollapsed =
          layoutWidth != null &&
          layoutWidth < sidebarAutoCollapseBreakpoint &&
          layoutWidth >= mobileBreakpoint;
      final collapsed = forceCollapsed || controllerCollapsed;
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      final sidebarBg = theme.canvasColor;
      final width = collapsed ? _sidebarCollapsedWidth : _sidebarExpandedWidth;
    final visible = _visibleNavEntries(
      widget.controller.items,
        widget.showFavorites,
        widget.showHistory,
        widget.showFinishes,
      ).where((e) => e.item.path != '/settings').toList();

      return Material(
        color: sidebarBg,
        child: SafeArea(
          right: false,
          child: AnimatedContainer(
            duration: _sidebarAnimationDuration,
            curve: Curves.easeInOut,
            width: width,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Material(
                      color: theme.brightness == Brightness.dark
                          ? Color.lerp(theme.canvasColor, Colors.white, 0.06)!
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: collapsed
                            ? () {
                                HapticFeedback.selectionClick();
                                widget.controller.toggleSidebar();
                              }
                            : null,
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          child: collapsed
                              ? Center(child: AppIcon(radius: 11))
                              : Row(
                                  children: [
                                    AppIcon(radius: 11),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        'Klit',
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.onSurface,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                Flexible(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    children: [
                      for (final e in visible)
                        _SidebarTile(
                          item: e.item,
                          selected: widget.controller.currentIndex == e.index,
                          onTap: () => widget.controller.goTo(e.index),
                          collapsed: collapsed,
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (collapsed) const _SidebarActiveAccountAvatar(),
                      for (var i = 0; i < widget.controller.items.length; i++)
                        if (widget.controller.items[i].path == '/settings')
                          _SidebarTile(
                            item: widget.controller.items[i],
                            selected: i == widget.controller.currentIndex,
                            onTap: () => widget.controller.goTo(i),
                            collapsed: collapsed,
                          ),
                      const SizedBox(height: 4),
                      _SidebarCollapseButton(
                        controller: widget.controller,
                        effectiveCollapsed: collapsed,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}

class _SidebarActiveAccountAvatar extends StatelessWidget {
  const _SidebarActiveAccountAvatar();

  @override
  Widget build(BuildContext context) {
    final identity = context.watch<IdentityClient>().identity;
    if (identity.username == null) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Tooltip(
        message: identity.username!,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: IdentityAvatar(identity.id, radius: 14),
        ),
      ),
    );
  }
}

class _SidebarCollapseButton extends StatelessWidget {
  const _SidebarCollapseButton({
    required this.controller,
    required this.effectiveCollapsed,
  });

  final _NavAdapter controller;
  final bool effectiveCollapsed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Tooltip(
      message: effectiveCollapsed ? 'Expand sidebar' : 'Shrink sidebar',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              controller.toggleSidebar();
            },
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    effectiveCollapsed
                        ? Icons.keyboard_double_arrow_right
                        : Icons.keyboard_double_arrow_left,
                    size: 22,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  if (!effectiveCollapsed) ...[
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Shrink sidebar',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.collapsed,
  });

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final surfaceElevated = theme.brightness == Brightness.dark
        ? Color.lerp(theme.canvasColor, Colors.white, 0.06)!
        : colorScheme.surfaceContainerHighest;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: _sidebarAnimationDuration,
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: selected ? surfaceElevated : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            minimumSize: Size.zero,
            onPressed: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 22,
                  color: selected
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      item.label,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: selected
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactNavBar extends StatelessWidget {
  const _CompactNavBar({
    required this.controller,
    required this.showFavorites,
    required this.showHistory,
    required this.showFinishes,
  });

  final _NavAdapter controller;
  final bool showFavorites;
  final bool showHistory;
  final bool showFinishes;

  @override
  Widget build(BuildContext context) {
    final visible = _visibleNavEntries(
      controller.items,
      showFavorites,
      showHistory,
      showFinishes,
    );
    final theme = Theme.of(context);
    final barBg = theme.brightness == Brightness.dark
        ? theme.canvasColor
        : theme.colorScheme.surfaceContainerHighest;
    return Material(
      color: barBg,
      child: SafeArea(
        child: Row(
          children: [
            for (final e in visible)
              Expanded(
                child: _NavBarTile(
                  item: e.item,
                  selected: controller.currentIndex == e.index,
                  onTap: () => controller.goTo(e.index),
                  showLabel: false,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FullNavBar extends StatelessWidget {
  const _FullNavBar({
    required this.controller,
    required this.showFavorites,
    required this.showHistory,
    required this.showFinishes,
  });

  final _NavAdapter controller;
  final bool showFavorites;
  final bool showHistory;
  final bool showFinishes;

  @override
  Widget build(BuildContext context) {
    final visible = _visibleNavEntries(
      controller.items,
      showFavorites,
      showHistory,
      showFinishes,
    );
    final theme = Theme.of(context);
    final barBg = theme.brightness == Brightness.dark
        ? theme.canvasColor
        : theme.colorScheme.surfaceContainerHighest;
    return Material(
      color: barBg,
      child: SafeArea(
        child: Row(
          children: [
            for (final e in visible)
              _NavBarTile(
                item: e.item,
                selected: controller.currentIndex == e.index,
                onTap: () => controller.goTo(e.index),
                showLabel: true,
              ),
          ],
        ),
      ),
    );
  }
}

class _NavBarTile extends StatelessWidget {
  const _NavBarTile({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.showLabel,
  });

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final child = showLabel
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 20),
              const SizedBox(width: 8),
              Text(item.label),
            ],
          )
        : Icon(item.icon);
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      minimumSize: Size.zero,
      onPressed: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: child,
    );
  }
}
