import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../core/constants/constants.dart';
import '../../core/theme/ui_style_manager.dart';
import '../../providers/providers.dart';
import '../../core/utils/helpers.dart';
import '../theme.dart';

const Map<int, _NavItemData> _navDefs = {
  0: _NavItemData(
    icon: CupertinoIcons.home,
    activeIcon: CupertinoIcons.house_fill,
    label: 'Home',
  ),
  1: _NavItemData(
    icon: CupertinoIcons.flame,
    activeIcon: CupertinoIcons.flame_fill,
    label: 'Hot',
  ),
  2: _NavItemData(
    icon: CupertinoIcons.star,
    activeIcon: CupertinoIcons.star_fill,
    label: 'Popular',
  ),
  3: _NavItemData(
    icon: CupertinoIcons.settings,
    activeIcon: CupertinoIcons.settings_solid,
    label: 'Settings',
  ),
  4: _NavItemData(
    icon: CupertinoIcons.search,
    activeIcon: CupertinoIcons.search,
    label: 'Search',
  ),
  5: _NavItemData(
    icon: CupertinoIcons.person,
    activeIcon: CupertinoIcons.person_fill,
    label: 'Profile',
  ),
  6: _NavItemData(
    icon: CupertinoIcons.heart,
    activeIcon: CupertinoIcons.heart_fill,
    label: 'Favorites',
  ),
  7: _NavItemData(
    icon: CupertinoIcons.rectangle_stack_fill,
    activeIcon: CupertinoIcons.rectangle_stack_fill,
    label: 'Feeds',
  ),
  8: _NavItemData(
    icon: CupertinoIcons.ellipsis_circle,
    activeIcon: CupertinoIcons.ellipsis_circle_fill,
    label: 'More',
  ),
};

/// Section ids that are real destinations (not the More menu).
const Set<int> _sectionIds = {0, 1, 2, 3, 4, 5, 6, 7};

