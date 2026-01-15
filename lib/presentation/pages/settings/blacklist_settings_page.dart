import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../../data/services/services.dart';
import '../../providers/providers.dart';

/// Design constants for the purple/indigo mobile theme
class _ThemeColors {
  static const Color primaryPurple = Color(0xFF8B5CF6);
}

/// Blacklist settings page for managing tag blacklist
class BlacklistSettingsPage extends StatefulWidget {
  const BlacklistSettingsPage({super.key});

  @override
  State<BlacklistSettingsPage> createState() => _BlacklistSettingsPageState();
}

class _BlacklistSettingsPageState extends State<BlacklistSettingsPage> {
  late TextEditingController _blacklistController;
  bool _isSyncing = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _blacklistController = TextEditingController(text: settings.blacklist);
    _blacklistController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _blacklistController.removeListener(_onTextChanged);
    _blacklistController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final settings = context.read<SettingsProvider>();
    final hasChanges = _blacklistController.text != settings.blacklist;
    if (hasChanges != _hasChanges) {
      setState(() => _hasChanges = hasChanges);
    }
  }

  Future<void> _saveBlacklist() async {
    final settings = context.read<SettingsProvider>();
    await settings.setBlacklist(_blacklistController.text);
    setState(() => _hasChanges = false);
    
    if (mounted) {
      _showToast('Blacklist saved');
    }
  }

  Future<void> _syncFromAccount() async {
    final authProvider = context.read<AuthProvider>();
    final settings = context.read<SettingsProvider>();
    
    if (authProvider.isGuest || authProvider.currentAccount == null) {
      _showToast('Sign in to sync blacklist from your account');
      return;
    }

    setState(() => _isSyncing = true);

    try {
      final apiService = context.read<ApiService>();
      final result = await apiService.getUserProfile(
        authProvider.currentAccount!.username,
      );

      await result.when(
        success: (user) async {
          if (user.blacklistedTags != null && user.blacklistedTags!.isNotEmpty) {
            _blacklistController.text = user.blacklistedTags!;
            await settings.setBlacklist(user.blacklistedTags!);
            _showToast('Blacklist synced from account');
          } else {
            _showToast('No blacklist found on your account');
          }
        },
        failure: (error) {
          _showToast('Failed to sync: ${error.message}');
        },
      );
    } catch (e) {
      _showToast('Failed to sync blacklist');
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  void _showToast(String message) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CupertinoAlertDialog(
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Blacklist Syntax'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildHelpSection('Basic Tags', 
                'Enter one tag per line to hide posts containing that tag.\n\nExample:\nyoung\nscat'),
              const SizedBox(height: 12),
              _buildHelpSection('Multiple Tags (AND)', 
                'Put multiple tags on one line to require ALL tags.\n\nExample:\nmale solo\n(hides posts with BOTH male AND solo)'),
              const SizedBox(height: 12),
              _buildHelpSection('Exclusions', 
                'Use - to exclude a tag from a rule.\n\nExample:\nmale -muscular\n(hides male posts EXCEPT muscular ones)'),
              const SizedBox(height: 12),
              _buildHelpSection('Special Filters', 
                'rating:s - Safe\nrating:q - Questionable\nrating:e - Explicit\ntype:video - Videos\ntype:gif - GIFs'),
              const SizedBox(height: 12),
              _buildHelpSection('Wildcards', 
                'Use * for partial matches.\n\nExample:\nyoung*\n(matches young, younger, youngest, etc.)'),
              const SizedBox(height: 12),
              _buildHelpSection('Comments', 
                'Lines starting with # are ignored.\n\nExample:\n# This is a comment'),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: const TextStyle(
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();
    final isGuest = authProvider.isGuest;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
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
          'Blacklist',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _showHelpDialog,
              child: Icon(
                CupertinoIcons.question_circle,
                color: _ThemeColors.primaryPurple,
                size: 24,
              ),
            ),
            if (_hasChanges)
              CupertinoButton(
                padding: const EdgeInsets.only(left: 8),
                onPressed: _saveBlacklist,
                child: Text(
                  'Save',
                  style: TextStyle(
                    color: _ThemeColors.primaryPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Sync button section
            _buildSyncSection(isDark, isGuest),
            // Blacklist editor
            Expanded(
              child: _buildEditor(isDark),
            ),
            // Footer with stats
            _buildFooter(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncSection(bool isDark, bool isGuest) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? CupertinoColors.white.withValues(alpha: 0.1)
                : CupertinoColors.black.withValues(alpha: 0.05),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sync from Account',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isGuest
                      ? 'Sign in to sync your blacklist'
                      : 'Import blacklist from your e621/e926 profile',
                  style: TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isGuest
                ? CupertinoColors.systemGrey4
                : _ThemeColors.primaryPurple,
            borderRadius: BorderRadius.circular(8),
            onPressed: isGuest || _isSyncing ? null : _syncFromAccount,
            child: _isSyncing
                ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.cloud_download,
                        size: 18,
                        color: isGuest
                            ? CupertinoColors.systemGrey
                            : CupertinoColors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Sync',
                        style: TextStyle(
                          color: isGuest
                              ? CupertinoColors.systemGrey
                              : CupertinoColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.pencil,
                size: 16,
                color: CupertinoColors.systemGrey,
              ),
              const SizedBox(width: 8),
              Text(
                'Enter tags to blacklist (one rule per line)',
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2C2C2E)
                    : CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? _ThemeColors.primaryPurple.withValues(alpha: 0.2)
                      : _ThemeColors.primaryPurple.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: CupertinoTextField(
                controller: _blacklistController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                padding: const EdgeInsets.all(16),
                placeholder: '# Example blacklist\nyoung\nscat\ngore\n-safe_for_work muscular',
                placeholderStyle: TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'monospace',
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  height: 1.5,
                ),
                decoration: const BoxDecoration(),
                keyboardType: TextInputType.multiline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    final settings = context.watch<SettingsProvider>();
    final lineCount = settings.blacklistLines.length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark
                ? CupertinoColors.white.withValues(alpha: 0.1)
                : CupertinoColors.black.withValues(alpha: 0.05),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.list_bullet,
                size: 16,
                color: CupertinoColors.systemGrey,
              ),
              const SizedBox(width: 8),
              Text(
                '$lineCount active ${lineCount == 1 ? 'rule' : 'rules'}',
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: settings.blacklistEnabled
                      ? CupertinoColors.systemGreen
                      : CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                settings.blacklistEnabled ? 'Enabled' : 'Disabled',
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
