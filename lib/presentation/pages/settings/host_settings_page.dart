import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider;
import 'package:provider/provider.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/helpers.dart';
import '../../providers/providers.dart';

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

    await context.read<SettingsProvider>().setHost(host);
    
    if (mounted) {
      Navigator.of(context).pop();
      _showSuccess('Host updated successfully');
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
          ? AppColors.darkGroupedBackground
          : AppColors.lightGroupedBackground,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Server Configuration'),
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
            const SizedBox(height: 32),
            _buildInfoCard(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
      ),
    );
  }

  Widget _buildPresetHosts(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSecondaryBackground : CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: _presetHosts.asMap().entries.map((entry) {
          final index = entry.key;
          final host = entry.value;
          final isSelected = _selectedHost == host['url'];
          final isLast = index == _presetHosts.length - 1;

          return Column(
            children: [
              CupertinoListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryBlue
                        : CupertinoColors.systemGrey4,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    CupertinoIcons.globe,
                    size: 20,
                    color: isSelected
                        ? CupertinoColors.white
                        : CupertinoColors.secondaryLabel,
                  ),
                ),
                title: Text(host['name']!),
                subtitle: Text(host['description']!),
                trailing: isSelected
                    ? const Icon(
                        CupertinoIcons.checkmark_circle_fill,
                        color: AppColors.primaryBlue,
                      )
                    : null,
                onTap: () {
                  setState(() => _selectedHost = host['url']!);
                  _saveHost(host['url']!);
                },
              ),
              if (!isLast)
                const Padding(
                  padding: EdgeInsets.only(left: 54),
                  child: Divider(height: 1),
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
        color: isDark ? AppColors.darkSecondaryBackground : CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        border: isCustom
            ? Border.all(color: AppColors.primaryBlue, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Custom Host URL',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          CupertinoTextField(
            controller: _customHostController,
            placeholder: 'https://example.com',
            keyboardType: TextInputType.url,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6.resolveFrom(context),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(10),
                  onPressed: () {
                    final url = _customHostController.text.trim();
                    if (url.isNotEmpty) {
                      setState(() => _selectedHost = url);
                      _saveHost(url);
                    }
                  },
                  child: const Text(
                    'Use Custom Host',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.info_circle,
            color: AppColors.primaryBlue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Custom hosts must be compatible with the e926 API. Changing the host will affect all new requests.',
              style: TextStyle(
                fontSize: 13,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
