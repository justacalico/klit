part of '../navbar.dart';

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
    final l10n = AppLocalizations.of(context);
    final child = showLabel
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 20),
              const SizedBox(width: 8),
              Text(item.label(l10n)),
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
