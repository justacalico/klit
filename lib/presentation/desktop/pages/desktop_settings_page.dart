import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../../app/routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/proxy_config.dart';
import '../../providers/providers.dart';
import '../widgets/desktop_toolbar.dart';

/// Desktop settings page with macOS-style preferences
class DesktopSettingsPage extends StatelessWidget {
  final Function(String) onNavigate;

  const DesktopSettingsPage({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const DesktopToolbar(
          title: 'Settings',
          icon: CupertinoIcons.settings,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      context,
                      title: 'Account',
                      icon: CupertinoIcons.person_circle,
                      children: [_buildAccountCard(context, CupertinoTheme.brightnessOf(context) == Brightness.dark)],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      context,
                      title: 'Appearance',
                      icon: CupertinoIcons.paintbrush,
                      children: [_buildThemeSelector(context, CupertinoTheme.brightnessOf(context) == Brightness.dark)],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      context,
                      title: 'Content',
                      icon: CupertinoIcons.photo_on_rectangle,
                      children: [
                        _buildGridSizeSetting(context, CupertinoTheme.brightnessOf(context) == Brightness.dark),
                        const SizedBox(height: 12),
                        _buildSafeModeSetting(context, CupertinoTheme.brightnessOf(context) == Brightness.dark),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      context,
                      title: 'Behavior',
                      icon: CupertinoIcons.hand_draw,
                      children: [
                        _buildConfettiSetting(context, CupertinoTheme.brightnessOf(context) == Brightness.dark),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      context,
                      title: 'Connection',
                      icon: CupertinoIcons.globe,
                      children: [
                        _buildHostSetting(context, CupertinoTheme.brightnessOf(context) == Brightness.dark),
                        const SizedBox(height: 12),
                        _buildProxySetting(context, CupertinoTheme.brightnessOf(context) == Brightness.dark),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      context,
                      title: 'About',
                      icon: CupertinoIcons.info_circle,
                      children: [_buildAboutCard(context, CupertinoTheme.brightnessOf(context) == Brightness.dark)],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: const Color(0xFF8B5CF6)),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildCard(
    BuildContext context,
    bool isDark, {
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF2C2C2E).withValues(alpha: 0.7),
                      const Color(0xFF1C1C1E).withValues(alpha: 0.8),
                    ]
                  : [
                      const Color(0xFFFFFFFF).withValues(alpha: 0.7),
                      const Color(0xFFF8F8FA).withValues(alpha: 0.8),
                    ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF3D3D3F).withValues(alpha: 0.5)
                  : const Color(0xFFE5E5E7).withValues(alpha: 0.8),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, bool isDark) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final account = authProvider.currentAccount;
        final isGuest = authProvider.isGuest;

        // Guest mode - show sign in prompt
        if (isGuest) {
          return _buildCard(
            context,
            isDark,
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(
                    child: Icon(
                      CupertinoIcons.person_badge_plus,
                      size: 24,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Guest Mode',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Sign in to access all features',
                        style: TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  onPressed: () {
                    authProvider.logout();
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.login,
                      (route) => false,
                    );
                  },
                  child: const Text('Sign In'),
                ),
              ],
            ),
          );
        }

        return _buildCard(
          context,
          isDark,
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(
                    account != null ? account.username[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account?.username ?? 'Not logged in',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (account != null)
                      Text(
                        account.host,
                        style: TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                onPressed: () => onNavigate(AppRoutes.accountManagement),
                child: const Text('Manage'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeSelector(BuildContext context, bool isDark) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return _buildCard(
          context,
          isDark,
          child: Row(
            children: [
              const Icon(CupertinoIcons.moon_stars, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Theme', style: TextStyle(fontSize: 15)),
              ),
              CupertinoSlidingSegmentedControl<int>(
                groupValue: settings.themeMode,
                children: const {
                  0: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('Auto', style: TextStyle(fontSize: 12)),
                  ),
                  1: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('Light', style: TextStyle(fontSize: 12)),
                  ),
                  2: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('Dark', style: TextStyle(fontSize: 12)),
                  ),
                  3: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('OLED', style: TextStyle(fontSize: 12)),
                  ),
                },
                onValueChanged: (value) {
                  if (value != null) {
                    settings.setThemeMode(value);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGridSizeSetting(BuildContext context, bool isDark) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return _buildCard(
          context,
          isDark,
          child: Row(
            children: [
              const Icon(CupertinoIcons.square_grid_2x2, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Default Grid Size',
                  style: TextStyle(fontSize: 15),
                ),
              ),
              CupertinoSlidingSegmentedControl<int>(
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
                  if (value != null) {
                    settings.setGridSize(value);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSafeModeSetting(BuildContext context, bool isDark) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return _buildCard(
          context,
          isDark,
          child: Row(
            children: [
              const Icon(CupertinoIcons.shield, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Safe Mode', style: TextStyle(fontSize: 15)),
                    Text(
                      'Only show safe-rated content',
                      style: TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoSwitch(
                value: settings.safeMode,
                onChanged: (value) => settings.setSafeMode(value),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConfettiSetting(BuildContext context, bool isDark) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return _buildCard(
          context,
          isDark,
          child: Row(
            children: [
              const Icon(CupertinoIcons.sparkles, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Confetti on Favorite', style: TextStyle(fontSize: 15)),
                    Text(
                      'Show confetti animation when favoriting',
                      style: TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoSwitch(
                value: settings.confettiOnFavorite,
                onChanged: (value) => settings.setConfettiOnFavorite(value),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHostSetting(BuildContext context, bool isDark) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return _buildCard(
          context,
          isDark,
          child: Row(
            children: [
              const Icon(CupertinoIcons.link, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('API Host', style: TextStyle(fontSize: 15)),
                    Text(
                      settings.host,
                      style: const TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                onPressed: () => onNavigate(AppRoutes.hostSettings),
                child: const Text('Configure'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProxySetting(BuildContext context, bool isDark) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final proxyConfig = settings.proxyConfig;
        return _buildCard(
          context,
          isDark,
          child: Row(
            children: [
              const Icon(CupertinoIcons.arrow_right_arrow_left, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('HTTP Proxy', style: TextStyle(fontSize: 15)),
                    Text(
                      proxyConfig.enabled
                          ? '${proxyConfig.host}:${proxyConfig.port}'
                          : 'Disabled',
                      style: const TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoSwitch(
                value: proxyConfig.enabled,
                onChanged: (value) => settings.setProxyEnabled(value),
              ),
              const SizedBox(width: 8),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                onPressed: () => _showProxySettingsDialog(context, isDark),
                child: const Text('Configure'),
              ),
            ],
          ),
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
    final usernameController = TextEditingController(text: proxyConfig.username ?? '');
    final passwordController = TextEditingController(text: proxyConfig.password ?? '');
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
                const SizedBox(height: 12),
                Text(
                  'Proxy settings apply to all API requests.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? CupertinoColors.systemGrey
                        : CupertinoColors.systemGrey2,
                  ),
                  textAlign: TextAlign.center,
                ),
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

                settings.setProxyConfig(ProxyConfig(
                  enabled: proxyConfig.enabled,
                  host: host,
                  port: port,
                  useAuthentication: useAuth,
                  username: useAuth ? username : null,
                  password: useAuth ? password : null,
                ));
                Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context, bool isDark) {
    return _buildCard(
      context,
      isDark,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryBlue, AppColors.primaryPurple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'K',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConstants.appName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Version ${AppConstants.appVersion}',
                      style: TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'A beautiful e926-compatible client built with Flutter.',
            style: TextStyle(
              fontSize: 13,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }
}
