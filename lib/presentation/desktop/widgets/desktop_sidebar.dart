import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../../app/routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/providers.dart';

/// macOS-style sidebar for desktop navigation
class DesktopSidebar extends StatelessWidget {
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
      width: isCollapsed ? 72 : 220,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF1C1C1E).withValues(alpha: 0.75),
                        const Color(0xFF2C2C2E).withValues(alpha: 0.85),
                        const Color(0xFF1C1C1E).withValues(alpha: 0.9),
                      ]
                    : [
                        const Color(0xFFFFFFFF).withValues(alpha: 0.7),
                        const Color(0xFFF8F8FA).withValues(alpha: 0.8),
                        const Color(0xFFF2F2F7).withValues(alpha: 0.85),
                      ],
                stops: const [0.0, 0.5, 1.0],
              ),
              border: Border(
                right: BorderSide(
                  color: isDark
                      ? const Color(0xFF3A3A3C).withValues(alpha: 0.4)
                      : const Color(0xFFD1D1D6).withValues(alpha: 0.5),
                  width: 0.5,
                ),
              ),
            ),
            child: Column(
        children: [
          // App header
          _buildHeader(context, isDark),
          const SizedBox(height: 8),
          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _SidebarSection(
                  title: 'Browse',
                  isCollapsed: isCollapsed,
                  children: [
                    _SidebarItem(
                      icon: CupertinoIcons.house_fill,
                      label: 'Home',
                      isSelected: selectedIndex == 0,
                      isCollapsed: isCollapsed,
                      onTap: () => onItemSelected(0),
                    ),
                    _SidebarItem(
                      icon: CupertinoIcons.flame_fill,
                      label: 'Hot',
                      isSelected: selectedIndex == 1,
                      isCollapsed: isCollapsed,
                      onTap: () => onItemSelected(1),
                    ),
                    _SidebarItem(
                      icon: CupertinoIcons.star_fill,
                      label: 'Popular',
                      isSelected: selectedIndex == 2,
                      isCollapsed: isCollapsed,
                      onTap: () => onItemSelected(2),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SidebarSection(
                  title: 'Tools',
                  isCollapsed: isCollapsed,
                  children: [
                    _SidebarItem(
                      icon: CupertinoIcons.search,
                      label: 'Search',
                      isSelected: selectedIndex == 4,
                      isCollapsed: isCollapsed,
                      onTap: () => onItemSelected(4),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SidebarSection(
                  title: 'Account',
                  isCollapsed: isCollapsed,
                  children: [
                    _SidebarItem(
                      icon: CupertinoIcons.person_fill,
                      label: 'Profile',
                      isSelected: selectedIndex == 5,
                      isCollapsed: isCollapsed,
                      onTap: () => onItemSelected(5),
                    ),
                    _SidebarItem(
                      icon: CupertinoIcons.heart_fill,
                      label: 'Favorites',
                      isSelected: selectedIndex == 6,
                      isCollapsed: isCollapsed,
                      onTap: () => onItemSelected(6),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Settings or Sign Out at bottom (depending on guest mode)
          Padding(
            padding: const EdgeInsets.all(8),
            child: isGuest
                ? _SidebarItem(
                    icon: CupertinoIcons.square_arrow_right,
                    label: 'Sign Out',
                    isSelected: false,
                    isCollapsed: isCollapsed,
                    onTap: () => _handleLogout(context),
                  )
                : _SidebarItem(
                    icon: CupertinoIcons.settings,
                    label: 'Settings',
                    isSelected: selectedIndex == 3,
                    isCollapsed: isCollapsed,
                    onTap: () => onItemSelected(3),
                  ),
          ),
          // Collapse toggle with glass effect
          Padding(
            padding: const EdgeInsets.all(8),
            child: _GlassCollapseButton(
              isCollapsed: isCollapsed,
              onTap: onToggleCollapse,
            ),
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
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? const Color(0xFF3A3A3C).withValues(alpha: 0.3)
                : const Color(0xFFD1D1D6).withValues(alpha: 0.4),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // App icon with liquid glass glow effect
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryBlue.withValues(alpha: 0.9),
                  AppColors.primaryPurple.withValues(alpha: 0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(7),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'K',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (!isCollapsed) ...[
            const SizedBox(width: 10),
            const Text(
              'Klit',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isCollapsed)
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 4, top: 8),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ...children,
      ],
    );
  }
}

/// Individual sidebar navigation item
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
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
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

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final isActive = widget.isSelected || _isHovered;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: EdgeInsets.symmetric(
                horizontal: widget.isCollapsed ? 0 : 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                gradient: isActive
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: widget.isSelected
                            ? [
                                AppColors.primaryBlue.withValues(
                                  alpha: isDark ? 0.3 : 0.2,
                                ),
                                AppColors.primaryBlue.withValues(
                                  alpha: isDark ? 0.2 : 0.15,
                                ),
                              ]
                            : [
                                (isDark
                                        ? const Color(0xFF3A3A3C)
                                        : const Color(0xFFE5E5EA))
                                    .withValues(alpha: 0.5 * _glowAnimation.value),
                                (isDark
                                        ? const Color(0xFF2C2C2E)
                                        : const Color(0xFFF2F2F7))
                                    .withValues(alpha: 0.3 * _glowAnimation.value),
                              ],
                      )
                    : null,
                borderRadius: BorderRadius.circular(8),
                border: widget.isSelected
                    ? Border.all(
                        color: AppColors.primaryBlue.withValues(alpha: 0.3),
                        width: 0.5,
                      )
                    : null,
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
          child: widget.isCollapsed
              ? Center(
                  child: Icon(
                    widget.icon,
                    size: 20,
                    color: widget.isSelected
                        ? AppColors.primaryBlue
                        : CupertinoColors.label.resolveFrom(context),
                  ),
                )
              : Row(
                  children: [
                    Icon(
                      widget.icon,
                      size: 18,
                      color: widget.isSelected
                          ? AppColors.primaryBlue
                          : CupertinoColors.label.resolveFrom(context),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: widget.isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: widget.isSelected
                              ? AppColors.primaryBlue
                              : CupertinoColors.label.resolveFrom(context),
                        ),
                      ),
                    ),
                  ],
                ),
            );
          },
        ),
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isHovered
                  ? [
                      (isDark
                              ? const Color(0xFF3A3A3C)
                              : const Color(0xFFE5E5EA))
                          .withValues(alpha: 0.6),
                      (isDark
                              ? const Color(0xFF2C2C2E)
                              : const Color(0xFFF2F2F7))
                          .withValues(alpha: 0.4),
                    ]
                  : [
                      (isDark
                              ? const Color(0xFF2C2C2E)
                              : const Color(0xFFF2F2F7))
                          .withValues(alpha: 0.4),
                      (isDark
                              ? const Color(0xFF1C1C1E)
                              : const Color(0xFFFFFFFF))
                          .withValues(alpha: 0.3),
                    ],
            ),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF3A3A3C).withValues(alpha: 0.3)
                  : const Color(0xFFD1D1D6).withValues(alpha: 0.4),
              width: 0.5,
            ),
          ),
          child: Icon(
            widget.isCollapsed
                ? CupertinoIcons.sidebar_right
                : CupertinoIcons.sidebar_left,
            size: 18,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      ),
    );
  }
}
