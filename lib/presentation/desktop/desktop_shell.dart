import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/input/input.dart';
import '../../core/theme/ui_style_manager.dart';
import '../pages/post/post_detail_page.dart';
import '../providers/navigation_provider.dart';
import 'pages/desktop_favorites_page.dart';
import 'pages/desktop_home_page.dart';
import 'pages/desktop_hot_page.dart';
import 'pages/desktop_popular_page.dart';
import 'pages/desktop_post_detail_page.dart';
import 'pages/desktop_profile_page.dart';
import 'pages/desktop_search_page.dart';
import 'pages/desktop_settings_page.dart';
import 'widgets/desktop_sidebar.dart';

/// Design constants matching the login page theme
class _ShellColors {
  static const Color primaryIndigo = Color(0xFF6366F1);
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color primaryViolet = Color(0xFFA855F7);
}

/// Desktop shell with macOS-style sidebar navigation and modern design
/// Includes full gamepad/controller support for SteamOS and Steam Deck
class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key});

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell>
    with SingleTickerProviderStateMixin, GamepadInputMixin {
  bool _sidebarCollapsed = false;

  // For post detail view
  PostDetailArguments? _postDetailArgs;
  String? _searchQuery;

  // Background animation
  late AnimationController _bgAnimationController;

  // Controller state
  bool _showControllerMode = false;

  // Navigation indices for sidebar (for controller navigation)
  static const List<int> _sidebarNavOrder = [
    0,
    1,
    2,
    6,
    4,
    5,
    3,
  ]; // Home, Hot, Popular, Favorites, Search, Profile, Settings

  @override
  void initState() {
    super.initState();
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    // Check if controller is connected
    _showControllerMode = gamepad.isConnected;

    // Listen for controller connection changes
    gamepad.stateChanges.listen((state) {
      if (mounted && state.isConnected != _showControllerMode) {
        setState(() => _showControllerMode = state.isConnected);
      }
    });
  }

  @override
  void dispose() {
    _bgAnimationController.dispose();
    super.dispose();
  }

  /// Handle gamepad D-pad navigation for sidebar
  /// Up/Down navigates sidebar items when no post detail is open
  @override
  void onGamepadDirection(GamepadDirection direction) {
    if (!mounted) return;

    // Don't handle if post detail is open (it handles its own navigation)
    if (_postDetailArgs != null) return;

    final navProvider = context.read<NavigationProvider>();
    final selectedIndex = navProvider.getDesktopIndex();
    final currentNavIndex = _sidebarNavOrder.indexOf(selectedIndex);

    switch (direction) {
      case GamepadDirection.up:
        // Navigate to previous sidebar item
        if (currentNavIndex > 0) {
          _onNavItemSelected(_sidebarNavOrder[currentNavIndex - 1]);
          HapticFeedback.selectionClick();
        }

      case GamepadDirection.down:
        // Navigate to next sidebar item
        if (currentNavIndex < _sidebarNavOrder.length - 1) {
          _onNavItemSelected(_sidebarNavOrder[currentNavIndex + 1]);
          HapticFeedback.selectionClick();
        }

      default:
        break;
    }
  }

  /// Handle gamepad button presses
  @override
  void onGamepadButton(GamepadButton button) {
    if (!mounted) return;

    // Don't handle if post detail is open (it handles its own buttons)
    if (_postDetailArgs != null) return;

    switch (button) {
      case GamepadButton.start:
        // Toggle sidebar collapse
        _toggleSidebar();
        HapticFeedback.mediumImpact();

      case GamepadButton.select:
        // Open search
        _openSearch();
        HapticFeedback.mediumImpact();

      default:
        break;
    }
  }

  void _onNavItemSelected(int index) {
    final navProvider = context.read<NavigationProvider>();
    navProvider.setFromDesktopIndex(index);
    setState(() {
      _searchQuery = null;
    });
  }

  void _openPostDetail(PostDetailArguments args) {
    setState(() {
      _postDetailArgs = args;
    });
  }

  void _closePostDetail() {
    setState(() {
      _postDetailArgs = null;
    });
  }

  void _openSearch([String? query]) {
    final navProvider = context.read<NavigationProvider>();
    navProvider.setFromDesktopIndex(4); // Search tab
    setState(() {
      _searchQuery = query;
      _postDetailArgs = null;
    });
  }

  void _toggleSidebar() {
    setState(() {
      _sidebarCollapsed = !_sidebarCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final isLiquidGlass = UIStyleManager.isLiquidGlass(context);
    final navProvider = context.watch<NavigationProvider>();
    final selectedIndex = navProvider.getDesktopIndex();

    return CupertinoPageScaffold(
      child: Container(
        // Base background color
        color: isDark ? const Color(0xFF0A0A0C) : const Color(0xFFF8F8FC),
        child: Stack(
          children: [
            // Animated gradient background (only for liquid glass mode)
            if (isLiquidGlass)
              AnimatedBuilder(
                animation: _bgAnimationController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _ShellBackgroundPainter(
                      isDark: isDark,
                      animationValue: _bgAnimationController.value,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
            // Main layout with sidebar
            Row(
              children: [
                // Sidebar
                DesktopSidebar(
                  selectedIndex: selectedIndex,
                  onItemSelected: _onNavItemSelected,
                  isCollapsed: _sidebarCollapsed,
                  onToggleCollapse: _toggleSidebar,
                ),
                // Main content area
                Expanded(child: ClipRect(child: _buildMainContent(selectedIndex))),
              ],
            ),
            // Full-screen post detail overlay
            if (_postDetailArgs != null) _buildPostDetailOverlay(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(int selectedIndex) {
    switch (selectedIndex) {
      case 0:
        return DesktopHomePage(
          onPostTap: _openPostDetail,
          onSearchTap: _openSearch,
        );
      case 1:
        return DesktopHotPage(
          onPostTap: _openPostDetail,
          onSearchTap: _openSearch,
        );
      case 2:
        return DesktopPopularPage(
          onPostTap: _openPostDetail,
          onSearchTap: _openSearch,
        );
      case 3:
        return DesktopSettingsPage(
          onNavigate: (route) {
            Navigator.of(context).pushNamed(route);
          },
        );
      case 4:
        return DesktopSearchPage(
          initialQuery: _searchQuery,
          onPostTap: _openPostDetail,
        );
      case 5:
        return DesktopProfilePage(
          onNavigate: (route) {
            Navigator.of(context).pushNamed(route);
          },
        );
      case 6:
        return DesktopFavoritesPage(onPostTap: _openPostDetail);
      default:
        return DesktopHomePage(
          onPostTap: _openPostDetail,
          onSearchTap: _openSearch,
        );
    }
  }

  Widget _buildPostDetailOverlay(bool isDark) {
    // Use a unique key based on postIds and initialIndex to force rebuild when post changes
    final key = ValueKey(
      '${_postDetailArgs!.postIds.hashCode}_${_postDetailArgs!.initialIndex}',
    );

    return DesktopPostDetailPage(
      key: key,
      postIds: _postDetailArgs!.postIds,
      initialIndex: _postDetailArgs!.initialIndex,
      onSearchTag: _openSearch,
      onClose: _closePostDetail,
      onLoadMore: _postDetailArgs!.onLoadMore,
      hasMore: _postDetailArgs!.hasMore,
    );
  }
}

/// Background painter for animated gradient orbs
class _ShellBackgroundPainter extends CustomPainter {
  final bool isDark;
  final double animationValue;

  _ShellBackgroundPainter({required this.isDark, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final colors = isDark
        ? [
            _ShellColors.primaryIndigo.withValues(alpha: 0.06),
            _ShellColors.primaryPurple.withValues(alpha: 0.05),
            _ShellColors.primaryViolet.withValues(alpha: 0.04),
          ]
        : [
            _ShellColors.primaryIndigo.withValues(alpha: 0.04),
            _ShellColors.primaryPurple.withValues(alpha: 0.03),
            _ShellColors.primaryViolet.withValues(alpha: 0.025),
          ];

    // Top right orb
    paint.shader =
        RadialGradient(
          colors: [colors[0], colors[0].withValues(alpha: 0)],
        ).createShader(
          Rect.fromCircle(
            center: Offset(
              size.width * 0.85 + math.sin(animationValue * math.pi * 2) * 30,
              size.height * 0.15 + math.cos(animationValue * math.pi * 2) * 25,
            ),
            radius: size.width * 0.4,
          ),
        );
    canvas.drawCircle(
      Offset(
        size.width * 0.85 + math.sin(animationValue * math.pi * 2) * 30,
        size.height * 0.15 + math.cos(animationValue * math.pi * 2) * 25,
      ),
      size.width * 0.4,
      paint,
    );

    // Bottom left orb
    paint.shader =
        RadialGradient(
          colors: [colors[1], colors[1].withValues(alpha: 0)],
        ).createShader(
          Rect.fromCircle(
            center: Offset(
              size.width * 0.2 + math.cos(animationValue * math.pi * 2) * 20,
              size.height * 0.8 + math.sin(animationValue * math.pi * 2) * 30,
            ),
            radius: size.width * 0.35,
          ),
        );
    canvas.drawCircle(
      Offset(
        size.width * 0.2 + math.cos(animationValue * math.pi * 2) * 20,
        size.height * 0.8 + math.sin(animationValue * math.pi * 2) * 30,
      ),
      size.width * 0.35,
      paint,
    );

    // Center right orb
    paint.shader =
        RadialGradient(
          colors: [colors[2], colors[2].withValues(alpha: 0)],
        ).createShader(
          Rect.fromCircle(
            center: Offset(
              size.width * 0.7 +
                  math.sin(animationValue * math.pi * 2 + 1) * 25,
              size.height * 0.5 +
                  math.cos(animationValue * math.pi * 2 + 1) * 35,
            ),
            radius: size.width * 0.3,
          ),
        );
    canvas.drawCircle(
      Offset(
        size.width * 0.7 + math.sin(animationValue * math.pi * 2 + 1) * 25,
        size.height * 0.5 + math.cos(animationValue * math.pi * 2 + 1) * 35,
      ),
      size.width * 0.3,
      paint,
    );

    // Extra small accent orb
    paint.shader =
        RadialGradient(
          colors: [colors[0], colors[0].withValues(alpha: 0)],
        ).createShader(
          Rect.fromCircle(
            center: Offset(
              size.width * 0.4 +
                  math.cos(animationValue * math.pi * 2 + 2) * 15,
              size.height * 0.3 +
                  math.sin(animationValue * math.pi * 2 + 2) * 20,
            ),
            radius: size.width * 0.2,
          ),
        );
    canvas.drawCircle(
      Offset(
        size.width * 0.4 + math.cos(animationValue * math.pi * 2 + 2) * 15,
        size.height * 0.3 + math.sin(animationValue * math.pi * 2 + 2) * 20,
      ),
      size.width * 0.2,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ShellBackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isDark != isDark;
  }
}
