import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ListTile, Material, ReorderableListView;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/routes.dart';
import '../../../core/constants/constants.dart';
import '../../providers/providers.dart';

/// Design constants for the purple/indigo mobile theme
class _ThemeColors {
  static const Color primaryIndigo = Color(0xFF6366F1);
  static const Color primaryPurple = Color(0xFF8B5CF6);
}

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
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            transitionBetweenRoutes: false,
            backgroundColor: isDark
                ? const Color(0xFF1C1C1E).withValues(alpha: 0.85)
                : CupertinoColors.white.withValues(alpha: 0.85),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? _ThemeColors.primaryPurple.withValues(alpha: 0.15)
                    : _ThemeColors.primaryPurple.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
            middle: Text(
              'Settings',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
            largeTitle: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _ThemeColors.primaryIndigo,
                        _ThemeColors.primaryPurple,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: _ThemeColors.primaryPurple.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    CupertinoIcons.gear_solid,
                    size: 16,
                    color: CupertinoColors.white,
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Settings'),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 20),
                _buildAccountSection(context, isDark),
                const SizedBox(height: 24),
                _buildAppearanceSection(context, isDark),
                const SizedBox(height: 24),
                _buildCustomizationSection(context, isDark),
                const SizedBox(height: 24),
                _buildNetworkSection(context, isDark),
                const SizedBox(height: 24),
                _buildCacheSection(context, isDark),
                const SizedBox(height: 24),
                _buildAboutSection(context, isDark),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context, bool isDark) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // Guest mode - show login prompt
        if (auth.isGuest) {
          return _buildLiquidGlassSection(
            context,
            isDark: isDark,
            title: 'ACCOUNT',
            children: [
              _buildLiquidGlassTile(
                context,
                isDark: isDark,
                icon: CupertinoIcons.person_badge_plus,
                iconColor: AppColors.primaryBlue,
                title: 'Sign In',
                subtitle: 'Sign in to access all features',
                showChevron: true,
                onTap: () {
                  auth.logout(); // Clear guest state
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
                },
              ),
            ],
          );
        }

        // Logged in - show account management
        return _buildLiquidGlassSection(
          context,
          isDark: isDark,
          title: 'ACCOUNT',
          children: [
            _buildLiquidGlassTile(
              context,
              isDark: isDark,
              icon: CupertinoIcons.person_circle,
              iconColor: AppColors.primaryBlue,
              title: auth.currentAccount?.username ?? 'Not logged in',
              subtitle: auth.currentAccount?.host ?? '',
              showChevron: true,
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.accountManagement),
            ),
            _buildLiquidGlassDivider(isDark),
            _buildLiquidGlassTile(
              context,
              isDark: isDark,
              icon: CupertinoIcons.globe,
              iconColor: AppColors.primaryGreen,
              title: 'Server Configuration',
              showChevron: true,
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.hostSettings),
            ),
          ],
        );
      },
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
                        color: isDark
                            ? CupertinoColors.white
                            : CupertinoColors.black,
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
        _buildLiquidGlassDivider(isDark),
        Consumer<SettingsProvider>(
          builder: (context, settings, _) {
            return _buildLiquidGlassTile(
              context,
              isDark: isDark,
              icon: CupertinoIcons.sparkles,
              iconColor: AppColors.primaryPink,
              title: 'Confetti on Favorite',
              subtitle: 'Show confetti animation when favoriting a post',
              trailing: CupertinoSwitch(
                value: settings.confettiOnFavorite,
                activeTrackColor: AppColors.primaryGreen,
                onChanged: (value) => settings.setConfettiOnFavorite(value),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCustomizationSection(BuildContext context, bool isDark) {
    return _buildLiquidGlassSection(
      context,
      isDark: isDark,
      title: 'CUSTOMIZATION',
      children: [
        Consumer<SettingsProvider>(
          builder: (context, settings, _) {
            return _buildLiquidGlassTile(
              context,
              isDark: isDark,
              icon: CupertinoIcons.square_stack_3d_up,
              iconColor: _ThemeColors.primaryIndigo,
              title: 'Navigation Order',
              subtitle: 'Customize the order of navigation tabs',
              showChevron: true,
              onTap: () => _showNavOrderEditor(context, settings, isDark),
            );
          },
        ),
      ],
    );
  }

  void _showNavOrderEditor(
    BuildContext context,
    SettingsProvider settings,
    bool isDark,
  ) {
    // Navigation items with their icons and labels
    final navItems = <int, Map<String, dynamic>>{
      0: {'icon': CupertinoIcons.house_fill, 'label': 'Home'},
      1: {'icon': CupertinoIcons.flame_fill, 'label': 'Hot'},
      2: {'icon': CupertinoIcons.star_fill, 'label': 'Popular'},
      3: {'icon': CupertinoIcons.person_fill, 'label': 'Profile'},
      4: {'icon': CupertinoIcons.settings_solid, 'label': 'Settings'},
    };

    List<int> currentOrder = List.from(settings.mobileNavOrder);

    showCupertinoModalPopup(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isDark
                            ? CupertinoColors.white.withValues(alpha: 0.1)
                            : CupertinoColors.black.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const Text(
                        'Navigation Order',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          settings.setMobileNavOrder(currentOrder);
                          Navigator.pop(context);
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ),
                // Instructions
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Drag to reorder navigation items',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? CupertinoColors.white.withValues(alpha: 0.6)
                          : CupertinoColors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                // Reorderable list
                Expanded(
                  child: Material(
                    color: CupertinoColors.transparent,
                    child: ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: currentOrder.length,
                      onReorder: (oldIndex, newIndex) {
                        setModalState(() {
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
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2C2C2E)
                                : const Color(0xFFF2F2F7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: Icon(
                              item['icon'] as IconData,
                              color: _ThemeColors.primaryPurple,
                            ),
                            title: Text(item['label'] as String),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Reset button
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      color: isDark
                          ? const Color(0xFF2C2C2E)
                          : const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(12),
                      onPressed: () {
                        setModalState(() {
                          currentOrder = [0, 1, 2, 3, 4];
                        });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.arrow_counterclockwise,
                            size: 18,
                            color: isDark
                                ? CupertinoColors.white
                                : CupertinoColors.black,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Reset to Default',
                            style: TextStyle(
                              color: isDark
                                  ? CupertinoColors.white
                                  : CupertinoColors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNetworkSection(BuildContext context, bool isDark) {
    return _buildLiquidGlassSection(
      context,
      isDark: isDark,
      title: 'NETWORK',
      children: [
        Consumer<SettingsProvider>(
          builder: (context, settings, _) {
            return _buildLiquidGlassTile(
              context,
              isDark: isDark,
              icon: CupertinoIcons.globe,
              iconColor: AppColors.primaryTeal,
              title: 'HTTP Proxy',
              subtitle: settings.proxyConfig.enabled
                  ? '${settings.proxyConfig.host}:${settings.proxyConfig.port}'
                  : 'Disabled',
              trailing: CupertinoSwitch(
                value: settings.proxyConfig.enabled,
                activeTrackColor: AppColors.primaryGreen,
                onChanged: (value) => settings.setProxyEnabled(value),
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
              icon: CupertinoIcons.gear_alt_fill,
              iconColor: AppColors.primaryOrange,
              title: 'Proxy Settings',
              subtitle: 'Configure proxy host, port, and authentication',
              showChevron: true,
              onTap: () => _showProxySettingsDialog(context, isDark, settings),
            );
          },
        ),
      ],
    );
  }

  void _showProxySettingsDialog(
    BuildContext context,
    bool isDark,
    SettingsProvider settings,
  ) {
    final hostController = TextEditingController(
      text: settings.proxyConfig.host,
    );
    final portController = TextEditingController(
      text: settings.proxyConfig.port.toString(),
    );
    final usernameController = TextEditingController(
      text: settings.proxyConfig.username ?? '',
    );
    final passwordController = TextEditingController(
      text: settings.proxyConfig.password ?? '',
    );

    bool useAuth = settings.proxyConfig.useAuthentication;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1C1C1E).withValues(alpha: 0.95)
                : CupertinoColors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark
                          ? CupertinoColors.white.withValues(alpha: 0.3)
                          : CupertinoColors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 17,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          'Proxy Settings',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? CupertinoColors.white
                                : CupertinoColors.black,
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: _ThemeColors.primaryPurple,
                            ),
                          ),
                          onPressed: () {
                            final port = int.tryParse(portController.text) ?? 8080;
                            settings.setProxyConfig(
                              settings.proxyConfig.copyWith(
                                host: hostController.text.trim(),
                                port: port,
                                useAuthentication: useAuth,
                                username: usernameController.text.trim().isEmpty
                                    ? null
                                    : usernameController.text.trim(),
                                password: passwordController.text.isEmpty
                                    ? null
                                    : passwordController.text,
                              ),
                            );
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                  // Divider
                  Container(
                    height: 0.5,
                    color: isDark
                        ? CupertinoColors.white.withValues(alpha: 0.1)
                        : CupertinoColors.black.withValues(alpha: 0.1),
                  ),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Host field
                          _buildProxyTextField(
                            isDark: isDark,
                            label: 'Proxy Host',
                            placeholder: 'e.g., 127.0.0.1 or proxy.example.com',
                            controller: hostController,
                            keyboardType: TextInputType.url,
                          ),
                          const SizedBox(height: 16),
                          // Port field
                          _buildProxyTextField(
                            isDark: isDark,
                            label: 'Proxy Port',
                            placeholder: 'e.g., 8080',
                            controller: portController,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 24),
                          // Authentication toggle
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? CupertinoColors.white.withValues(alpha: 0.1)
                                  : CupertinoColors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Use Authentication',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? CupertinoColors.white
                                            : CupertinoColors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Enable if proxy requires login',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark
                                            ? CupertinoColors.white.withValues(alpha: 0.5)
                                            : CupertinoColors.black.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                                CupertinoSwitch(
                                  value: useAuth,
                                  activeTrackColor: _ThemeColors.primaryPurple,
                                  onChanged: (value) {
                                    setState(() => useAuth = value);
                                  },
                                ),
                              ],
                            ),
                          ),
                          if (useAuth) ...[
                            const SizedBox(height: 16),
                            _buildProxyTextField(
                              isDark: isDark,
                              label: 'Username',
                              placeholder: 'Proxy username',
                              controller: usernameController,
                              keyboardType: TextInputType.text,
                            ),
                            const SizedBox(height: 16),
                            _buildProxyTextField(
                              isDark: isDark,
                              label: 'Password',
                              placeholder: 'Proxy password',
                              controller: passwordController,
                              keyboardType: TextInputType.visiblePassword,
                              obscureText: true,
                            ),
                          ],
                          const SizedBox(height: 24),
                          // Info text
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _ThemeColors.primaryPurple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _ThemeColors.primaryPurple.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  CupertinoIcons.info_circle_fill,
                                  size: 20,
                                  color: _ThemeColors.primaryPurple,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'The HTTP proxy will be used for all API requests. Supports HTTP/HTTPS proxies on all platforms (macOS, Windows, Linux, Android, iOS). Web platform uses browser settings.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.4,
                                      color: isDark
                                          ? CupertinoColors.white.withValues(alpha: 0.7)
                                          : CupertinoColors.black.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

  Widget _buildProxyTextField({
    required bool isDark,
    required String label,
    required String placeholder,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark
                ? CupertinoColors.white.withValues(alpha: 0.7)
                : CupertinoColors.black.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        CupertinoTextField(
          controller: controller,
          placeholder: placeholder,
          keyboardType: keyboardType,
          obscureText: obscureText,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark
                ? CupertinoColors.white.withValues(alpha: 0.1)
                : CupertinoColors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? CupertinoColors.white.withValues(alpha: 0.15)
                  : CupertinoColors.black.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          style: TextStyle(
            fontSize: 16,
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
          ),
          placeholderStyle: TextStyle(
            fontSize: 16,
            color: isDark
                ? CupertinoColors.white.withValues(alpha: 0.4)
                : CupertinoColors.black.withValues(alpha: 0.4),
          ),
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
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            final version = snapshot.data?.version ?? '...';
            return _buildLiquidGlassTile(
              context,
              isDark: isDark,
              icon: CupertinoIcons.info_circle_fill,
              iconColor: AppColors.primaryBlue,
              title: 'Version',
              trailing: Text(
                version,
                style: TextStyle(
                  color: isDark
                      ? CupertinoColors.white.withValues(alpha: 0.5)
                      : CupertinoColors.black.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
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

  void _showTermsOfService(BuildContext context, bool isDark) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => _buildPolicyDialog(
        context,
        isDark: isDark,
        title: 'Terms of Service',
        content: '''
Klit - Terms of Service

Last Updated: January 2025

1. LICENSE
Klit is free and open source software licensed under the GNU General Public License (GPL). You are free to use, modify, and distribute this software in accordance with the GPL license terms.

2. NO WARRANTY
This software is provided "as is" without warranty of any kind, express or implied. The developers make no guarantees regarding the reliability, accuracy, or fitness for any particular purpose.

3. USER RESPONSIBILITY
You are solely responsible for:
• The content you access through this application
• Compliance with applicable laws in your jurisdiction
• Any actions taken while using this software

4. THIRD-PARTY CONTENT
Klit provides access to third-party content and services. We do not control, endorse, or assume responsibility for any third-party content accessed through this application.

5. MODIFICATIONS
We reserve the right to modify these terms at any time. Continued use of the application constitutes acceptance of any changes.

6. OPEN SOURCE
The source code is publicly available. You can review, contribute to, or fork this project in accordance with the GPL license.
''',
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context, bool isDark) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => _buildPolicyDialog(
        context,
        isDark: isDark,
        title: 'Privacy Policy',
        content: '''
Klit - Privacy Policy

Last Updated: January 2025

1. DATA COLLECTION
We do not collect any personal data. Klit is designed with privacy as a core principle.

2. LOCAL STORAGE
All your data is stored locally on your device:
• Favorites and bookmarks
• Viewing history
• App preferences and settings

No data is transmitted to external servers owned by us.

3. NO TRACKING
We do not:
• Track your usage or behavior
• Collect analytics or telemetry
• Use cookies or tracking technologies
• Share any information with third parties

4. NO ACCOUNTS
Klit does not require user accounts or registration. There is no sign-up process and no personal information is ever requested.

5. THIRD-PARTY SERVICES
When you access content through Klit, you may interact with third-party websites or services. Those services have their own privacy policies which we do not control.

6. OPEN SOURCE
Klit is open source under the GPL license. You can verify our privacy practices by reviewing the source code yourself.

7. CONTACT
For any privacy concerns or questions about this policy, please visit our website or open an issue on our public repository.

Your Privacy is Protected - Everything Stays on Your Device.
''',
      ),
    );
  }

  Widget _buildPolicyDialog(
    BuildContext context, {
    required bool isDark,
    required String title,
    required String content,
  }) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark
            ? CupertinoColors.black.withValues(alpha: 0.9)
            : CupertinoColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark
                      ? CupertinoColors.white.withValues(alpha: 0.3)
                      : CupertinoColors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 60),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Text(
                        'Done',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Divider
              Container(
                height: 0.5,
                color: isDark
                    ? CupertinoColors.white.withValues(alpha: 0.1)
                    : CupertinoColors.black.withValues(alpha: 0.1),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    content,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: isDark
                          ? CupertinoColors.white.withValues(alpha: 0.85)
                          : CupertinoColors.black.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                      style: TextStyle(fontSize: 13, color: subtitleColor),
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
              : CupertinoColors.black.withValues(
                  alpha: isEnabled ? 0.08 : 0.03,
                ),
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
        content: const Text(
          'Are you sure you want to clear your search history?',
        ),
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

  void _showThemePicker(
    BuildContext context,
    SettingsProvider settings,
    bool isDark,
  ) {
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
                        color: isDark
                            ? CupertinoColors.white
                            : CupertinoColors.black,
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
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark
                                    ? AppColors.primaryBlue.withValues(
                                        alpha: 0.3,
                                      )
                                    : AppColors.primaryBlue.withValues(
                                        alpha: 0.15,
                                      ))
                              : (isDark
                                    ? CupertinoColors.white.withValues(
                                        alpha: 0.08,
                                      )
                                    : CupertinoColors.black.withValues(
                                        alpha: 0.04,
                                      )),
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(
                                  color: AppColors.primaryBlue.withValues(
                                    alpha: 0.5,
                                  ),
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
                                        ? CupertinoColors.white.withValues(
                                            alpha: 0.7,
                                          )
                                        : CupertinoColors.black.withValues(
                                            alpha: 0.6,
                                          )),
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
                                          ? CupertinoColors.white.withValues(
                                              alpha: 0.5,
                                            )
                                          : CupertinoColors.black.withValues(
                                              alpha: 0.5,
                                            ),
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
