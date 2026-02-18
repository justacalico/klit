import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Tooltip;
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
    0: _NavItemDef(icon: CupertinoIcons.house_fill, label: 'Home', section: 'browse'),
    1: _NavItemDef(icon: CupertinoIcons.flame_fill, label: 'Hot', section: 'browse'),
    2: _NavItemDef(icon: CupertinoIcons.star_fill, label: 'Popular', section: 'browse'),
    4: _NavItemDef(icon: CupertinoIcons.search, label: 'Search', section: 'tools'),
    5: _NavItemDef(icon: CupertinoIcons.person_fill, label: 'Profile', section: 'account'),
    6: _NavItemDef(icon: CupertinoIcons.heart_fill, label: 'Favorites', section: 'account'),
  };
}

class AppSidebar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.isCollapsed = false,
    required this.onToggleCollapse,
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
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
              Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
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
          case 'browse': browse.add(id); break;
          case 'tools': tools.add(id); break;
          case 'account': account.add(id); break;
        }
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: widget.isCollapsed ? 72 : 240,
      child: isLiquidGlass
          ? _buildGlassSidebar(context, isDark, isGuest, browse, tools, account)
          : _buildMaterialSidebar(context, isDark, isGuest, browse, tools, account),
    );
  }

  Widget _buildGlassSidebar(
    BuildContext context,
    bool isDark,
    bool isGuest,
    List<int> browse,
    List<int> tools,
    List<int> account,
  ) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
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
                color: UIColors.primaryPurple.withValues(alpha: isDark ? 0.15 : 0.1),
                width: 1,
              ),
            ),
          ),
          child: _buildContent(context, isDark, isGuest, browse, tools, account),
        ),
      ),
    );
  }

  Widget _buildMaterialSidebar(
    BuildContext context,
    bool isDark,
    bool isGuest,
    List<int> browse,
    List<int> tools,
    List<int> account,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : const Color(0xFFF5F5F7),
        border: Border(
          right: BorderSide(
            color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5E7),
            width: 1,
          ),
        ),
      ),
      child: _buildContent(context, isDark, isGuest, browse, tools, account),
    );
  }

  Widget _buildContent(
    BuildContext context,
    bool isDark,
    bool isGuest,
    List<int> browse,
    List<int> tools,
    List<int> account,
  ) {
    return Column(
      children: [
        _buildHeader(context, isDark),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              if (browse.isNotEmpty) ...[
                _Section(title: 'Browse', isCollapsed: widget.isCollapsed, children: [
                  for (final id in browse)
                    _SidebarItem(
                      icon: _NavItemDef.items[id]!.icon,
                      label: _NavItemDef.items[id]!.label,
                      isSelected: widget.selectedIndex == id,
                      isCollapsed: widget.isCollapsed,
                      onTap: () => widget.onItemSelected(id),
                    ),
                ]),
                const SizedBox(height: 20),
              ],
              if (tools.isNotEmpty) ...[
                _Section(title: 'Tools', isCollapsed: widget.isCollapsed, children: [
                  for (final id in tools)
                    _SidebarItem(
                      icon: _NavItemDef.items[id]!.icon,
                      label: _NavItemDef.items[id]!.label,
                      isSelected: widget.selectedIndex == id,
                      isCollapsed: widget.isCollapsed,
                      onTap: () => widget.onItemSelected(id),
                    ),
                ]),
                const SizedBox(height: 20),
              ],
              if (account.isNotEmpty)
                _Section(title: 'Account', isCollapsed: widget.isCollapsed, children: [
                  for (final id in account)
                    _SidebarItem(
                      icon: _NavItemDef.items[id]!.icon,
                      label: _NavItemDef.items[id]!.label,
                      isSelected: widget.selectedIndex == id,
                      isCollapsed: widget.isCollapsed,
                      onTap: () => widget.onItemSelected(id),
                    ),
                ]),
            ],
          ),
        ),
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
        Padding(
          padding: const EdgeInsets.all(12),
          child: _CollapseButton(
            isCollapsed: widget.isCollapsed,
            onTap: widget.onToggleCollapse,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: UIColors.primaryPurple.withValues(alpha: isDark ? 0.1 : 0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA855F7)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: UIColors.primaryPurple.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text('K', style: TextStyle(color: CupertinoColors.white, fontSize: 20, fontWeight: FontWeight.w700)),
            ),
          ),
          if (!widget.isCollapsed) ...[
            const SizedBox(width: 12),
            Text(
              'Klit',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? CupertinoColors.white : const Color(0xFF1F2937),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool isCollapsed;

  const _Section({required this.title, required this.children, required this.isCollapsed});

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
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
                letterSpacing: 1,
                color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey,
              ),
            ),
          ),
        ...children,
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

