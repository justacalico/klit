import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:provider/provider.dart';
import '../../app/routes.dart';
import '../../core/constants/constants.dart';
import '../../data/services/services.dart';
import '../layout/layout_scope.dart';
import '../../providers/providers.dart';

/// Design constants for account management
class _AccountColors {
  static const Color primaryIndigo = Color(0xFF6366F1);
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color primaryViolet = Color(0xFFA855F7);
}

/// Embeddable account list and empty state; add/switch/remove via static [showAddAccountSheet].
class AccountManagementContent extends StatelessWidget {
  final bool isDark;
  /// When true, used inside Settings: no desktop back/title row; optional Add above list on mobile.
  final bool embeddedInSettings;
  /// When true (and embedded), show an "Add account" row above the list on mobile.
  final bool showAddButtonAboveList;

  const AccountManagementContent({
    super.key,
    required this.isDark,
    this.embeddedInSettings = false,
    this.showAddButtonAboveList = false,
  });

  /// Show add-account sheet (dialog on desktop, modal on mobile). Used by Settings and empty state.
  static void showAddAccountSheet(BuildContext context, bool isDesktop) {
    if (isDesktop) {
      showCupertinoDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => const _DesktopAddAccountDialog(),
      );
    } else {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => const _AddAccountSheet(),
      );
    }
  }

  static void _showDesktopAccountOptions(
    BuildContext context,
    String accountId,
    bool isActive,
    bool isDark,
  ) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _DesktopAccountOptionsDialog(
        accountId: accountId,
        isActive: isActive,
        isDark: isDark,
        onSwitch: () {
          Navigator.of(dialogContext).pop();
          final auth = context.read<AuthProvider>();
          final account = auth.accounts.firstWhere((a) => a.id == accountId);
          AccountManagementContent._switchAccount(
            context,
            accountId,
            account.host,
          );
        },
        onTest: () async {
          Navigator.of(dialogContext).pop();
          await AccountManagementContent._testAccount(context, accountId);
        },
        onRemove: () {
          Navigator.of(dialogContext).pop();
          AccountManagementContent._confirmRemoveAccount(context, accountId);
        },
      ),
    );
  }

  static void _showAccountOptions(
    BuildContext context,
    String accountId,
    bool isActive,
  ) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          if (!isActive)
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.of(context).pop();
                final auth = context.read<AuthProvider>();
                final posts = context.read<PostsProvider>();
                final settings = context.read<SettingsProvider>();

                // Get the account before switching to access its host
                final account = auth.accounts.firstWhere(
                  (a) => a.id == accountId,
                );

                final success = await auth.switchAccount(accountId);
                if (success && context.mounted) {
                  // Clear all cached posts
                  posts.clearAllPosts();
                  // Update settings host to match the account's host
                  await settings.setHost(account.host);
                  if (!context.mounted) return;
                  // Navigate to main and clear stack to refresh the app
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
                }
              },
              child: const Text('Switch to this account'),
            ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(context).pop();
              await AccountManagementContent._testAccount(context, accountId);
            },
            child: const Text('Test connection'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              AccountManagementContent._confirmRemoveAccount(context, accountId);
            },
            child: const Text('Remove Account'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mode = LayoutScope.of(context);

    if (mode.isDesktop) {
      return Padding(
        padding: EdgeInsets.all(embeddedInSettings ? 0 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: embeddedInSettings ? MainAxisSize.min : MainAxisSize.max,
          children: [
            if (!embeddedInSettings) ...[
              // Header with back button and title
              Row(
                children: [
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? CupertinoColors.white.withValues(alpha: 0.1)
                              : CupertinoColors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          CupertinoIcons.back,
                          color: isDark
                              ? CupertinoColors.white
                              : CupertinoColors.black,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        _AccountColors.primaryIndigo,
                        _AccountColors.primaryPurple,
                      ],
                    ).createShader(bounds),
                    child: const Text(
                      'Accounts',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.white,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _DesktopAddButton(
                    onPressed: () =>
                        AccountManagementContent.showAddAccountSheet(context, true),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
            // Account list
            embeddedInSettings
                ? SizedBox(
                    height: 400,
                    child: Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        if (auth.accounts.isEmpty) {
                          return _buildEmptyState(context);
                        }
                        return _buildDesktopAccountList(context, auth);
                      },
                    ),
                  )
                : Expanded(
                    child: Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        if (auth.accounts.isEmpty) {
                          return _buildEmptyState(context);
                        }
                        return _buildDesktopAccountList(context, auth);
                      },
                    ),
                  ),
          ],
        ),
      );
    } else {
      return Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.accounts.isEmpty) {
            return _buildEmptyState(context);
          }
          final isDesktop = false;
          final list = ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: auth.accounts.length,
            itemBuilder: (context, index) {
              final account = auth.accounts[index];
              final isActive = auth.currentAccount?.id == account.id;
              final isOled = context.watch<SettingsProvider>().themeMode == 3;

              return _MobileAccountCard(
                username: account.username,
                host: Uri.parse(account.host).host,
                isActive: isActive,
                isDark: isDark,
                isOled: isOled,
                onTap: isActive
                    ? null
                    : () => _switchAccount(context, account.id, account.host),
                onOptions: () => AccountManagementContent._showAccountOptions(
                  context,
                  account.id,
                  isActive,
                ),
              );
            },
          );
          if (embeddedInSettings && showAddButtonAboveList) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        onPressed: () =>
                            AccountManagementContent.showAddAccountSheet(context, isDesktop),
                        child: const Text('Add account'),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 320, child: list),
              ],
            );
          }
          // Embedded in settings: give list bounded height to avoid unbounded constraints
          // (parent is Column inside SingleChildScrollView), which triggers semantics assertion.
          if (embeddedInSettings) {
            return SizedBox(height: 320, child: list);
          }
          return list;
        },
      );
    }
  }

  Widget _buildDesktopAccountList(BuildContext context, AuthProvider auth) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView.separated(
          itemCount: auth.accounts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final account = auth.accounts[index];
            final isActive = auth.currentAccount?.id == account.id;
            return _DesktopAccountCard(
              username: account.username,
              host: Uri.parse(account.host).host,
              isActive: isActive,
              isDark: isDark,
              onTap: isActive
                  ? null
                  : () => _switchAccount(context, account.id, account.host),
              onOptions: () => AccountManagementContent._showDesktopAccountOptions(
                context,
                account.id,
                isActive,
                isDark,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDesktop = LayoutScope.of(context).isDesktop;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.person_2,
            size: 64,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
          const SizedBox(height: 16),
          Text(
            'No Accounts',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add an account to get started',
            style: TextStyle(
              fontSize: 15,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 24),
          CupertinoButton.filled(
            onPressed: () =>
                AccountManagementContent.showAddAccountSheet(context, isDesktop),
            child: const Text('Add Account'),
          ),
        ],
      ),
    );
  }

  static Future<void> _switchAccount(
    BuildContext context,
    String accountId,
    String host,
  ) async {
    final auth = context.read<AuthProvider>();
    final posts = context.read<PostsProvider>();
    final settings = context.read<SettingsProvider>();

    final success = await auth.switchAccount(accountId);
    if (success && context.mounted) {
      posts.clearAllPosts();
      await settings.setHost(host);
      if (!context.mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
    }
  }

  static void _confirmRemoveAccount(BuildContext context, String accountId) {
    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Remove Account'),
        content: const Text('Are you sure you want to remove this account?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final noAccountsLeft = await auth.removeAccount(accountId);
              if (noAccountsLeft) {
                navigator.pushNamedAndRemoveUntil(
                  AppRoutes.login,
                  (route) => false,
                );
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  static Future<void> _testAccount(BuildContext context, String accountId) async {
    final auth = context.read<AuthProvider>();
    final api = context.read<ApiService>();
    final account = auth.accounts.where((a) => a.id == accountId).firstOrNull;
    if (account == null || !context.mounted) return;
    final current = auth.currentAccount;
    api.setBaseUrl(account.host);
    api.setAuth(account.username, account.apiKey);
    final result = await api.verifyCredentials(account.username, account.apiKey);
    if (current != null) {
      api.setBaseUrl(current.host);
      api.setAuth(current.username, current.apiKey);
    } else {
      api.clearAuth();
    }
    if (!context.mounted) return;
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Test account'),
        content: Text(
          result.when(
            success: (_) => 'Credentials are valid for ${account.username}@${Uri.parse(account.host).host}.',
            failure: (e) => 'Failed: ${e.message}',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }
}

class _AddAccountSheet extends StatefulWidget {
  const _AddAccountSheet();

  @override
  State<_AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends State<_AddAccountSheet> {
  final _usernameController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _hostController = TextEditingController();
  bool _useCustomHost = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _hostController.text = ApiConstants.defaultHost;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _apiKeyController.dispose();
    _hostController.dispose();
    super.dispose();
  }

  void _showValidationError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Validation Error'),
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

  Future<void> _addAccount() async {
    final username = _usernameController.text.trim();
    final apiKey = _apiKeyController.text.trim();
    final host = _useCustomHost ? _hostController.text.trim() : null;

    // Validate username
    if (username.isEmpty) {
      _showValidationError('Username is required');
      return;
    }
    if (username.length < 3) {
      _showValidationError('Username must be at least 3 characters');
      return;
    }

    // Validate API key
    if (apiKey.isEmpty) {
      _showValidationError('API key is required');
      return;
    }
    if (apiKey.length < 24) {
      _showValidationError('API key is too short');
      return;
    }

    // Validate host if custom
    if (_useCustomHost && host != null) {
      // Allow localhost, IP addresses, and regular domains
      final urlPattern = RegExp(
        r'^https?:\/\/(localhost|\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}|(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6})(:\d+)?(\/[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)?$',
      );
      if (!urlPattern.hasMatch(host)) {
        _showValidationError(
          'Please enter a valid URL (e.g., http://localhost:3000 or https://example.com)',
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final posts = context.read<PostsProvider>();
    final settings = context.read<SettingsProvider>();

    final success = await auth.login(
      username: username,
      apiKey: apiKey,
      host: host,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      // Clear all cached posts since we have a new account
      posts.clearAllPosts();
      // Update settings host to match the new account's host
      final newHost = host ?? 'https://e926.net';
      await settings.setHost(newHost);
      if (!mounted) return;
      // Pop the sheet and navigate to main to refresh everything
      Navigator.of(context).pop();
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
    } else if (auth.error != null && mounted) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text(auth.error!),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final isOled = context.watch<SettingsProvider>().themeMode == 3;
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.resolveSecondaryBackground(isDark, isOled: isOled),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  const Text(
                    'Add Account',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _isLoading ? null : _addAccount,
                    child: _isLoading
                        ? const CupertinoActivityIndicator()
                        : const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              CupertinoTextField(
                controller: _usernameController,
                placeholder: 'Username',
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Icon(
                    CupertinoIcons.person,
                    size: 20,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6.resolveFrom(context),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: _apiKeyController,
                placeholder: 'API Key',
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Icon(
                    CupertinoIcons.lock,
                    size: 20,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6.resolveFrom(context),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CupertinoSwitch(
                    value: _useCustomHost,
                    onChanged: (value) =>
                        setState(() => _useCustomHost = value),
                  ),
                  const SizedBox(width: 12),
                  const Text('Use custom host'),
                ],
              ),
              if (_useCustomHost) ...[
                const SizedBox(height: 12),
                CupertinoTextField(
                  controller: _hostController,
                  placeholder: 'Host URL',
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(
                      CupertinoIcons.globe,
                      size: 20,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6.resolveFrom(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Desktop Widgets

/// Desktop add button with gradient
class _DesktopAddButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _DesktopAddButton({required this.onPressed});

  @override
  State<_DesktopAddButton> createState() => _DesktopAddButtonState();
}

class _DesktopAddButtonState extends State<_DesktopAddButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isHovered
                  ? [_AccountColors.primaryPurple, _AccountColors.primaryViolet]
                  : [
                      _AccountColors.primaryIndigo,
                      _AccountColors.primaryPurple,
                    ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: _AccountColors.primaryPurple.withValues(
                        alpha: 0.4,
                      ),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                CupertinoIcons.plus,
                color: CupertinoColors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Add Account',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Desktop account card with glassmorphic design
class _DesktopAccountCard extends StatefulWidget {
  final String username;
  final String host;
  final bool isActive;
  final bool isDark;
  final VoidCallback? onTap;
  final VoidCallback onOptions;

  const _DesktopAccountCard({
    required this.username,
    required this.host,
    required this.isActive,
    required this.isDark,
    required this.onTap,
    required this.onOptions,
  });

  @override
  State<_DesktopAccountCard> createState() => _DesktopAccountCardState();
}

class _DesktopAccountCardState extends State<_DesktopAccountCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: MouseRegion(
        cursor: widget.onTap != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? _AccountColors.primaryIndigo.withValues(alpha: 0.12)
                  : (widget.isDark
                        ? CupertinoColors.white.withValues(
                            alpha: _isHovered ? 0.08 : 0.05,
                          )
                        : CupertinoColors.white),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: widget.isActive
                    ? _AccountColors.primaryIndigo.withValues(alpha: 0.4)
                    : (_isHovered
                          ? _AccountColors.primaryIndigo.withValues(alpha: 0.2)
                          : (widget.isDark
                                ? CupertinoColors.white.withValues(alpha: 0.08)
                                : CupertinoColors.systemGrey5)),
                width: widget.isActive ? 1.5 : 1,
              ),
              boxShadow: _isHovered && !widget.isActive
                  ? [
                      BoxShadow(
                        color: _AccountColors.primaryIndigo.withValues(
                          alpha: 0.08,
                        ),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: widget.isActive
                        ? const LinearGradient(
                            colors: [
                              _AccountColors.primaryIndigo,
                              _AccountColors.primaryPurple,
                            ],
                          )
                        : null,
                    color: widget.isActive ? null : CupertinoColors.systemGrey,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      widget.username[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.username,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: widget.isActive
                              ? FontWeight.w600
                              : FontWeight.w500,
                          letterSpacing: -0.2,
                          color: widget.isDark
                              ? CupertinoColors.white
                              : CupertinoColors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.host,
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
                // Active badge
                if (widget.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _AccountColors.primaryIndigo.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _AccountColors.primaryIndigo.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _AccountColors.primaryIndigo,
                      ),
                    ),
                  ),
                const SizedBox(width: 10),
                // Options button
                _DesktopOptionsButton(
                  onPressed: widget.onOptions,
                  isDark: widget.isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Desktop options button
class _DesktopOptionsButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isDark;

  const _DesktopOptionsButton({required this.onPressed, required this.isDark});

  @override
  State<_DesktopOptionsButton> createState() => _DesktopOptionsButtonState();
}

class _DesktopOptionsButtonState extends State<_DesktopOptionsButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isHovered
                ? _AccountColors.primaryIndigo.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            CupertinoIcons.ellipsis_circle,
            size: 22,
            color: _isHovered
                ? _AccountColors.primaryIndigo
                : CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      ),
    );
  }
}

/// Mobile account card
class _MobileAccountCard extends StatelessWidget {
  final String username;
  final String host;
  final bool isActive;
  final bool isDark;
  final bool isOled;
  final VoidCallback? onTap;
  final VoidCallback onOptions;

  const _MobileAccountCard({
    required this.username,
    required this.host,
    required this.isActive,
    required this.isDark,
    required this.isOled,
    required this.onTap,
    required this.onOptions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.resolveSecondaryBackground(isDark, isOled: isOled),
        borderRadius: BorderRadius.circular(12),
        border: isActive
            ? Border.all(color: _AccountColors.primaryIndigo, width: 2)
            : null,
      ),
      child: CupertinoListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    colors: [
                      _AccountColors.primaryIndigo,
                      _AccountColors.primaryPurple,
                    ],
                  )
                : null,
            color: isActive ? null : CupertinoColors.systemGrey,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Center(
            child: Text(
              username[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: CupertinoColors.white,
              ),
            ),
          ),
        ),
        title: Text(
          username,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          host,
          style: TextStyle(
            fontSize: 12,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _AccountColors.primaryIndigo.withValues(alpha: 0.2),
                      _AccountColors.primaryPurple.withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _AccountColors.primaryIndigo,
                  ),
                ),
              ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onOptions,
              child: const Icon(CupertinoIcons.ellipsis_circle, size: 24),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

/// Desktop account options dialog
class _DesktopAccountOptionsDialog extends StatelessWidget {
  final String accountId;
  final bool isActive;
  final bool isDark;
  final VoidCallback onSwitch;
  final Future<void> Function() onTest;
  final VoidCallback onRemove;

  const _DesktopAccountOptionsDialog({
    required this.accountId,
    required this.isActive,
    required this.isDark,
    required this.onSwitch,
    required this.onTest,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? CupertinoColors.black.withValues(alpha: 0.7)
                  : CupertinoColors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? CupertinoColors.white.withValues(alpha: 0.1)
                    : CupertinoColors.black.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isActive)
                  _DialogOption(
                    icon: CupertinoIcons.arrow_right_arrow_left,
                    label: 'Switch to this account',
                    isDark: isDark,
                    onTap: onSwitch,
                  ),
                _DialogOption(
                  icon: CupertinoIcons.checkmark_circle,
                  label: 'Test connection',
                  isDark: isDark,
                  onTap: () => onTest(),
                ),
                _DialogOption(
                  icon: CupertinoIcons.trash,
                  label: 'Remove Account',
                  isDark: isDark,
                  isDestructive: true,
                  onTap: onRemove,
                ),
                _DialogOption(
                  icon: CupertinoIcons.xmark,
                  label: 'Cancel',
                  isDark: isDark,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogOption extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final bool isDestructive;
  final VoidCallback onTap;

  const _DialogOption({
    required this.icon,
    required this.label,
    required this.isDark,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  State<_DialogOption> createState() => _DialogOptionState();
}

class _DialogOptionState extends State<_DialogOption> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isDestructive
        ? CupertinoColors.destructiveRed
        : (widget.isDark ? CupertinoColors.white : CupertinoColors.black);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _isHovered
                ? (widget.isDestructive
                      ? CupertinoColors.destructiveRed.withValues(alpha: 0.1)
                      : _AccountColors.primaryIndigo.withValues(alpha: 0.1))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 20, color: color),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Desktop add account dialog
class _DesktopAddAccountDialog extends StatefulWidget {
  const _DesktopAddAccountDialog();

  @override
  State<_DesktopAddAccountDialog> createState() =>
      _DesktopAddAccountDialogState();
}

class _DesktopAddAccountDialogState extends State<_DesktopAddAccountDialog> {
  final _usernameController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _hostController = TextEditingController();
  bool _useCustomHost = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _hostController.text = ApiConstants.defaultHost;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _apiKeyController.dispose();
    _hostController.dispose();
    super.dispose();
  }

  void _showValidationError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Validation Error'),
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

  Future<void> _addAccount() async {
    final username = _usernameController.text.trim();
    final apiKey = _apiKeyController.text.trim();
    final host = _useCustomHost ? _hostController.text.trim() : null;

    if (username.isEmpty) {
      _showValidationError('Username is required');
      return;
    }
    if (username.length < 3) {
      _showValidationError('Username must be at least 3 characters');
      return;
    }
    if (apiKey.isEmpty) {
      _showValidationError('API key is required');
      return;
    }
    if (apiKey.length < 24) {
      _showValidationError('API key is too short');
      return;
    }
    if (_useCustomHost && host != null) {
      // Allow localhost, IP addresses, and regular domains
      final urlPattern = RegExp(
        r'^https?:\/\/(localhost|\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}|(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6})(:\d+)?(\/[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)?$',
      );
      if (!urlPattern.hasMatch(host)) {
        _showValidationError(
          'Please enter a valid URL (e.g., http://localhost:3000 or https://example.com)',
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final posts = context.read<PostsProvider>();
    final settings = context.read<SettingsProvider>();

    final success = await auth.login(
      username: username,
      apiKey: apiKey,
      host: host,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      posts.clearAllPosts();
      final newHost = host ?? 'https://e926.net';
      await settings.setHost(newHost);
      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
    } else if (auth.error != null && mounted) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text(auth.error!),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark
                  ? CupertinoColors.black.withValues(alpha: 0.75)
                  : CupertinoColors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? CupertinoColors.white.withValues(alpha: 0.1)
                    : CupertinoColors.black.withValues(alpha: 0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withValues(alpha: 0.3),
                  blurRadius: 40,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          _AccountColors.primaryIndigo,
                          _AccountColors.primaryPurple,
                        ],
                      ).createShader(bounds),
                      child: const Text(
                        'Add Account',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Icon(
                          CupertinoIcons.xmark_circle_fill,
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Username field
                _DesktopTextField(
                  controller: _usernameController,
                  placeholder: 'Username',
                  icon: CupertinoIcons.person,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                // API Key field
                _DesktopTextField(
                  controller: _apiKeyController,
                  placeholder: 'API Key',
                  icon: CupertinoIcons.lock,
                  isDark: isDark,
                ),
                const SizedBox(height: 20),
                // Custom host toggle
                Row(
                  children: [
                    CupertinoSwitch(
                      value: _useCustomHost,
                      activeTrackColor: _AccountColors.primaryIndigo,
                      onChanged: (value) =>
                          setState(() => _useCustomHost = value),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Use custom host',
                      style: TextStyle(
                        color: isDark
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                      ),
                    ),
                  ],
                ),
                if (_useCustomHost) ...[
                  const SizedBox(height: 16),
                  _DesktopTextField(
                    controller: _hostController,
                    placeholder: 'Host URL',
                    icon: CupertinoIcons.globe,
                    isDark: isDark,
                  ),
                ],
                const SizedBox(height: 28),
                // Add button
                _DesktopAddDialogButton(
                  isLoading: _isLoading,
                  onPressed: _addAccount,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopTextField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final IconData icon;
  final bool isDark;

  const _DesktopTextField({
    required this.controller,
    required this.placeholder,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      prefix: Padding(
        padding: const EdgeInsets.only(left: 14),
        child: Icon(
          icon,
          size: 20,
          color: _AccountColors.primaryIndigo.withValues(alpha: 0.7),
        ),
      ),
      padding: const EdgeInsets.all(16),
      style: TextStyle(
        color: isDark ? CupertinoColors.white : CupertinoColors.black,
      ),
      placeholderStyle: TextStyle(
        color: CupertinoColors.secondaryLabel.resolveFrom(context),
      ),
      decoration: BoxDecoration(
        color: isDark
            ? CupertinoColors.white.withValues(alpha: 0.08)
            : CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? CupertinoColors.white.withValues(alpha: 0.1)
              : CupertinoColors.systemGrey5,
        ),
      ),
    );
  }
}

class _DesktopAddDialogButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _DesktopAddDialogButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  State<_DesktopAddDialogButton> createState() =>
      _DesktopAddDialogButtonState();
}

class _DesktopAddDialogButtonState extends State<_DesktopAddDialogButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.isLoading
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.isLoading ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isHovered
                  ? [_AccountColors.primaryPurple, _AccountColors.primaryViolet]
                  : [
                      _AccountColors.primaryIndigo,
                      _AccountColors.primaryPurple,
                    ],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: _AccountColors.primaryPurple.withValues(
                        alpha: 0.4,
                      ),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: widget.isLoading
                ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                : const Text(
                    'Add Account',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
