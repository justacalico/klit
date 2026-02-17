import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/helpers.dart';
import '../../providers/providers.dart';

/// Design constants for the purple/indigo mobile theme
class _ThemeColors {
  static const Color primaryPurple = Color(0xFF8B5CF6);
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

  bool _isPresetHost(String url) {
    return _presetHosts.any((h) => h['url'] == url);
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

    return CupertinoPageScaffold(
      backgroundColor: isDark
          ? const Color(0xFF000000)
          : CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark
            ? const Color(0xFF1C1C1E).withValues(alpha: 0.9)
            : CupertinoColors.white.withValues(alpha: 0.9),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? _ThemeColors.primaryPurple.withValues(alpha: 0.15)
                : _ThemeColors.primaryPurple.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
        middle: Text(
          'Server Configuration',
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
            _buildSectionHeader('PRESET SERVERS'),
            const SizedBox(height: 8),
            _buildPresetHosts(context, isDark),
            const SizedBox(height: 24),
            _buildSectionHeader('CUSTOM SERVER'),
            const SizedBox(height: 8),
            _buildCustomHost(context, isDark),
            const SizedBox(height: 24),
            _buildInfoCard(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
      ),
    );
  }

  Widget _buildPresetHosts(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? _ThemeColors.primaryPurple.withValues(alpha: 0.15)
              : CupertinoColors.systemGrey5,
          width: 0.5,
        ),
      ),
      child: Column(
        children: _presetHosts.asMap().entries.map((entry) {
          final index = entry.key;
          final host = entry.value;
          final isSelected = _selectedHost == host['url'];
          final isLast = index == _presetHosts.length - 1;

          return Column(
            children: [
              GestureDetector(
                onTap: () {
                  HapticUtils.selectionClick();
                  setState(() => _selectedHost = host['url']!);
                  _saveHost(host['url']!);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  color: CupertinoColors.transparent,
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    _ThemeColors.primaryPurple,
                                    _ThemeColors.primaryPurple.withValues(alpha: 0.8),
                                  ],
                                )
                              : null,
                          color: isSelected ? null : (isDark ? const Color(0xFF2C2C2E) : CupertinoColors.systemGrey5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          CupertinoIcons.globe,
                          size: 20,
                          color: isSelected
                              ? CupertinoColors.white
                              : CupertinoColors.secondaryLabel.resolveFrom(context),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              host['name']!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: isDark ? CupertinoColors.white : CupertinoColors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              host['description']!,
                              style: TextStyle(
                                fontSize: 14,
                                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          CupertinoIcons.checkmark_circle_fill,
                          color: _ThemeColors.primaryPurple,
                          size: 24,
                        ),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.only(left: 70),
                  child: Container(
                    height: 0.5,
                    color: isDark
                        ? CupertinoColors.white.withValues(alpha: 0.1)
                        : CupertinoColors.systemGrey4,
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCustomHost(BuildContext context, bool isDark) {
    final isCustom = !_isPresetHost(_selectedHost);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCustom
              ? _ThemeColors.primaryPurple
              : (isDark
                  ? _ThemeColors.primaryPurple.withValues(alpha: 0.15)
                  : CupertinoColors.systemGrey5),
          width: isCustom ? 2 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Custom Host URL',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
            ),
          ),
          const SizedBox(height: 12),
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
              color: isDark ? const Color(0xFF2C2C2E) : CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 14),
              color: _ThemeColors.primaryPurple,
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

  Widget _buildInfoCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _ThemeColors.primaryPurple.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _ThemeColors.primaryPurple.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            CupertinoIcons.info_circle_fill,
            color: _ThemeColors.primaryPurple,
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
