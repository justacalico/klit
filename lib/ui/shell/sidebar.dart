import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider, Tooltip;
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/theme/ui_style_manager.dart';
import '../../providers/providers.dart';
import '../theme.dart';

class _NavItemDef {
  final IconData icon;
  final String label;
  final String section;

  const _NavItemDef({
    required this.icon,
    required this.label,
    required this.section,
  });

  static const Map<int, _NavItemDef> items = {
    0: _NavItemDef(
      icon: CupertinoIcons.house_fill,
      label: 'Home',
      section: 'browse',
    ),
    1: _NavItemDef(
      icon: CupertinoIcons.flame_fill,
      label: 'Hot',
      section: 'browse',
    ),
    2: _NavItemDef(
      icon: CupertinoIcons.star_fill,
      label: 'Popular',
      section: 'browse',
    ),
    4: _NavItemDef(
      icon: CupertinoIcons.search,
      label: 'Search',
      section: 'tools',
    ),
    5: _NavItemDef(
      icon: CupertinoIcons.person_fill,
      label: 'Profile',
      section: 'account',
    ),
    6: _NavItemDef(
      icon: CupertinoIcons.heart_fill,
      label: 'Favorites',
      section: 'account',
    ),
  };
}

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.isCollapsed = false,
    required this.onToggleCollapse,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  void _handleLogout(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of guest mode?'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AuthProvider>().logout();
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
            },
            child: const Text('Sign Out'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
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
    final navOrder = context.watch<SettingsProvider>().desktopNavOrder;
    final isLiquidGlass = UIStyleManager.isLiquidGlass(context);

    final browse = <int>[];
    final tools = <int>[];
    final account = <int>[];

    for (final id in navOrder) {
      final item = _NavItemDef.items[id];
      if (item != null) {
        switch (item.section) {
          case 'browse':
            browse.add(id);
            break;
          case 'tools':
            tools.add(id);
            break;
          case 'account':
            account.add(id);
            break;
        }
      }
    }

    final bgColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 60,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 12 : 16,
              vertical: 12,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [UIColors.primaryIndigo, UIColors.primaryPurple],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'K',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Text(
                    'Klit',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? CupertinoColors.white
                          : const Color(0xFF1C1C1E),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (browse.isNotEmpty)
                  _buildSection(context, 'Browse', browse, isDark),
                if (tools.isNotEmpty)
                  _buildSection(context, 'Tools', tools, isDark),
                if (account.isNotEmpty)
                  _buildSection(context, 'Account', account, isDark),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
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
              : Column(
                  children: [
                    _SidebarItem(
                      icon: CupertinoIcons.settings,
                      label: 'Settings',
                      isSelected: selectedIndex == 3,
                      isCollapsed: isCollapsed,
                      onTap: () => onItemSelected(3),
                    ),
                    const SizedBox(height: 4),
                    _CollapseButton(
                      isCollapsed: isCollapsed,
                      onTap: onToggleCollapse,
                    ),
                  ],
                ),
        ),
      ],
    );

    final child = isLiquidGlass
        ? ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                color: bgColor.withValues(alpha: 0.8),
                child: content,
              ),
            ),
          )
        : ColoredBox(color: bgColor, child: content);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isCollapsed ? 72 : 240,
      child: child,
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<int> ids,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isCollapsed)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? CupertinoColors.systemGrey
                    : CupertinoColors.systemGrey2,
              ),
            ),
          ),
        for (final id in ids)
          _SidebarItem(
            icon: _NavItemDef.items[id]!.icon,
            label: _NavItemDef.items[id]!.label,
            isSelected: selectedIndex == id,
            isCollapsed: isCollapsed,
            onTap: () => onItemSelected(id),
          ),
      ],
    );
  }
}

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

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    return Tooltip(
      message: widget.isCollapsed ? widget.label : '',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                        UIColors.primaryIndigo.withValues(
                          alpha: isDark ? 0.25 : 0.15,
                        ),
                        UIColors.primaryPurple.withValues(
                          alpha: isDark ? 0.2 : 0.12,
                        ),
                      ],
                    )
                  : _hovered
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
                      color: UIColors.primaryPurple.withValues(alpha: 0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: widget.isCollapsed
                ? Center(child: Icon(widget.icon, size: 16))
                : Row(
                    children: [
                      Icon(
                        widget.icon,
                        size: 16,
                        color: widget.isSelected
                            ? CupertinoColors.white
                            : (isDark
                                  ? CupertinoColors.systemGrey
                                  : CupertinoColors.systemGrey2),
                      ),
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
                                ? UIColors.primaryPurple
                                : (isDark
                                      ? CupertinoColors.white
                                      : const Color(0xFF374151)),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _CollapseButton extends StatefulWidget {
  final bool isCollapsed;
  final VoidCallback onTap;

  const _CollapseButton({required this.isCollapsed, required this.onTap});

  @override
  State<_CollapseButton> createState() => _CollapseButtonState();
}

class _CollapseButtonState extends State<_CollapseButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    return Tooltip(
      message: widget.isCollapsed ? 'Expand sidebar' : 'Collapse sidebar',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _hovered
                  ? UIColors.primaryPurple.withValues(alpha: 0.1)
                  : (isDark
                        ? const Color(0xFF2C2C2E).withValues(alpha: 0.6)
                        : const Color(0xFFF2F2F7).withValues(alpha: 0.8)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hovered
                    ? UIColors.primaryPurple.withValues(alpha: 0.4)
                    : const Color(0x00000000),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.sidebar_left,
                  size: 18,
                  color: _hovered
                      ? UIColors.primaryPurple
                      : (isDark
                            ? CupertinoColors.systemGrey
                            : CupertinoColors.systemGrey2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Collapse',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _hovered
                          ? UIColors.primaryPurple
                          : (isDark
                                ? CupertinoColors.systemGrey
                                : CupertinoColors.systemGrey2),
                    ),
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_left,
                  size: 14,
                  color: _hovered
                      ? UIColors.primaryPurple.withValues(alpha: 0.7)
                      : CupertinoColors.systemGrey.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