class _NavItemData {
  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.navOrder,
    required this.currentIndex,
    required this.onTap,
    required this.isGuest,
    required this.onLogout,
    this.onMoreOptionSelected,
  });

  final List<int> navOrder;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isGuest;
  final VoidCallback onLogout;
  final ValueChanged<int>? onMoreOptionSelected;

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final isOled = context.watch<SettingsProvider>().themeMode == 3;
    final isLiquidGlass = UIStyleManager.isLiquidGlass(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    if (isLiquidGlass) {
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding + 16),
        child: _buildLiquidGlass(context, isDark, isOled),
      );
    }
    return _buildMaterial(context, isDark, isOled, bottomPadding);
  }

  Widget _buildLiquidGlass(BuildContext context, bool isDark, bool isOled) {
    final compact = navOrder.length >= 5;
    final gradientColors = isOled
        ? [AppColors.oledSecondaryBackground, const Color(0xFF0F0F0F)]
        : (isDark
            ? [const Color(0xFF1C1C1E), const Color(0xFF2C2C2E)]
            : [const Color(0xFFF5F5F7), const Color(0xFFEBEBEF)]);
    return Container(
      height: compact ? 56 : 72,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: UIColors.primaryPurple.withValues(
              alpha: isDark ? 0.3 : 0.15,
            ),
            blurRadius: 20,
            spreadRadius: -2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: isDark ? 0.4 : 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              border: Border.all(
                color: UIColors.primaryPurple.withValues(
                  alpha: isDark ? 0.2 : 0.1,
                ),
                width: 1,
              ),
            ),
            child: _buildContent(context, isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildMaterial(
    BuildContext context,
    bool isDark,
    bool isOled,
    double bottomPadding,
  ) {
    final compact = navOrder.length >= 5;
    return Container(
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottomPadding),
      decoration: BoxDecoration(
        color: isOled
            ? AppColors.oledSecondaryBackground
            : (isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5E7),
            width: 0.5,
          ),
        ),
      ),
      child: SizedBox(
        height: compact ? 52 : 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _buildNavItemsWithSpacing(context, isDark),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _buildNavItemsWithSpacing(context, isDark),
    );
  }

  List<Widget> _buildNavItemsWithSpacing(BuildContext context, bool isDark) {
    final items = _buildNavItems(context, isDark);
    if (items.length <= 1) return items;
    final spaced = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) spaced.add(const SizedBox(width: 4));
      spaced.add(items[i]);
    }
    return spaced;
  }

  List<Widget> _buildNavItems(BuildContext context, bool isDark) {
    final showLabels = navOrder.length < 5;
    final items = <Widget>[];
    for (var i = 0; i < navOrder.length; i++) {
      final id = navOrder[i];
      final isSelected = i == currentIndex;
      if (id == 4 && isGuest) {
        items.add(_LogoutItem(
          isDark: isDark,
          onTap: onLogout,
          showLabel: showLabels,
        ));
      } else if (id == 8) {
        final def = _navDefs[8]!;
        final moreIds = _sectionIds
            .where((sid) => !navOrder.contains(sid))
            .toList()
          ..sort();
        items.add(
          _MoreMenuButton(
            icon: def.icon,
            activeIcon: def.activeIcon,
            label: def.label,
            isSelected: isSelected,
            isDark: isDark,
            showLabel: showLabels,
            moreIds: moreIds,
            onOptionSelected: (selectedId) {
              HapticUtils.selectionClick();
              onMoreOptionSelected?.call(selectedId);
            },
          ),
        );
      } else {
        final def = _navDefs[id];
        if (def != null) {
          items.add(
            _NavBarItem(
              icon: def.icon,
              activeIcon: def.activeIcon,
              label: def.label,
              isSelected: isSelected,
              isDark: isDark,
              showLabel: showLabels,
              onTap: () {
                HapticUtils.selectionClick();
                onTap(i);
              },
            ),
          );
        }
      }
    }
    return items;
  }
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.showLabel,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final bool isDark;
  final bool showLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? UIColors.primaryPurple
        : (isDark
              ? CupertinoColors.white.withValues(alpha: 0.6)
              : CupertinoColors.black.withValues(alpha: 0.6));

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: showLabel ? 8 : 10),
          decoration: isSelected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      UIColors.primaryIndigo.withValues(alpha: 0.2),
                      UIColors.primaryPurple.withValues(alpha: 0.15),
                    ],
                  ),
                )
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: color,
                size: showLabel ? 24 : 26,
              ),
              if (showLabel) ...[
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreMenuButton extends StatelessWidget {
  const _MoreMenuButton({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.showLabel,
    required this.moreIds,
    required this.onOptionSelected,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final bool isDark;
  final bool showLabel;
  final List<int> moreIds;
  final ValueChanged<int> onOptionSelected;

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? UIColors.primaryPurple
        : (isDark
            ? CupertinoColors.white.withValues(alpha: 0.6)
            : CupertinoColors.black.withValues(alpha: 0.6));

    return Expanded(
      child: GestureDetector(
        onTap: () => _showMoreMenu(context),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: showLabel ? 8 : 10),
          decoration: isSelected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      UIColors.primaryIndigo.withValues(alpha: 0.2),
                      UIColors.primaryPurple.withValues(alpha: 0.15),
                    ],
                  ),
                )
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: color,
                size: showLabel ? 24 : 26,
              ),
              if (showLabel) ...[
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showMoreMenu(BuildContext context) {
    if (moreIds.isEmpty) return;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: CupertinoTheme.brightnessOf(context) == Brightness.dark
              ? const Color(0xFF1C1C1E)
              : CupertinoColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'More',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.secondaryLabel.resolveFrom(ctx),
                  ),
                ),
              ),
              ...moreIds.map((id) {
                final def = _navDefs[id];
                if (def == null) return const SizedBox.shrink();
                return CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  alignment: Alignment.centerLeft,
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    onOptionSelected(id);
                  },
                  child: Row(
                    children: [
                      Icon(def.icon, size: 22, color: UIColors.primaryPurple),
                      const SizedBox(width: 12),
                      Text(def.label),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutItem extends StatelessWidget {
  const _LogoutItem({
    required this.isDark,
    required this.onTap,
    this.showLabel = true,
  });

  final bool isDark;
  final VoidCallback onTap;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final color = isDark
        ? CupertinoColors.white.withValues(alpha: 0.5)
        : CupertinoColors.black.withValues(alpha: 0.4);
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticUtils.selectionClick();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.square_arrow_right,
              color: color,
              size: showLabel ? 24 : 26,
            ),
            if (showLabel) ...[
              const SizedBox(height: 4),
              Text(
                'Sign Out',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
