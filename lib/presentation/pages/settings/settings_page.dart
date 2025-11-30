import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider;
import 'package:provider/provider.dart';
import '../../../app/routes.dart';
import '../../../core/constants/constants.dart';
import '../../providers/providers.dart';

/// Settings page
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
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Settings'),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 20),
            _buildAccountSection(context),
            const SizedBox(height: 20),
            _buildAppearanceSection(context),
            const SizedBox(height: 20),
            _buildCacheSection(context),
            const SizedBox(height: 20),
            _buildAboutSection(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'ACCOUNT',
      children: [
        Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return _buildListTile(
              context,
              icon: CupertinoIcons.person_circle,
              iconColor: AppColors.primaryBlue,
              title: auth.currentAccount?.username ?? 'Not logged in',
              subtitle: auth.currentAccount?.host ?? '',
              trailing: const CupertinoListTileChevron(),
              onTap: () => Navigator.of(context).pushNamed(
                AppRoutes.accountManagement,
              ),
            );
          },
        ),
        _buildDivider(),
        _buildListTile(
          context,
          icon: CupertinoIcons.globe,
          iconColor: AppColors.primaryGreen,
          title: 'Server Configuration',
          trailing: const CupertinoListTileChevron(),
          onTap: () => Navigator.of(context).pushNamed(
            AppRoutes.hostSettings,
          ),
        ),
      ],
    );
  }

  Widget _buildAppearanceSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'APPEARANCE',
      children: [
        Consumer<SettingsProvider>(
          builder: (context, settings, _) {
            return _buildListTile(
              context,
              icon: CupertinoIcons.moon,
              iconColor: AppColors.primaryPurple,
              title: 'Theme',
              trailing: CupertinoSlidingSegmentedControl<int>(
                groupValue: settings.themeMode,
                children: const {
                  0: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('Auto', style: TextStyle(fontSize: 13)),
                  ),
                  1: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('Light', style: TextStyle(fontSize: 13)),
                  ),
                  2: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('Dark', style: TextStyle(fontSize: 13)),
                  ),
                },
                onValueChanged: (value) {
                  if (value != null) {
                    settings.setThemeMode(value);
                  }
                },
              ),
            );
          },
        ),
        _buildDivider(),
        Consumer<SettingsProvider>(
          builder: (context, settings, _) {
            return _buildListTile(
              context,
              icon: CupertinoIcons.square_grid_2x2,
              iconColor: AppColors.primaryOrange,
              title: 'Grid Size',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: settings.gridSize > AppConstants.minGridColumns
                        ? () => settings.setGridSize(settings.gridSize - 1)
                        : null,
                    child: const Icon(CupertinoIcons.minus_circle, size: 24),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${settings.gridSize}',
                      style: const TextStyle(fontSize: 17),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: settings.gridSize < AppConstants.maxGridColumns
                        ? () => settings.setGridSize(settings.gridSize + 1)
                        : null,
                    child: const Icon(CupertinoIcons.plus_circle, size: 24),
                  ),
                ],
              ),
            );
          },
        ),
        _buildDivider(),
        Consumer<SettingsProvider>(
          builder: (context, settings, _) {
            return _buildListTile(
              context,
              icon: CupertinoIcons.shield,
              iconColor: AppColors.safeColor,
              title: 'Safe Mode',
              subtitle: 'Only show safe-rated content',
              trailing: CupertinoSwitch(
                value: settings.safeMode,
                onChanged: (value) => settings.setSafeMode(value),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCacheSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'DATA',
      children: [
        Consumer<SettingsProvider>(
          builder: (context, settings, _) {
            return _buildListTile(
              context,
              icon: CupertinoIcons.clock,
              iconColor: AppColors.primaryTeal,
              title: 'Search History',
              subtitle: '${settings.searchHistory.length} items',
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: settings.searchHistory.isEmpty
                    ? null
                    : () => _confirmClearHistory(context, settings),
                child: const Text(
                  'Clear',
                  style: TextStyle(color: CupertinoColors.destructiveRed),
                ),
              ),
            );
          },
        ),
        _buildDivider(),
        _buildListTile(
          context,
          icon: CupertinoIcons.trash,
          iconColor: CupertinoColors.destructiveRed,
          title: 'Clear Image Cache',
          onTap: () => _confirmClearCache(context),
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'ABOUT',
      children: [
        _buildListTile(
          context,
          icon: CupertinoIcons.info_circle,
          iconColor: AppColors.primaryBlue,
          title: 'Version',
          trailing: Text(
            AppConstants.appVersion,
            style: TextStyle(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ),
        _buildDivider(),
        _buildListTile(
          context,
          icon: CupertinoIcons.doc_text,
          iconColor: AppColors.primaryGreen,
          title: 'Terms of Service',
          trailing: const CupertinoListTileChevron(),
          onTap: () {},
        ),
        _buildDivider(),
        _buildListTile(
          context,
          icon: CupertinoIcons.lock_shield,
          iconColor: AppColors.primaryPurple,
          title: 'Privacy Policy',
          trailing: const CupertinoListTileChevron(),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSecondaryBackground
                : CupertinoColors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return CupertinoListTile(
      leading: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: iconColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 18, color: CupertinoColors.white),
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.only(left: 54),
      child: Divider(height: 1),
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
}
