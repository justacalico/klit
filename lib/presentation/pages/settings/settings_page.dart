import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/routes.dart';
import '../../../core/constants/constants.dart';
import '../../providers/providers.dart';

/// Settings page with iOS 26 liquid glass design
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark
          ? AppColors.darkGroupedBackground
          : AppColors.lightGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Settings'),
        backgroundColor: isDark
            ? CupertinoColors.black.withValues(alpha: 0.5)
            : CupertinoColors.white.withValues(alpha: 0.5),
      ),
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            const SizedBox(height: 20),
            _buildAccountSection(context, isDark),
            const SizedBox(height: 24),
            _buildAppearanceSection(context, isDark),
            const SizedBox(height: 24),
            _buildCacheSection(context, isDark),
            const SizedBox(height: 24),
            _buildAboutSection(context, isDark),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context, bool isDark) {
    return _buildLiquidGlassSection(
      context,
      isDark: isDark,
      title: 'ACCOUNT',
      children: [
        Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return _buildLiquidGlassTile(
              context,
              isDark: isDark,
              icon: CupertinoIcons.person_circle,
              iconColor: AppColors.primaryBlue,
              title: auth.currentAccount?.username ?? 'Not logged in',
              subtitle: auth.currentAccount?.host ?? '',
              showChevron: true,
              onTap: () => Navigator.of(context).pushNamed(
                AppRoutes.accountManagement,
              ),
            );
          },
        ),
        _buildLiquidGlassDivider(isDark),
        _buildLiquidGlassTile(
          context,
          isDark: isDark,
          icon: CupertinoIcons.globe,
          iconColor: AppColors.primaryGreen,
          title: 'Server Configuration',
          showChevron: true,
          onTap: () => Navigator.of(context).pushNamed(
            AppRoutes.hostSettings,
          ),
        ),
      ],
    );
  }

  Widget _buildAppearanceSection(BuildContext context, bool isDark) {
    return _buildLiquidGlassSection(
      context,
      isDark: isDark,
      title: 'APPEARANCE',
      children: [
        Consumer<SettingsProvider>(
          builder: (context, settings, _) {
            final themeNames = ['Auto', 'Light', 'Dark', 'OLED'];
            return _buildLiquidGlassTile(
              context,
              isDark: isDark,
              icon: CupertinoIcons.moon_fill,
              iconColor: AppColors.primaryPurple,
              title: 'Theme',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    themeNames[settings.themeMode],
                    style: TextStyle(
                      color: isDark
                          ? CupertinoColors.white.withValues(alpha: 0.6)
                          : CupertinoColors.black.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    CupertinoIcons.chevron_right,
                    size: 16,
                    color: isDark
                        ? CupertinoColors.white.withValues(alpha: 0.3)
                        : CupertinoColors.black.withValues(alpha: 0.25),
                  ),
                ],
              ),
              onTap: () => _showThemePicker(context, settings, isDark),
            );
          },
        ),
        _buildLiquidGlassDivider(isDark),
        Consumer<SettingsProvider>(
          builder: (context, settings, _) {
            return _buildLiquidGlassTile(
              context,
              isDark: isDark,
              icon: CupertinoIcons.square_grid_2x2_fill,
              iconColor: AppColors.primaryOrange,
              title: 'Grid Size',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildGlassButton(
                    isDark: isDark,
                    icon: CupertinoIcons.minus,
                    onTap: settings.gridSize > AppConstants.minGridColumns
                        ? () => settings.setGridSize(settings.gridSize - 1)
                        : null,
                  ),
                  Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: Text(
                      '${settings.gridSize}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: isDark ? CupertinoColors.white : CupertinoColors.black,
                      ),
                    ),
                  ),
                  _buildGlassButton(
                    isDark: isDark,
                    icon: CupertinoIcons.plus,
                    onTap: settings.gridSize < AppConstants.maxGridColumns
                        ? () => settings.setGridSize(settings.gridSize + 1)
                        : null,
                  ),
                ],
              ),
            );
          },
        ),
        _buildLiquidGlassDivider(isDark),
        Consumer<SettingsProvider>(
          builder: (context, settings, _) {
            return _buildLiquidGlassTile(
              context,
              isDark: isDark,
              icon: CupertinoIcons.shield_fill,
              iconColor: AppColors.safeColor,
              title: 'Safe Mode',
              subtitle: 'Only show safe-rated content',
              trailing: CupertinoSwitch(
                value: settings.safeMode,
                activeTrackColor: AppColors.safeColor,
                onChanged: (value) => settings.setSafeMode(value),
              ),
            );
          },
        ),
        _buildLiquidGlassDivider(isDark),
        Consumer<SettingsProvider>(
          builder: (context, settings, _) {
            return _buildLiquidGlassTile(
              context,
              isDark: isDark,
              icon: CupertinoIcons.hand_draw_fill,
              iconColor: AppColors.primaryPink,
              title: 'Left Handed Mode',
              subtitle: 'Swap UI elements for left-handed use',
              trailing: CupertinoSwitch(
                value: settings.leftHandedMode,
                activeTrackColor: AppColors.primaryGreen,
                onChanged: (value) => settings.setLeftHandedMode(value),
              ),
            );
          },
        ),
        _buildLiquidGlassDivider(isDark),
        Consumer<SettingsProvider>(
          builder: (context, settings, _) {
            return _buildLiquidGlassTile(
              context,
              isDark: isDark,
              icon: CupertinoIcons.heart_fill,
              iconColor: AppColors.primaryRed,
              title: 'Upvote When Favorited',
              subtitle: 'Automatically upvote when adding to favorites',
              trailing: CupertinoSwitch(
                value: settings.upvoteWhenFavorited,
                activeTrackColor: AppColors.primaryGreen,
                onChanged: (value) => settings.setUpvoteWhenFavorited(value),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCacheSection(BuildContext context, bool isDark) {
    return _buildLiquidGlassSection(
      context,
      isDark: isDark,
      title: 'DATA',
      children: [
        Consumer<SettingsProvider>(
          builder: (context, settings, _) {
            return _buildLiquidGlassTile(
              context,
              isDark: isDark,
              icon: CupertinoIcons.clock_fill,
              iconColor: AppColors.primaryTeal,
              title: 'Search History',
              subtitle: '${settings.searchHistory.length} items',
              trailing: GestureDetector(
                onTap: settings.searchHistory.isEmpty
                    ? null
                    : () => _confirmClearHistory(context, settings),
                child: Text(
                  'Clear',
                  style: TextStyle(
                    color: settings.searchHistory.isEmpty
                        ? CupertinoColors.systemGrey
                        : CupertinoColors.destructiveRed,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          },
        ),
        _buildLiquidGlassDivider(isDark),
        _buildLiquidGlassTile(
          context,
          isDark: isDark,
          icon: CupertinoIcons.trash_fill,
          iconColor: CupertinoColors.destructiveRed,
          title: 'Clear Image Cache',
          showChevron: true,
          onTap: () => _confirmClearCache(context),
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context, bool isDark) {
    return _buildLiquidGlassSection(
      context,
      isDark: isDark,
      title: 'ABOUT',
      children: [
        _buildLiquidGlassTile(
          context,
          isDark: isDark,
          icon: CupertinoIcons.info_circle_fill,
          iconColor: AppColors.primaryBlue,
          title: 'Version',
          trailing: Text(
            AppConstants.appVersion,
            style: TextStyle(
              color: isDark
                  ? CupertinoColors.white.withValues(alpha: 0.5)
                  : CupertinoColors.black.withValues(alpha: 0.4),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        _buildLiquidGlassDivider(isDark),
        _buildLiquidGlassTile(
          context,
          isDark: isDark,
          icon: CupertinoIcons.globe,
          iconColor: AppColors.primaryOrange,
          title: 'Website',
          showChevron: true,
          onTap: () => _openWebsite(),
        ),
        _buildLiquidGlassDivider(isDark),
        _buildLiquidGlassTile(
          context,
          isDark: isDark,
          icon: CupertinoIcons.doc_text_fill,
          iconColor: AppColors.primaryGreen,
          title: 'Terms of Service',
          showChevron: true,
          onTap: () => _showTermsOfService(context, isDark),
        ),
        _buildLiquidGlassDivider(isDark),
        _buildLiquidGlassTile(
          context,
          isDark: isDark,
          icon: CupertinoIcons.lock_shield_fill,
          iconColor: AppColors.primaryPurple,
          title: 'Privacy Policy',
          showChevron: true,
          onTap: () => _showPrivacyPolicy(context, isDark),
        ),
      ],
    );
  }

  Future<void> _openWebsite() async {
    final uri = Uri.parse('https://openlyst.onrender.com/');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildLiquidGlassSection(
    BuildContext context, {
    required bool isDark,
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: isDark
                  ? CupertinoColors.white.withValues(alpha: 0.5)
                  : CupertinoColors.black.withValues(alpha: 0.4),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            CupertinoColors.white.withValues(alpha: 0.14),
                            CupertinoColors.white.withValues(alpha: 0.08),
                          ]
                        : [
                            CupertinoColors.white.withValues(alpha: 0.8),
                            CupertinoColors.white.withValues(alpha: 0.6),
                          ],
                  ),
                  border: Border.all(
                    color: isDark
                        ? CupertinoColors.white.withValues(alpha: 0.15)
                        : CupertinoColors.white.withValues(alpha: 0.5),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? CupertinoColors.black.withValues(alpha: 0.3)
                          : CupertinoColors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(children: children),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLiquidGlassTile(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    bool showChevron = false,
    VoidCallback? onTap,
  }) {
    final textColor = isDark ? CupertinoColors.white : CupertinoColors.black;
    final subtitleColor = isDark
        ? CupertinoColors.white.withValues(alpha: 0.5)
        : CupertinoColors.black.withValues(alpha: 0.5);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Icon with glass effect
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, size: 18, color: CupertinoColors.white),
            ),
            const SizedBox(width: 14),
            // Title and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Trailing widget
            if (trailing != null) trailing,
            if (showChevron)
              Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: isDark
                    ? CupertinoColors.white.withValues(alpha: 0.3)
                    : CupertinoColors.black.withValues(alpha: 0.25),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiquidGlassDivider(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(left: 62),
      height: 0.5,
      color: isDark
          ? CupertinoColors.white.withValues(alpha: 0.1)
          : CupertinoColors.black.withValues(alpha: 0.08),
    );
  }

  Widget _buildGlassButton({
    required bool isDark,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isDark
              ? CupertinoColors.white.withValues(alpha: isEnabled ? 0.15 : 0.05)
              : CupertinoColors.black.withValues(alpha: isEnabled ? 0.08 : 0.03),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isDark
              ? CupertinoColors.white.withValues(alpha: isEnabled ? 0.9 : 0.3)
              : CupertinoColors.black.withValues(alpha: isEnabled ? 0.8 : 0.25),
        ),
      ),
    );
  }

  void _confirmClearHistory(BuildContext context, SettingsProvider settings) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Clear Search History'),
        content: const Text('Are you sure you want to clear your search history?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              settings.clearSearchHistory();
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _confirmClearCache(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Clear Image Cache'),
        content: const Text('This will remove all cached images.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              // Clear cache logic would go here
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showThemePicker(BuildContext context, SettingsProvider settings, bool isDark) {
    final themes = [
      ('Auto', 'Follow system settings', CupertinoIcons.device_phone_portrait),
      ('Light', 'Always use light theme', CupertinoIcons.sun_max_fill),
      ('Dark', 'Standard dark theme', CupertinoIcons.moon_fill),
      ('OLED', 'Pure black for AMOLED screens', CupertinoIcons.moon_stars_fill),
    ];

    showCupertinoModalPopup(
      context: context,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        CupertinoColors.white.withValues(alpha: 0.16),
                        CupertinoColors.white.withValues(alpha: 0.10),
                      ]
                    : [
                        CupertinoColors.white.withValues(alpha: 0.9),
                        CupertinoColors.white.withValues(alpha: 0.75),
                      ],
              ),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? CupertinoColors.white.withValues(alpha: 0.2)
                      : CupertinoColors.white.withValues(alpha: 0.6),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark
                          ? CupertinoColors.white.withValues(alpha: 0.3)
                          : CupertinoColors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  // Title
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Choose Theme',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? CupertinoColors.white : CupertinoColors.black,
                      ),
                    ),
                  ),
                  // Theme options
                  ...List.generate(themes.length, (index) {
                    final (name, description, icon) = themes[index];
                    final isSelected = settings.themeMode == index;
                    return GestureDetector(
                      onTap: () {
                        settings.setThemeMode(index);
                        Navigator.of(context).pop();
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark
                                  ? AppColors.primaryBlue.withValues(alpha: 0.3)
                                  : AppColors.primaryBlue.withValues(alpha: 0.15))
                              : (isDark
                                  ? CupertinoColors.white.withValues(alpha: 0.08)
                                  : CupertinoColors.black.withValues(alpha: 0.04)),
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(
                                  color: AppColors.primaryBlue.withValues(alpha: 0.5),
                                  width: 1.5,
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              icon,
                              size: 24,
                              color: isSelected
                                  ? AppColors.primaryBlue
                                  : (isDark
                                      ? CupertinoColors.white.withValues(alpha: 0.7)
                                      : CupertinoColors.black.withValues(alpha: 0.6)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? AppColors.primaryBlue
                                          : (isDark
                                              ? CupertinoColors.white
                                              : CupertinoColors.black),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    description,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? CupertinoColors.white.withValues(alpha: 0.5)
                                          : CupertinoColors.black.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                CupertinoIcons.checkmark_circle_fill,
                                size: 24,
                                color: AppColors.primaryBlue,
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
