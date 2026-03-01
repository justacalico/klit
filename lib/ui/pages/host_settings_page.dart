import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/helpers.dart';
import '../../providers/providers.dart';

class _ServerPageColors {
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color accentGreen = Color(0xFF22C55E);
}

/// Host settings page
class HostSettingsPage extends StatefulWidget {
  const HostSettingsPage({super.key});

  @override
  State<HostSettingsPage> createState() => _HostSettingsPageState();
}

class _HostSettingsPageState extends State<HostSettingsPage> {
  final _customHostController = TextEditingController();
  String _selectedHost = ApiConstants.defaultHost;

  final List<Map<String, String>> _presetHosts = [
    {
      'name': 'e926 (Default)',
      'url': 'https://e926.net',
      'description': 'Main e926 instance (SFW)',
    },
    {
      'name': 'e621 (NSFW)',
      'url': 'https://e621.net',
      'description': 'NSFW alternative',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedHost = context.read<SettingsProvider>().host;
    _customHostController.text = _selectedHost;
  }

  @override
  void dispose() {
    _customHostController.dispose();
    super.dispose();
  }

  Future<void> _saveHost(String host) async {
    final error = Validators.url(host);
    if (error != null) {
      _showError(error);
      return;
    }

    // Save the new host (this triggers onHostChanged which updates API and clears posts)
    await context.read<SettingsProvider>().setHost(host);

    if (mounted) {
      Navigator.of(context).pop();
      _showSuccess('Host updated. Posts will reload from the new server.');
    }
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final isOled = context.watch<SettingsProvider>().themeMode == 3;

    return KeyedSubtree(
      key: const ValueKey('host-settings-page'),
      child: CupertinoPageScaffold(
        backgroundColor: AppColors.resolveScaffoldBackground(isDark, isOled: isOled),
        navigationBar: CupertinoNavigationBar(
          backgroundColor: AppColors.resolveSecondaryBackground(isDark, isOled: isOled).withValues(alpha: 0.9),
          border: Border(
            bottom: BorderSide(
              color: isDark
                  ? _ServerPageColors.primaryPurple.withValues(alpha: 0.15)
                  : _ServerPageColors.primaryPurple.withValues(alpha: 0.1),
              width: 0.5,
            ),
          ),
          middle: Text(
            'Server',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
            ),
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildContentHeader(isDark),
              const SizedBox(height: 20),
              _buildCard(
                isDark: isDark,
                isOled: isOled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCardTitle('Preset servers', 'Choose default or NSFW instance', isDark),
                    const SizedBox(height: 16),
                    _buildPresetHosts(context, isDark, isOled),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildCustomHost(context, isDark, isOled),
              const SizedBox(height: 20),
              _buildInfoCard(context, isDark, isOled),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.globe,
            size: 28,
            color: _ServerPageColors.accentGreen,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Server',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Choose API host or enter a custom URL',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required bool isDark,
    required bool isOled,
    required Widget child,
    EdgeInsets? padding,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding ?? const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF1C1C1E).withValues(alpha: 0.85),
                      const Color(0xFF252528).withValues(alpha: 0.7),
                    ]
                  : [
                      const Color(0xFFFFFFFF).withValues(alpha: 0.95),
                      const Color(0xFFF5F5F7).withValues(alpha: 0.9),
                    ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? CupertinoColors.white.withValues(alpha: 0.06)
                  : CupertinoColors.black.withValues(alpha: 0.04),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? CupertinoColors.black.withValues(alpha: 0.35)
                    : CupertinoColors.systemGrey.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildCardTitle(String title, String subtitle, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2,
          ),
        ),
      ],
    );
  }

  Widget _buildPresetHosts(BuildContext context, bool isDark, bool isOled) {
    return Column(
      children: _presetHosts.asMap().entries.map((entry) {
        final index = entry.key;
        final host = entry.value;
        final isSelected = _selectedHost == host['url'];
        final isLast = index == _presetHosts.length - 1;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                HapticUtils.selectionClick();
                setState(() => _selectedHost = host['url']!);
                _saveHost(host['url']!);
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _ServerPageColors.primaryPurple,
                                  _ServerPageColors.primaryPurple,
                                ],
                              )
                            : null,
                        color: isSelected
                            ? null
                            : (isDark
                                ? CupertinoColors.tertiarySystemFill
                                : CupertinoColors.systemGrey5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        CupertinoIcons.globe,
                        size: 22,
                        color: isSelected
                            ? CupertinoColors.white
                            : CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            host['name']!,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? CupertinoColors.white
                                  : CupertinoColors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            host['description']!,
                            style: TextStyle(
                              fontSize: 13,
                              color: CupertinoColors.secondaryLabel.resolveFrom(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _ServerPageColors.primaryPurple.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Active',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _ServerPageColors.primaryPurple,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (!isLast)
              Container(
                height: 0.5,
                margin: const EdgeInsets.only(left: 60),
                color: isDark
                    ? CupertinoColors.white.withValues(alpha: 0.08)
                    : CupertinoColors.systemGrey5,
              ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCustomHost(BuildContext context, bool isDark, bool isOled) {
    return _buildCard(
      isDark: isDark,
      isOled: isOled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCardTitle('Custom server', 'Use your own API host', isDark),
          const SizedBox(height: 16),
          CupertinoTextField(
            controller: _customHostController,
            placeholder: 'https://example.com',
            keyboardType: TextInputType.url,
            padding: const EdgeInsets.all(14),
            style: TextStyle(
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
            ),
            placeholderStyle: TextStyle(
              color: CupertinoColors.placeholderText.resolveFrom(context),
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? CupertinoColors.tertiarySystemFill
                  : CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 14),
              color: _ServerPageColors.primaryPurple,
              borderRadius: BorderRadius.circular(10),
              onPressed: () {
                HapticUtils.selectionClick();
                final url = _customHostController.text.trim();
                if (url.isNotEmpty) {
                  setState(() => _selectedHost = url);
                  _saveHost(url);
                }
              },
              child: const Text(
                'Use Custom Host',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: CupertinoColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, bool isDark, bool isOled) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _ServerPageColors.primaryPurple.withValues(
          alpha: isDark ? 0.12 : 0.08,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _ServerPageColors.primaryPurple.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            CupertinoIcons.info_circle_fill,
            color: _ServerPageColors.primaryPurple,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Custom hosts must be compatible with the e621 API. Changing the host will affect all new requests.',
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: isDark
                    ? CupertinoColors.white.withValues(alpha: 0.9)
                    : CupertinoColors.black.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