class _SidebarItemState extends State<_SidebarItem>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 150), vsync: this);
    _scale = Tween<double>(begin: 1, end: 0.98).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, _) => Transform.scale(
            scale: _scale.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: EdgeInsets.symmetric(horizontal: widget.isCollapsed ? 0 : 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: widget.isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          UIColors.primaryIndigo.withValues(alpha: isDark ? 0.25 : 0.15),
                          UIColors.primaryPurple.withValues(alpha: isDark ? 0.2 : 0.12),
                        ],
                      )
                    : _hovered
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA)).withValues(alpha: 0.6),
                              (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA)).withValues(alpha: 0.4),
                            ],
                          )
                        : null,
                borderRadius: BorderRadius.circular(12),
                border: widget.isSelected
                    ? Border.all(color: UIColors.primaryPurple.withValues(alpha: 0.3), width: 1)
                    : null,
                boxShadow: widget.isSelected
                    ? [BoxShadow(color: UIColors.primaryPurple.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))]
                    : null,
              ),
              child: widget.isCollapsed
                  ? Center(child: _icon(isDark))
                  : Row(
                      children: [
                        _icon(isDark),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: widget.isSelected ? UIColors.primaryPurple : (isDark ? CupertinoColors.white : const Color(0xFF374151)),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _icon(bool isDark) {
    return Container(
      width: 28,
      height: 28,
      decoration: widget.isSelected
          ? BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: UIColors.primaryPurple.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
            )
          : null,
      child: Icon(
        widget.icon,
        size: 16,
        color: widget.isSelected ? CupertinoColors.white : (isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey),
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
            padding: EdgeInsets.symmetric(horizontal: widget.isCollapsed ? 12 : 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: _hovered
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        UIColors.primaryIndigo.withValues(alpha: 0.2),
                        UIColors.primaryPurple.withValues(alpha: 0.15),
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [const Color(0xFF2C2C2E).withValues(alpha: 0.6), const Color(0xFF1C1C1E).withValues(alpha: 0.5)]
                          : [const Color(0xFFF2F2F7).withValues(alpha: 0.8), const Color(0xFFFFFFFF).withValues(alpha: 0.7)],
                    ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hovered ? UIColors.primaryPurple.withValues(alpha: 0.4) : (isDark ? const Color(0xFF3A3A3C).withValues(alpha: 0.4) : const Color(0xFFD1D1D6).withValues(alpha: 0.5)),
                width: 1,
              ),
              boxShadow: _hovered ? [BoxShadow(color: UIColors.primaryPurple.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))] : null,
            ),
            child: widget.isCollapsed
                ? Center(
                    child: AnimatedRotation(
                      turns: widget.isCollapsed ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(CupertinoIcons.sidebar_left, size: 18, color: _hovered ? UIColors.primaryPurple : (isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2)),
                    ),
                  )
                : Row(
                    children: [
                      AnimatedRotation(
                        turns: widget.isCollapsed ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(CupertinoIcons.sidebar_left, size: 18, color: _hovered ? UIColors.primaryPurple : (isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Collapse',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _hovered ? UIColors.primaryPurple : (isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2)),
                        ),
                      ),
                      Icon(CupertinoIcons.chevron_left, size: 14, color: _hovered ? UIColors.primaryPurple.withValues(alpha: 0.7) : CupertinoColors.systemGrey.withValues(alpha: 0.5)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

