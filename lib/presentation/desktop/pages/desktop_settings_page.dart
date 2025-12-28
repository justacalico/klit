import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show Material, ListTile, ReorderableListView;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../../../app/routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/ui_style_manager.dart';
import '../../../data/models/proxy_config.dart';
import '../../providers/providers.dart';

/// Design constants for the settings page
class _DesignColors {
  static const Color primaryIndigo = Color(0xFF6366F1);
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentTeal = Color(0xFF14B8A6);
  static const Color accentOrange = Color(0xFFF97316);
  static const Color accentGreen = Color(0xFF22C55E);
}

/// Settings category definition
class _SettingsCategory {
  final String id;
  final String title;
  final IconData icon;
  final Color color;

  const _SettingsCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
  });
}

/// Desktop settings page with macOS System Preferences-style sidebar design
class DesktopSettingsPage extends StatefulWidget {
  final Function(String) onNavigate;

  const DesktopSettingsPage({super.key, required this.onNavigate});

  @override
  State<DesktopSettingsPage> createState() => _DesktopSettingsPageState();
}

class _DesktopSettingsPageState extends State<DesktopSettingsPage>
    with SingleTickerProviderStateMixin {
  String _selectedCategory = 'account';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _appVersion = '...';

  static const List<_SettingsCategory> _categories = [
    _SettingsCategory(
      id: 'account',
      title: 'Account',
      icon: CupertinoIcons.person_circle_fill,
      color: _DesignColors.primaryPurple,
    ),
    _SettingsCategory(
      id: 'appearance',
      title: 'Appearance',
      icon: CupertinoIcons.paintbrush_fill,
      color: _DesignColors.primaryIndigo,
    ),
    _SettingsCategory(
      id: 'content',
      title: 'Content',
      icon: CupertinoIcons.photo_fill_on_rectangle_fill,
      color: _DesignColors.accentPink,
    ),
    _SettingsCategory(
      id: 'behavior',
      title: 'Behavior',
      icon: CupertinoIcons.sparkles,
      color: _DesignColors.accentOrange,
    ),
    _SettingsCategory(
      id: 'customization',
      title: 'Customization',
      icon: CupertinoIcons.slider_horizontal_3,
      color: _DesignColors.accentTeal,
    ),
    _SettingsCategory(
      id: 'network',
      title: 'Network',
      icon: CupertinoIcons.globe,
      color: _DesignColors.accentGreen,
    ),
    _SettingsCategory(
      id: 'about',
      title: 'About',
      icon: CupertinoIcons.info_circle_fill,
      color: CupertinoColors.systemGrey,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _appVersion = packageInfo.version);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _selectCategory(String id) {
    if (_selectedCategory == id) return;
    _animationController.reverse().then((_) {
      setState(() => _selectedCategory = id);
      _animationController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF0D0D0F) : const Color(0xFFF5F5F7),
      child: Row(
        children: [
          // Sidebar
          _buildSidebar(isDark),
          // Main content
          Expanded(child: _buildMainContent(isDark)),
        ],
      ),
    );
  }

  Widget _buildSidebar(bool isDark) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF18181B).withValues(alpha: 0.8)
            : const Color(0xFFFFFFFF).withValues(alpha: 0.8),
        border: Border(
          right: BorderSide(
            color: isDark
                ? _DesignColors.primaryPurple.withValues(alpha: 0.1)
                : const Color(0xFFE5E5E7),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        _DesignColors.primaryIndigo,
                        _DesignColors.primaryPurple,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: _DesignColors.primaryPurple.withValues(
                          alpha: 0.3,
                        ),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    CupertinoIcons.gear_alt_fill,
                    color: CupertinoColors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? CupertinoColors.white
                        : CupertinoColors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Categories
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category.id;
                return _buildCategoryItem(category, isSelected, isDark);
              },
            ),
          ),
          // Footer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Klit $_appVersion',
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? CupertinoColors.systemGrey
                    : CupertinoColors.systemGrey2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(
    _SettingsCategory category,
    bool isSelected,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: GestureDetector(
        onTap: () => _selectCategory(category.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      category.color.withValues(alpha: 0.2),
                      category.color.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(
                    color: category.color.withValues(alpha: 0.3),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? category.color.withValues(alpha: 0.2)
                      : (isDark
                            ? CupertinoColors.systemGrey.withValues(alpha: 0.2)
                            : CupertinoColors.systemGrey5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  category.icon,
                  size: 16,
                  color: isSelected
                      ? category.color
                      : (isDark
                            ? CupertinoColors.systemGrey
                            : CupertinoColors.systemGrey2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  category.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? (isDark
                              ? CupertinoColors.white
                              : CupertinoColors.black)
                        : (isDark
                              ? CupertinoColors.systemGrey
                              : CupertinoColors.systemGrey2),
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: category.color.withValues(alpha: 0.6),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(bool isDark) {
    final category = _categories.firstWhere((c) => c.id == _selectedCategory);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildContentHeader(category, isDark),
        // Content
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: _buildCategoryContent(isDark),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentHeader(_SettingsCategory category, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? _DesignColors.primaryPurple.withValues(alpha: 0.1)
                : const Color(0xFFE5E5E7),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  category.color.withValues(alpha: 0.2),
                  category.color.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: category.color.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(category.icon, size: 24, color: category.color),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _getCategoryDescription(category.id),
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? CupertinoColors.systemGrey
                      : CupertinoColors.systemGrey2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getCategoryDescription(String id) {
    switch (id) {
      case 'account':
        return 'Manage your account and login';
      case 'appearance':
        return 'Customize the look and feel';
      case 'content':
        return 'Configure content display options';
      case 'behavior':
        return 'Adjust app behavior and animations';
      case 'customization':
        return 'Personalize your experience';
      case 'network':
        return 'Network and proxy settings';
      case 'about':
        return 'About Klit';
      default:
        return '';
    }
  }

  Widget _buildCategoryContent(bool isDark) {
    switch (_selectedCategory) {
      case 'account':
        return _buildAccountContent(isDark);
      case 'appearance':
        return _buildAppearanceContent(isDark);
      case 'content':
        return _buildContentSettings(isDark);
      case 'behavior':
        return _buildBehaviorContent(isDark);
      case 'customization':
        return _buildCustomizationContent(isDark);
      case 'network':
        return _buildNetworkContent(isDark);
      case 'about':
        return _buildAboutContent(isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSettingsCard({
    required bool isDark,
    required Widget child,
    EdgeInsets? padding,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF1C1C1E).withValues(alpha: 0.8),
                      const Color(0xFF2C2C2E).withValues(alpha: 0.6),
                    ]
                  : [
                      const Color(0xFFFFFFFF).withValues(alpha: 0.9),
                      const Color(0xFFF8F8FA).withValues(alpha: 0.8),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? _DesignColors.primaryPurple.withValues(alpha: 0.15)
                  : const Color(0xFFE5E5E7),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? CupertinoColors.black.withValues(alpha: 0.3)
                    : CupertinoColors.systemGrey.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSettingRow({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? CupertinoColors.systemGrey
                            : CupertinoColors.systemGrey2,
                      ),
                    ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        height: 1,
        color: isDark
            ? _DesignColors.primaryPurple.withValues(alpha: 0.1)
            : const Color(0xFFE5E5E7),
      ),
    );
  }

  // ============================================
  // Account Content
  // ============================================
  Widget _buildAccountContent(bool isDark) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final account = authProvider.currentAccount;
        final isGuest = authProvider.isGuest;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingsCard(
              isDark: isDark,
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: isGuest
                              ? LinearGradient(
                                  colors: [
                                    CupertinoColors.systemGrey.withValues(
                                      alpha: 0.3,
                                    ),
                                    CupertinoColors.systemGrey.withValues(
                                      alpha: 0.2,
                                    ),
                                  ],
                                )
                              : const LinearGradient(
                                  colors: [
                                    _DesignColors.primaryIndigo,
                                    _DesignColors.primaryPurple,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: isGuest
                                  ? CupertinoColors.systemGrey.withValues(
                                      alpha: 0.2,
                                    )
                                  : _DesignColors.primaryPurple.withValues(
                                      alpha: 0.3,
                                    ),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: isGuest
                              ? const Icon(
                                  CupertinoIcons.person_badge_plus_fill,
                                  color: CupertinoColors.white,
                                  size: 28,
                                )
                              : Text(
                                  account?.username[0].toUpperCase() ?? '?',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: CupertinoColors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isGuest
                                  ? 'Guest Mode'
                                  : (account?.username ?? 'Not logged in'),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? CupertinoColors.white
                                    : CupertinoColors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isGuest
                                  ? 'Sign in to access all features'
                                  : (account?.host ?? ''),
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? CupertinoColors.systemGrey
                                    : CupertinoColors.systemGrey2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        color: _DesignColors.primaryPurple,
                        borderRadius: BorderRadius.circular(10),
                        onPressed: () {
                          if (isGuest) {
                            authProvider.logout();
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              AppRoutes.login,
                              (route) => false,
                            );
                          } else {
                            widget.onNavigate(AppRoutes.accountManagement);
                          }
                        },
                        child: Text(
                          isGuest ? 'Sign In' : 'Manage',
                          style: const TextStyle(
                            color: CupertinoColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!isGuest) ...[
              const SizedBox(height: 16),
              _buildSettingsCard(
                isDark: isDark,
                child: _buildSettingRow(
                  isDark: isDark,
                  icon: CupertinoIcons.globe,
                  iconColor: _DesignColors.accentTeal,
                  title: 'Server Configuration',
                  subtitle: 'Change API host',
                  trailing: const Icon(
                    CupertinoIcons.chevron_right,
                    size: 16,
                    color: CupertinoColors.systemGrey,
                  ),
                  onTap: () => widget.onNavigate(AppRoutes.hostSettings),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  // ============================================
  // Appearance Content
  // ============================================
  Widget _buildAppearanceContent(bool isDark) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingsCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? CupertinoColors.systemGrey
                          : CupertinoColors.systemGrey2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildThemeOption(
                        isDark: isDark,
                        isSelected: settings.themeMode == 0,
                        icon: CupertinoIcons.device_laptop,
                        label: 'Auto',
                        onTap: () => settings.setThemeMode(0),
                      ),
                      const SizedBox(width: 12),
                      _buildThemeOption(
                        isDark: isDark,
                        isSelected: settings.themeMode == 1,
                        icon: CupertinoIcons.sun_max_fill,
                        label: 'Light',
                        onTap: () => settings.setThemeMode(1),
                      ),
                      const SizedBox(width: 12),
                      _buildThemeOption(
                        isDark: isDark,
                        isSelected: settings.themeMode == 2,
                        icon: CupertinoIcons.moon_fill,
                        label: 'Dark',
                        onTap: () => settings.setThemeMode(2),
                      ),
                      const SizedBox(width: 12),
                      _buildThemeOption(
                        isDark: isDark,
                        isSelected: settings.themeMode == 3,
                        icon: CupertinoIcons.circle_fill,
                        label: 'OLED',
                        onTap: () => settings.setThemeMode(3),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildSettingsCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UI Style',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? CupertinoColors.systemGrey
                          : CupertinoColors.systemGrey2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose between performance-focused Material or beautiful Liquid Glass effects',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? CupertinoColors.systemGrey2
                          : CupertinoColors.systemGrey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildUIStyleOption(
                        isDark: isDark,
                        isSelected: settings.uiStyle == UIStyle.liquidGlass,
                        icon: CupertinoIcons.sparkles,
                        label: 'Liquid Glass',
                        description: 'Beautiful blur effects',
                        onTap: () => settings.setUIStyle(UIStyle.liquidGlass),
                      ),
                      const SizedBox(width: 12),
                      _buildUIStyleOption(
                        isDark: isDark,
                        isSelected: settings.uiStyle == UIStyle.material,
                        icon: CupertinoIcons.bolt_fill,
                        label: 'Material',
                        description: 'Performance-focused',
                        onTap: () => settings.setUIStyle(UIStyle.material),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUIStyleOption({
    required bool isDark,
    required bool isSelected,
    required IconData icon,
    required String label,
    required String description,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [
                      _DesignColors.accentTeal,
                      Color(0xFF0D9488),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected
                ? null
                : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? _DesignColors.accentTeal
                  : (isDark
                        ? _DesignColors.accentTeal.withValues(alpha: 0.1)
                        : const Color(0xFFE5E5E7)),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _DesignColors.accentTeal.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 28,
                color: isSelected
                    ? CupertinoColors.white
                    : (isDark
                          ? CupertinoColors.white.withValues(alpha: 0.7)
                          : CupertinoColors.black.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? CupertinoColors.white
                      : (isDark
                            ? CupertinoColors.white
                            : CupertinoColors.black),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected
                      ? CupertinoColors.white.withValues(alpha: 0.8)
                      : (isDark
                            ? CupertinoColors.systemGrey
                            : CupertinoColors.systemGrey2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required bool isDark,
    required bool isSelected,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [
                      _DesignColors.primaryIndigo,
                      _DesignColors.primaryPurple,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected
                ? null
                : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? _DesignColors.primaryPurple
                  : (isDark
                        ? _DesignColors.primaryPurple.withValues(alpha: 0.1)
                        : const Color(0xFFE5E5E7)),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _DesignColors.primaryPurple.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected
                    ? CupertinoColors.white
                    : (isDark
                          ? CupertinoColors.systemGrey
                          : CupertinoColors.systemGrey2),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? CupertinoColors.white
                      : (isDark
                            ? CupertinoColors.systemGrey
                            : CupertinoColors.systemGrey2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // Content Settings
  // ============================================
  Widget _buildContentSettings(bool isDark) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingsCard(
              isDark: isDark,
              child: Column(
                children: [
                  _buildSettingRow(
                    isDark: isDark,
                    icon: CupertinoIcons.square_grid_2x2_fill,
                    iconColor: _DesignColors.accentPink,
                    title: 'Grid Size',
                    subtitle: 'Number of columns in grid view',
                    trailing: CupertinoSlidingSegmentedControl<int>(
                      groupValue: settings.gridSize,
                      children: const {
                        2: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('2', style: TextStyle(fontSize: 13)),
                        ),
                        3: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('3', style: TextStyle(fontSize: 13)),
                        ),
                        4: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('4', style: TextStyle(fontSize: 13)),
                        ),
                      },
                      onValueChanged: (value) {
                        if (value != null) settings.setGridSize(value);
                      },
                    ),
                  ),
                  _buildDivider(isDark),
                  _buildSettingRow(
                    isDark: isDark,
                    icon: CupertinoIcons.shield_fill,
                    iconColor: _DesignColors.accentGreen,
                    title: 'Safe Mode',
                    subtitle: 'Only show safe-rated content',
                    trailing: CupertinoSwitch(
                      value: settings.safeMode,
                      activeTrackColor: _DesignColors.accentGreen,
                      onChanged: (value) => settings.setSafeMode(value),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================
  // Behavior Content
  // ============================================
  Widget _buildBehaviorContent(bool isDark) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingsCard(
              isDark: isDark,
              child: _buildSettingRow(
                isDark: isDark,
                icon: CupertinoIcons.sparkles,
                iconColor: _DesignColors.accentOrange,
                title: 'Confetti on Favorite',
                subtitle: 'Show celebration animation when favoriting',
                trailing: CupertinoSwitch(
                  value: settings.confettiOnFavorite,
                  activeTrackColor: _DesignColors.accentOrange,
                  onChanged: (value) => settings.setConfettiOnFavorite(value),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================
  // Customization Content
  // ============================================
  Widget _buildCustomizationContent(bool isDark) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingsCard(
              isDark: isDark,
              child: _buildSettingRow(
                isDark: isDark,
                icon: CupertinoIcons.sidebar_left,
                iconColor: _DesignColors.accentTeal,
                title: 'Sidebar Order',
                subtitle: 'Customize the order of sidebar items',
                trailing: CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: _DesignColors.accentTeal.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  onPressed: () =>
                      _showDesktopNavOrderDialog(context, settings, isDark),
                  child: const Text(
                    'Configure',
                    style: TextStyle(
                      color: _DesignColors.accentTeal,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDesktopNavOrderDialog(
    BuildContext context,
    SettingsProvider settings,
    bool isDark,
  ) {
    final navItems = <int, Map<String, dynamic>>{
      0: {'icon': CupertinoIcons.house_fill, 'label': 'Home'},
      1: {'icon': CupertinoIcons.flame_fill, 'label': 'Hot'},
      2: {'icon': CupertinoIcons.star_fill, 'label': 'Popular'},
      4: {'icon': CupertinoIcons.search, 'label': 'Search'},
      5: {'icon': CupertinoIcons.person_fill, 'label': 'Profile'},
      6: {'icon': CupertinoIcons.heart_fill, 'label': 'Favorites'},
    };

    List<int> currentOrder = List.from(settings.desktopNavOrder);

    showCupertinoDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return CupertinoAlertDialog(
            title: const Text('Sidebar Order'),
            content: SizedBox(
              width: 300,
              height: 350,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Drag to reorder sidebar items',
                    style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Material(
                      color: CupertinoColors.transparent,
                      child: ReorderableListView.builder(
                        shrinkWrap: true,
                        itemCount: currentOrder.length,
                        onReorder: (oldIndex, newIndex) {
                          setDialogState(() {
                            if (newIndex > oldIndex) newIndex--;
                            final item = currentOrder.removeAt(oldIndex);
                            currentOrder.insert(newIndex, item);
                          });
                        },
                        itemBuilder: (context, index) {
                          final itemId = currentOrder[index];
                          final item = navItems[itemId]!;
                          return Container(
                            key: ValueKey(itemId),
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2C2C2E)
                                  : const Color(0xFFF2F2F7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              dense: true,
                              leading: Icon(
                                item['icon'] as IconData,
                                color: _DesignColors.primaryPurple,
                                size: 20,
                              ),
                              title: Text(
                                item['label'] as String,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () {
                  setDialogState(() {
                    currentOrder = [0, 1, 2, 4, 5, 6];
                  });
                },
                child: const Text('Reset'),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () {
                  settings.setDesktopNavOrder(currentOrder);
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================
  // Network Content
  // ============================================
  Widget _buildNetworkContent(bool isDark) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final proxyConfig = settings.proxyConfig;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingsCard(
              isDark: isDark,
              child: Column(
                children: [
                  _buildSettingRow(
                    isDark: isDark,
                    icon: CupertinoIcons.link,
                    iconColor: _DesignColors.accentGreen,
                    title: 'API Host',
                    subtitle: settings.host,
                    trailing: CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: _DesignColors.accentGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      onPressed: () =>
                          widget.onNavigate(AppRoutes.hostSettings),
                      child: const Text(
                        'Configure',
                        style: TextStyle(
                          color: _DesignColors.accentGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  _buildDivider(isDark),
                  _buildSettingRow(
                    isDark: isDark,
                    icon: CupertinoIcons.arrow_right_arrow_left,
                    iconColor: _DesignColors.primaryIndigo,
                    title: 'HTTP Proxy',
                    subtitle: proxyConfig.enabled
                        ? '${proxyConfig.host}:${proxyConfig.port}'
                        : 'Disabled',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CupertinoSwitch(
                          value: proxyConfig.enabled,
                          activeTrackColor: _DesignColors.primaryIndigo,
                          onChanged: (value) => settings.setProxyEnabled(value),
                        ),
                        const SizedBox(width: 8),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          color: _DesignColors.primaryIndigo.withValues(
                            alpha: 0.2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          onPressed: () =>
                              _showProxySettingsDialog(context, isDark),
                          child: const Text(
                            'Edit',
                            style: TextStyle(
                              color: _DesignColors.primaryIndigo,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showProxySettingsDialog(BuildContext context, bool isDark) {
    final settings = context.read<SettingsProvider>();
    final proxyConfig = settings.proxyConfig;

    final hostController = TextEditingController(text: proxyConfig.host);
    final portController = TextEditingController(
      text: proxyConfig.port > 0 ? proxyConfig.port.toString() : '8080',
    );
    final usernameController = TextEditingController(
      text: proxyConfig.username ?? '',
    );
    final passwordController = TextEditingController(
      text: proxyConfig.password ?? '',
    );
    bool useAuth = proxyConfig.useAuthentication;

    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => CupertinoAlertDialog(
          title: const Text('Proxy Settings'),
          content: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoTextField(
                  controller: hostController,
                  placeholder: 'Proxy Host (e.g., 127.0.0.1)',
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2C2C2E)
                        : CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 12),
                CupertinoTextField(
                  controller: portController,
                  placeholder: 'Port (e.g., 8080)',
                  keyboardType: TextInputType.number,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2C2C2E)
                        : CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Use Authentication',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? CupertinoColors.white
                              : CupertinoColors.black,
                        ),
                      ),
                    ),
                    CupertinoSwitch(
                      value: useAuth,
                      onChanged: (value) => setState(() => useAuth = value),
                    ),
                  ],
                ),
                if (useAuth) ...[
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: usernameController,
                    placeholder: 'Username',
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2C2C2E)
                          : CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: passwordController,
                    placeholder: 'Password',
                    obscureText: true,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2C2C2E)
                          : CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                final host = hostController.text.trim();
                final port = int.tryParse(portController.text.trim()) ?? 8080;
                final username = usernameController.text.trim();
                final password = passwordController.text;

                settings.setProxyConfig(
                  ProxyConfig(
                    enabled: proxyConfig.enabled,
                    host: host,
                    port: port,
                    useAuthentication: useAuth,
                    username: useAuth ? username : null,
                    password: useAuth ? password : null,
                  ),
                );
                Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // About Content
  // ============================================
  Widget _buildAboutContent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSettingsCard(
          isDark: isDark,
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      _DesignColors.primaryIndigo,
                      _DesignColors.primaryPurple,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _DesignColors.primaryPurple.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'K',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Version $_appVersion',
                style: TextStyle(
                  fontSize: 15,
                  color: isDark
                      ? CupertinoColors.systemGrey
                      : CupertinoColors.systemGrey2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'A beautiful e926-compatible client built with Flutter.\nDesigned for an exceptional browsing experience.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark
                      ? CupertinoColors.systemGrey
                      : CupertinoColors.systemGrey2,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildAboutBadge(
                    isDark: isDark,
                    icon: CupertinoIcons.heart_fill,
                    label: 'Made with Flutter',
                    color: _DesignColors.accentPink,
                  ),
                  const SizedBox(width: 12),
                  _buildAboutBadge(
                    isDark: isDark,
                    icon: CupertinoIcons.sparkles,
                    label: 'Open Source',
                    color: _DesignColors.accentOrange,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutBadge({
    required bool isDark,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
