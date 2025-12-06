import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'home/home_page.dart';
import 'hot/hot_page.dart';
import 'popular/popular_page.dart';
import 'profile/profile_page.dart';
import 'settings/settings_page.dart';

/// Main tab navigation page
class MainTabPage extends StatefulWidget {
  const MainTabPage({super.key});

  @override
  State<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    HotPage(),
    PopularPage(),
    ProfilePage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;

    return CupertinoPageScaffold(
      child: Stack(
        children: [
          // Page content
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          // Liquid Glass navigation bar
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 8,
            child: _buildLiquidGlassNavBar(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildLiquidGlassNavBar(bool isDark) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          // Outer glow/shadow
          BoxShadow(
            color: isDark
                ? CupertinoColors.black.withOpacity(0.4)
                : CupertinoColors.black.withOpacity(0.08),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          // Inner highlight (top)
          BoxShadow(
            color: isDark
                ? CupertinoColors.white.withOpacity(0.05)
                : CupertinoColors.white.withOpacity(0.8),
            blurRadius: 1,
            spreadRadius: 0,
            offset: const Offset(0, -0.5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              // Liquid glass gradient
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        CupertinoColors.white.withOpacity(0.18),
                        CupertinoColors.white.withOpacity(0.08),
                      ]
                    : [
                        CupertinoColors.white.withOpacity(0.85),
                        CupertinoColors.white.withOpacity(0.65),
                      ],
              ),
              // Subtle border for glass edge effect
              border: Border.all(
                color: isDark
                    ? CupertinoColors.white.withOpacity(0.2)
                    : CupertinoColors.white.withOpacity(0.6),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLiquidGlassNavItem(
                  index: 0,
                  icon: CupertinoIcons.home,
                  activeIcon: CupertinoIcons.house_fill,
                  label: 'Home',
                  isDark: isDark,
                ),
                _buildLiquidGlassNavItem(
                  index: 1,
                  icon: CupertinoIcons.flame,
                  activeIcon: CupertinoIcons.flame_fill,
                  label: 'Hot',
                  isDark: isDark,
                ),
                _buildLiquidGlassNavItem(
                  index: 2,
                  icon: CupertinoIcons.star,
                  activeIcon: CupertinoIcons.star_fill,
                  label: 'Popular',
                  isDark: isDark,
                ),
                _buildLiquidGlassNavItem(
                  index: 3,
                  icon: CupertinoIcons.person,
                  activeIcon: CupertinoIcons.person_fill,
                  label: 'Profile',
                  isDark: isDark,
                ),
                _buildLiquidGlassNavItem(
                  index: 4,
                  icon: CupertinoIcons.settings,
                  activeIcon: CupertinoIcons.settings_solid,
                  label: 'Settings',
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiquidGlassNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isDark,
  }) {
    final isSelected = _currentIndex == index;
    
    // Colors matching iOS 26 liquid glass style
    final selectedColor = isDark
        ? CupertinoColors.white
        : CupertinoColors.black;
    final unselectedColor = isDark
        ? CupertinoColors.white.withOpacity(0.5)
        : CupertinoColors.black.withOpacity(0.4);

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: isSelected ? 72 : 56,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: isDark
                    ? CupertinoColors.white.withOpacity(0.15)
                    : CupertinoColors.black.withOpacity(0.06),
              )
            : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                color: isSelected ? selectedColor : unselectedColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? selectedColor : unselectedColor,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
