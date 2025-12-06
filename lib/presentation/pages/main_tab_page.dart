import 'dart:ui';
import 'package:flutter/cupertino.dart';
import '../../core/constants/constants.dart';
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
          // Floating navigation bar
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 12,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSecondaryBackground.withOpacity(0.85)
                        : CupertinoColors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkSeparator.withOpacity(0.5)
                          : AppColors.lightSeparator.withOpacity(0.5),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(
                        index: 0,
                        icon: CupertinoIcons.home,
                        activeIcon: CupertinoIcons.house_fill,
                        label: 'Home',
                        isDark: isDark,
                      ),
                      _buildNavItem(
                        index: 1,
                        icon: CupertinoIcons.flame,
                        activeIcon: CupertinoIcons.flame_fill,
                        label: 'Hot',
                        isDark: isDark,
                      ),
                      _buildNavItem(
                        index: 2,
                        icon: CupertinoIcons.star,
                        activeIcon: CupertinoIcons.star_fill,
                        label: 'Popular',
                        isDark: isDark,
                      ),
                      _buildNavItem(
                        index: 3,
                        icon: CupertinoIcons.person,
                        activeIcon: CupertinoIcons.person_fill,
                        label: 'Profile',
                        isDark: isDark,
                      ),
                      _buildNavItem(
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
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isDark,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? AppColors.primaryBlue
        : (isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2);

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: color,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
