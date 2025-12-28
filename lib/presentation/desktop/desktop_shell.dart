import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import '../../core/theme/ui_style_manager.dart';
import '../pages/post/post_detail_page.dart';
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
class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key});

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _sidebarCollapsed = false;

  // For post detail view
  PostDetailArguments? _postDetailArgs;
  String? _searchQuery;

  // Background animation
  late AnimationController _bgAnimationController;

  @override
  void initState() {
    super.initState();
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _bgAnimationController.dispose();
    super.dispose();
  }

  void _onNavItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
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
    setState(() {
      _selectedIndex = 4; // Search tab
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
                  selectedIndex: _selectedIndex,
                  onItemSelected: _onNavItemSelected,
                  isCollapsed: _sidebarCollapsed,
                  onToggleCollapse: _toggleSidebar,
                ),
                // Main content area
                Expanded(
                  child: ClipRect(
                    child: _buildMainContent(),
                  ),
                ),
              ],
            ),
            // Full-screen post detail overlay
            if (_postDetailArgs != null) _buildPostDetailOverlay(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_selectedIndex) {
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
        return DesktopFavoritesPage(
          onPostTap: _openPostDetail,
        );
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

  _ShellBackgroundPainter({
    required this.isDark,
    required this.animationValue,
  });

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
    paint.shader = RadialGradient(
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
    paint.shader = RadialGradient(
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
    paint.shader = RadialGradient(
      colors: [colors[2], colors[2].withValues(alpha: 0)],
    ).createShader(
      Rect.fromCircle(
        center: Offset(
          size.width * 0.7 + math.sin(animationValue * math.pi * 2 + 1) * 25,
          size.height * 0.5 + math.cos(animationValue * math.pi * 2 + 1) * 35,
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
    paint.shader = RadialGradient(
      colors: [colors[0], colors[0].withValues(alpha: 0)],
    ).createShader(
      Rect.fromCircle(
        center: Offset(
          size.width * 0.4 + math.cos(animationValue * math.pi * 2 + 2) * 15,
          size.height * 0.3 + math.sin(animationValue * math.pi * 2 + 2) * 20,
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
