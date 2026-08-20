part of '../navbar.dart';

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
          widget.controller.autoExpandSidebar();
        });
      } else if (!wasNarrow && isNarrow) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          widget.controller.setSidebarCollapsed(true);
        });
      }
    }

    _lastLayoutWidth = newWidth;
  }

  @override
  Widget build(BuildContext context) {
    final layoutWidth = widget.layoutWidth;
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
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 28, 8, 8),
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
                            ? const Center(child: AppIcon(radius: 11))
                            : Row(
                                children: [
                                  const AppIcon(radius: 11),
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
        message: identity.username,
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
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Tooltip(
      message: effectiveCollapsed
          ? l10n.commonExpandSidebar
          : l10n.commonShrinkSidebar,
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
                        l10n.commonShrinkSidebar,
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
    final l10n = AppLocalizations.of(context);
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
                      item.label(l10n),
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
