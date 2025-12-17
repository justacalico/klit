import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../app/routes.dart';
import '../../core/utils/helpers.dart';
import '../providers/providers.dart';
import 'home/home_page.dart';
import 'hot/hot_page.dart';
import 'popular/popular_page.dart';
import 'profile/profile_page.dart';
import 'settings/settings_page.dart';

/// Design constants for the purple/indigo mobile theme
class MobileThemeColors {
  static const Color primaryIndigo = Color(0xFF6366F1);
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color primaryViolet = Color(0xFFA855F7);
}

/// Main tab navigation page
class MainTabPage extends StatefulWidget {
  const MainTabPage({super.key});

  @override
  State<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> {
  int _currentIndex = 0;

  // All available pages mapped by their ID
  static const Map<int, Widget> _allPages = {
    0: HomePage(),
    1: HotPage(),
    2: PopularPage(),
    3: ProfilePage(),
    4: SettingsPage(),
  };

  // Navigation item definitions
  static const Map<int, Map<String, dynamic>> _navItemDefs = {
    0: {
      'icon': CupertinoIcons.home,
      'activeIcon': CupertinoIcons.house_fill,
      'label': 'Home',
    },
    1: {
      'icon': CupertinoIcons.flame,
      'activeIcon': CupertinoIcons.flame_fill,
      'label': 'Hot',
    },
    2: {
      'icon': CupertinoIcons.star,
      'activeIcon': CupertinoIcons.star_fill,
      'label': 'Popular',
    },
    3: {
      'icon': CupertinoIcons.person,
      'activeIcon': CupertinoIcons.person_fill,
      'label': 'Profile',
    },
    4: {
      'icon': CupertinoIcons.settings,
      'activeIcon': CupertinoIcons.settings_solid,
      'label': 'Settings',
    },
  };

  void _handleLogout(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of guest mode?'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(dialogContext).pop();
              final authProvider = context.read<AuthProvider>();
              authProvider.logout();
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
            },
            child: const Text('Sign Out'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(),
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
    final isGuest = context.watch<AuthProvider>().isGuest;
    final navOrder = context.watch<SettingsProvider>().mobileNavOrder;

    // Build pages list based on custom order
    final orderedPages = navOrder.map((id) => _allPages[id]!).toList();

    return PopScope(
      canPop: false,
      child: CupertinoPageScaffold(
        child: Stack(
          children: [
            // Page content based on custom order
            IndexedStack(index: _currentIndex, children: orderedPages),
            // Modern gradient navigation bar
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              child: _buildModernNavBar(isDark, isGuest, navOrder),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernNavBar(bool isDark, bool isGuest, List<int> navOrder) {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          // Purple glow effect
          BoxShadow(
            color: MobileThemeColors.primaryPurple.withValues(alpha: isDark ? 0.3 : 0.15),
            blurRadius: 20,
            spreadRadius: -2,
            offset: const Offset(0, 8),
          ),
          // Outer shadow
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: isDark ? 0.4 : 0.1),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              // Modern gradient with purple tint
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF1C1C1E).withValues(alpha: 0.9),
                        const Color(0xFF2C2C2E).withValues(alpha: 0.85),
                      ]
                    : [
                        CupertinoColors.white.withValues(alpha: 0.92),
                        CupertinoColors.white.withValues(alpha: 0.85),
                      ],
              ),
              // Purple tinted border
              border: Border.all(
                color: isDark
                    ? MobileThemeColors.primaryPurple.withValues(alpha: 0.2)
                    : MobileThemeColors.primaryPurple.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Build nav items based on custom order
                for (int i = 0; i < navOrder.length; i++) ...[
                  // In guest mode, replace Settings (4) with Sign Out
                  if (isGuest && navOrder[i] == 4)
                    _buildLogoutNavItem(isDark)
                  else
                    _buildModernNavItem(
                      index: i,
                      icon: _navItemDefs[navOrder[i]]!['icon'] as IconData,
                      activeIcon: _navItemDefs[navOrder[i]]!['activeIcon'] as IconData,
                      label: _navItemDefs[navOrder[i]]!['label'] as String,
                      isDark: isDark,
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutNavItem(bool isDark) {
    final color = isDark
        ? CupertinoColors.white.withValues(alpha: 0.5)
        : CupertinoColors.black.withValues(alpha: 0.4);

    return GestureDetector(
      onTap: () {
        HapticUtils.selectionClick();
        _handleLogout(context);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 56,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.square_arrow_right, color: color, size: 24),
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
        ),
      ),
    );
  }

  Widget _buildModernNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isDark,
  }) {
    final isSelected = _currentIndex == index;

    // Purple gradient for selected items
    final selectedColor = MobileThemeColors.primaryPurple;
    final unselectedColor = isDark
        ? CupertinoColors.white.withValues(alpha: 0.5)
        : CupertinoColors.black.withValues(alpha: 0.4);

    return GestureDetector(
      onTap: () {
        HapticUtils.selectionClick();
        setState(() => _currentIndex = index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: isSelected ? 72 : 56,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    MobileThemeColors.primaryIndigo.withValues(alpha: 0.2),
                    MobileThemeColors.primaryPurple.withValues(alpha: 0.15),
                  ],
                ),
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
            const SizedBox(height: 4),
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
