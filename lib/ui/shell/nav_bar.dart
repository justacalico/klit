import 'dart:ui';
import 'package:flutter/cupertino.dart';
import '../../core/theme/ui_style_manager.dart';
import '../../core/utils/helpers.dart';
import '../theme.dart';

/// Nav item definitions for bottom navbar (mobile)
const Map<int, Map<String, dynamic>> _navDefs = {
  0: {'icon': CupertinoIcons.home, 'activeIcon': CupertinoIcons.house_fill, 'label': 'Home'},
  1: {'icon': CupertinoIcons.flame, 'activeIcon': CupertinoIcons.flame_fill, 'label': 'Hot'},
  2: {'icon': CupertinoIcons.star, 'activeIcon': CupertinoIcons.star_fill, 'label': 'Popular'},
  3: {'icon': CupertinoIcons.person, 'activeIcon': CupertinoIcons.person_fill, 'label': 'Profile'},
  4: {'icon': CupertinoIcons.settings, 'activeIcon': CupertinoIcons.settings_solid, 'label': 'Settings'},
};

class AppNavBar extends StatelessWidget {
  final List<int> navOrder;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isGuest;
  final VoidCallback onLogout;

  const AppNavBar({
    super.key,
    required this.navOrder,
    required this.currentIndex,
    required this.onTap,
    required this.isGuest,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final isLiquidGlass = UIStyleManager.isLiquidGlass(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    if (isLiquidGlass) {
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding + 16),
        child: _buildLiquidGlass(context, isDark),
      );
    }
    return _buildMaterial(context, isDark);
  }

  Widget _buildLiquidGlass(BuildContext context, bool isDark) {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: UIColors.primaryPurple.withValues(alpha: isDark ? 0.3 : 0.15),
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
                colors: isDark
                    ? [const Color(0xFF1C1C1E), const Color(0xFF2C2C2E)]
                    : [const Color(0xFFF5F5F7), const Color(0xFFEBEBEF)],
              ),
              border: Border.all(color: UIColors.primaryPurple.withValues(alpha: isDark ? 0.2 : 0.1), width: 1),
            ),
            child: _buildContent(context, isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildMaterial(BuildContext context, bool isDark) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
        border: Border(
          top: BorderSide(color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5E7), width: 0.5),
        ),
      ),
      child: SizedBox(
        height: 56,
        child: _buildContent(context, isDark),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (int i = 0; i < navOrder.length; i++)
          if (isGuest && navOrder[i] == 4)
            _LogoutItem(isDark: isDark, onTap: onLogout)
          else
            _NavItem(
              index: i,
              currentIndex: currentIndex,
              icon: _navDefs[navOrder[i]]!['icon'] as IconData,
              activeIcon: _navDefs[navOrder[i]]!['activeIcon'] as IconData,
              label: _navDefs[navOrder[i]]!['label'] as String,
              isDark: isDark,
              onTap: () => onTap(i),
            ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentIndex == index;
    final color = isSelected ? UIColors.primaryPurple : (isDark ? CupertinoColors.white.withValues(alpha: 0.6) : CupertinoColors.black.withValues(alpha: 0.6));

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticUtils.selectionClick();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
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
            children: [
              Icon(isSelected ? activeIcon : icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutItem extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _LogoutItem({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isDark ? CupertinoColors.white.withValues(alpha: 0.5) : CupertinoColors.black.withValues(alpha: 0.4);
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticUtils.selectionClick();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.square_arrow_right, color: color, size: 24),
            const SizedBox(height: 4),
            Text('Sign Out', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color)),
          ],
        ),
      ),
    );
  }
}
