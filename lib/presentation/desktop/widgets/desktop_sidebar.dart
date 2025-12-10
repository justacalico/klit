import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../../app/routes.dart';
import '../../providers/providers.dart';

/// Design constants for the new purple/indigo theme
class _DesignColors {
  static const Color primaryIndigo = Color(0xFF6366F1);
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color primaryViolet = Color(0xFFA855F7);
}

/// macOS-style sidebar for desktop navigation with modern glassmorphism
class DesktopSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  const DesktopSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.isCollapsed = false,
    required this.onToggleCollapse,
  });

  @override
  State<DesktopSidebar> createState() => _DesktopSidebarState();
}

class _DesktopSidebarState extends State<DesktopSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _bgAnimationController;

  @override
  void initState() {
    super.initState();
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _bgAnimationController.dispose();
    super.dispose();
  }

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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: widget.isCollapsed ? 72 : 240,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF18181B).withValues(alpha: 0.85),
                        const Color(0xFF1F1F23).withValues(alpha: 0.9),
                        const Color(0xFF18181B).withValues(alpha: 0.95),
                      ]
                    : [
                        const Color(0xFFFFFFFF).withValues(alpha: 0.8),
                        const Color(0xFFFAFAFC).withValues(alpha: 0.85),
                        const Color(0xFFF5F5F7).withValues(alpha: 0.9),
                      ],
                stops: const [0.0, 0.5, 1.0],
              ),
              border: Border(
                right: BorderSide(
                  color: isDark
                      ? _DesignColors.primaryPurple.withValues(alpha: 0.15)
                      : _DesignColors.primaryPurple.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Stack(
              children: [
                // Animated gradient orbs in background
                AnimatedBuilder(
                  animation: _bgAnimationController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _SidebarBackgroundPainter(
                        isDark: isDark,
                        animationValue: _bgAnimationController.value,
                      ),
                      size: Size.infinite,
                    );
                  },
                ),
                // Main content
                Column(
                  children: [
                    // App header
                    _buildHeader(context, isDark),
                    const SizedBox(height: 12),
                    // Navigation items
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          _SidebarSection(
                            title: 'Browse',
                            isCollapsed: widget.isCollapsed,
                            children: [
                              _SidebarItem(
                                icon: CupertinoIcons.house_fill,
                                label: 'Home',
                                isSelected: widget.selectedIndex == 0,
                                isCollapsed: widget.isCollapsed,
                                onTap: () => widget.onItemSelected(0),
                              ),
                              _SidebarItem(
                                icon: CupertinoIcons.flame_fill,
                                label: 'Hot',
                                isSelected: widget.selectedIndex == 1,
                                isCollapsed: widget.isCollapsed,
                                onTap: () => widget.onItemSelected(1),
                              ),
                              _SidebarItem(
                                icon: CupertinoIcons.star_fill,
                                label: 'Popular',
                                isSelected: widget.selectedIndex == 2,
                                isCollapsed: widget.isCollapsed,
                                onTap: () => widget.onItemSelected(2),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _SidebarSection(
                            title: 'Tools',
                            isCollapsed: widget.isCollapsed,
                            children: [
                              _SidebarItem(
                                icon: CupertinoIcons.search,
                                label: 'Search',
                                isSelected: widget.selectedIndex == 4,
                                isCollapsed: widget.isCollapsed,
                                onTap: () => widget.onItemSelected(4),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _SidebarSection(
                            title: 'Account',
                            isCollapsed: widget.isCollapsed,
                            children: [
                              _SidebarItem(
                                icon: CupertinoIcons.person_fill,
                                label: 'Profile',
                                isSelected: widget.selectedIndex == 5,
                                isCollapsed: widget.isCollapsed,
                                onTap: () => widget.onItemSelected(5),
                              ),
                              _SidebarItem(
                                icon: CupertinoIcons.heart_fill,
                                label: 'Favorites',
                                isSelected: widget.selectedIndex == 6,
                                isCollapsed: widget.isCollapsed,
                                onTap: () => widget.onItemSelected(6),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Settings or Sign Out at bottom
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: isGuest
                          ? _SidebarItem(
                              icon: CupertinoIcons.square_arrow_right,
                              label: 'Sign Out',
                              isSelected: false,
                              isCollapsed: widget.isCollapsed,
                              onTap: () => _handleLogout(context),
                            )
                          : _SidebarItem(
                              icon: CupertinoIcons.settings,
                              label: 'Settings',
                              isSelected: widget.selectedIndex == 3,
                              isCollapsed: widget.isCollapsed,
                              onTap: () => widget.onItemSelected(3),
                            ),
                    ),
                    const SizedBox(height: 8),
                    // Collapse toggle
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: _GlassCollapseButton(
                        isCollapsed: widget.isCollapsed,
                        onTap: widget.onToggleCollapse,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? _DesignColors.primaryPurple.withValues(alpha: 0.1)
                : _DesignColors.primaryPurple.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // App icon with gradient
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6366F1),
                  Color(0xFF8B5CF6),
                  Color(0xFFA855F7),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: _DesignColors.primaryPurple.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'K',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          if (!widget.isCollapsed) ...[
            const SizedBox(width: 12),
            Text(
              'Klit',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: isDark ? CupertinoColors.white : const Color(0xFF1F2937),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Background painter for animated gradient orbs
class _SidebarBackgroundPainter extends CustomPainter {
  final bool isDark;
  final double animationValue;

  _SidebarBackgroundPainter({
    required this.isDark,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final colors = isDark
        ? [
            _DesignColors.primaryIndigo.withValues(alpha: 0.08),
            _DesignColors.primaryPurple.withValues(alpha: 0.06),
            _DesignColors.primaryViolet.withValues(alpha: 0.05),
          ]
        : [
            _DesignColors.primaryIndigo.withValues(alpha: 0.05),
            _DesignColors.primaryPurple.withValues(alpha: 0.04),
            _DesignColors.primaryViolet.withValues(alpha: 0.03),
          ];

    // Top orb
    paint.shader = RadialGradient(
      colors: [colors[0], colors[0].withValues(alpha: 0)],
    ).createShader(
      Rect.fromCircle(
        center: Offset(
          size.width * 0.8 + math.sin(animationValue * math.pi * 2) * 10,
          size.height * 0.15 + math.cos(animationValue * math.pi * 2) * 15,
        ),
        radius: size.width * 0.8,
      ),
    );
    canvas.drawCircle(
      Offset(
        size.width * 0.8 + math.sin(animationValue * math.pi * 2) * 10,
        size.height * 0.15 + math.cos(animationValue * math.pi * 2) * 15,
      ),
      size.width * 0.8,
      paint,
    );

    // Middle orb
    paint.shader = RadialGradient(
      colors: [colors[1], colors[1].withValues(alpha: 0)],
    ).createShader(
      Rect.fromCircle(
        center: Offset(
          size.width * 0.2 + math.cos(animationValue * math.pi * 2 + 1) * 8,
          size.height * 0.5 + math.sin(animationValue * math.pi * 2 + 1) * 20,
        ),
        radius: size.width * 0.6,
      ),
    );
    canvas.drawCircle(
      Offset(
        size.width * 0.2 + math.cos(animationValue * math.pi * 2 + 1) * 8,
        size.height * 0.5 + math.sin(animationValue * math.pi * 2 + 1) * 20,
      ),
      size.width * 0.6,
      paint,
    );

    // Bottom orb
    paint.shader = RadialGradient(
      colors: [colors[2], colors[2].withValues(alpha: 0)],
    ).createShader(
      Rect.fromCircle(
        center: Offset(
          size.width * 0.7 + math.sin(animationValue * math.pi * 2 + 2) * 12,
          size.height * 0.85 + math.cos(animationValue * math.pi * 2 + 2) * 10,
        ),
        radius: size.width * 0.7,
      ),
    );
    canvas.drawCircle(
      Offset(
        size.width * 0.7 + math.sin(animationValue * math.pi * 2 + 2) * 12,
        size.height * 0.85 + math.cos(animationValue * math.pi * 2 + 2) * 10,
      ),
      size.width * 0.7,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SidebarBackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isDark != isDark;
  }
}

/// Sidebar section with title
class _SidebarSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool isCollapsed;

  const _SidebarSection({
    required this.title,
    required this.children,
    required this.isCollapsed,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isCollapsed)
          Padding(
            padding: const EdgeInsets.only(left: 14, bottom: 8, top: 4),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? CupertinoColors.systemGrey
                    : CupertinoColors.systemGrey,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ...children,
      ],
    );
  }
}

/// Individual sidebar navigation item with modern styling
class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final isActive = widget.isSelected || _isHovered;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
      },
      onExit: (_) {
        setState(() => _isHovered = false);
      },
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () => _controller.reverse(),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(vertical: 2),
                padding: EdgeInsets.symmetric(
                  horizontal: widget.isCollapsed ? 0 : 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: widget.isSelected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _DesignColors.primaryIndigo.withValues(
                              alpha: isDark ? 0.25 : 0.15,
                            ),
                            _DesignColors.primaryPurple.withValues(
                              alpha: isDark ? 0.2 : 0.12,
                            ),
                          ],
                        )
                      : _isHovered
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                (isDark
                                        ? const Color(0xFF2C2C2E)
                                        : const Color(0xFFE5E5EA))
                                    .withValues(alpha: 0.6),
                                (isDark
                                        ? const Color(0xFF2C2C2E)
                                        : const Color(0xFFE5E5EA))
                                    .withValues(alpha: 0.4),
                              ],
                            )
                          : null,
                  borderRadius: BorderRadius.circular(12),
                  border: widget.isSelected
                      ? Border.all(
                          color:
                              _DesignColors.primaryPurple.withValues(alpha: 0.3),
                          width: 1,
                        )
                      : null,
                  boxShadow: widget.isSelected
                      ? [
                          BoxShadow(
                            color: _DesignColors.primaryPurple.withValues(
                              alpha: 0.2,
                            ),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: widget.isCollapsed
                    ? Center(
                        child: _buildIcon(isDark),
                      )
                    : Row(
                        children: [
                          _buildIcon(isDark),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: widget.isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: widget.isSelected
                                    ? _DesignColors.primaryPurple
                                    : isDark
                                        ? CupertinoColors.white
                                        : const Color(0xFF374151),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildIcon(bool isDark) {
    return Container(
      width: 28,
      height: 28,
      decoration: widget.isSelected
          ? BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6366F1),
                  Color(0xFF8B5CF6),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: _DesignColors.primaryPurple.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            )
          : null,
      child: Icon(
        widget.icon,
        size: 16,
        color: widget.isSelected
            ? CupertinoColors.white
            : isDark
                ? CupertinoColors.systemGrey
                : CupertinoColors.systemGrey,
      ),
    );
  }
}

/// Glass-styled collapse toggle button
class _GlassCollapseButton extends StatefulWidget {
  final bool isCollapsed;
  final VoidCallback onTap;

  const _GlassCollapseButton({
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  State<_GlassCollapseButton> createState() => _GlassCollapseButtonState();
}

class _GlassCollapseButtonState extends State<_GlassCollapseButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: _isHovered
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _DesignColors.primaryIndigo.withValues(alpha: 0.15),
                      _DesignColors.primaryPurple.withValues(alpha: 0.1),
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            const Color(0xFF2C2C2E).withValues(alpha: 0.5),
                            const Color(0xFF1C1C1E).withValues(alpha: 0.4),
                          ]
                        : [
                            const Color(0xFFF2F2F7).withValues(alpha: 0.6),
                            const Color(0xFFFFFFFF).withValues(alpha: 0.5),
                          ],
                  ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isHovered
                  ? _DesignColors.primaryPurple.withValues(alpha: 0.3)
                  : isDark
                      ? const Color(0xFF3A3A3C).withValues(alpha: 0.3)
                      : const Color(0xFFD1D1D6).withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Icon(
            widget.isCollapsed
                ? CupertinoIcons.sidebar_right
                : CupertinoIcons.sidebar_left,
            size: 18,
            color: _isHovered
                ? _DesignColors.primaryPurple
                : CupertinoColors.systemGrey,
          ),
        ),
      ),
    );
  }
}
