part of '../navbar.dart';

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
    final l10n = AppLocalizations.of(context);
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
    final barBg = isDark ? theme.canvasColor : colorScheme.surfaceContainerHigh;
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
                    label: primaryVisible[i].item.label(l10n),
                    selected: selectedIndex == i,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      controller.goTo(primaryVisible[i].index);
                    },
                  ),
                ),
              if (moreVisible.isNotEmpty)
                Expanded(
                  child: Builder(
                    builder: (moreContext) => _BottomNavDestination(
                      icon: CupertinoIcons.ellipsis,
                      label: l10n.commonMore,
                      selected: selectedIndex == primaryCount,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _showMoreMenu(moreContext, moreVisible, controller);
                      },
                    ),
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

Future<void> _showMoreMenu(
  BuildContext context,
  List<({int index, NavItem item})> entries,
  _NavAdapter nav,
) async {
  final l10n = AppLocalizations.of(context);
  final box = context.findRenderObject()! as RenderBox;
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  final rect = RelativeRect.fromRect(
    Rect.fromPoints(
      box.localToGlobal(Offset.zero, ancestor: overlay),
      box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
    ),
    Offset.zero & overlay.size,
  );

  final selected = await showMenu<int>(
    context: context,
    position: rect,
    items: entries
        .map(
          (e) => PopupMenuTile<int>(
            title: e.item.label(l10n),
            icon: e.item.icon,
            value: e.index,
          ),
        )
        .toList(),
  );

  if (selected != null) {
    HapticFeedback.selectionClick();
    nav.goTo(selected);
  }
}
