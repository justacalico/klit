import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../../app/routes.dart';
import '../../../core/constants/constants.dart';
import '../../providers/providers.dart';

/// Account management page
class AccountManagementPage extends StatelessWidget {
  const AccountManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark
          ? AppColors.darkGroupedBackground
          : AppColors.lightGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Accounts'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _showAddAccountSheet(context),
          child: const Icon(CupertinoIcons.plus),
        ),
      ),
      child: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.accounts.isEmpty) {
              return _buildEmptyState(context);
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: auth.accounts.length,
              itemBuilder: (context, index) {
                final account = auth.accounts[index];
                final isActive = auth.currentAccount?.id == account.id;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSecondaryBackground
                        : CupertinoColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: isActive
                        ? Border.all(
                            color: AppColors.primaryBlue,
                            width: 2,
                          )
                        : null,
                  ),
                  child: CupertinoListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primaryBlue
                            : CupertinoColors.systemGrey,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Center(
                        child: Text(
                          account.username[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: CupertinoColors.white,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      account.username,
                      style: TextStyle(
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      Uri.parse(account.host).host,
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Active',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => _showAccountOptions(
                            context,
                            account.id,
                            isActive,
                          ),
                          child: const Icon(
                            CupertinoIcons.ellipsis_circle,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    onTap: isActive
                        ? null
                        : () async {
                            final success = await auth.switchAccount(account.id);
                            if (success && context.mounted) {
                              // Navigate to main and clear stack to refresh the app
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                AppRoutes.main,
                                (route) => false,
                              );
                            }
                          },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
          const Text(
            'No Accounts',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
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
            onPressed: () => _showAddAccountSheet(context),
            child: const Text('Add Account'),
          ),
        ],
      ),
    );
  }

  void _showAddAccountSheet(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => const _AddAccountSheet(),
    );
  }

  void _showAccountOptions(BuildContext context, String accountId, bool isActive) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          if (!isActive)
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.of(context).pop();
                final auth = context.read<AuthProvider>();
                final success = await auth.switchAccount(accountId);
                if (success && context.mounted) {
                  // Navigate to main and clear stack to refresh the app
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.main,
                    (route) => false,
                  );
                }
              },
              child: const Text('Switch to this account'),
            ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              _confirmRemoveAccount(context, accountId);
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

  void _confirmRemoveAccount(BuildContext context, String accountId) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Remove Account'),
        content: const Text('Are you sure you want to remove this account?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthProvider>().removeAccount(accountId);
            },
            child: const Text('Remove'),
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

  Future<void> _addAccount() async {
    if (_usernameController.text.isEmpty || _apiKeyController.text.isEmpty) {
      return;
    }

    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      username: _usernameController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
      host: _useCustomHost ? _hostController.text.trim() : null,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pop();
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
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: CupertinoTheme.brightnessOf(context) == Brightness.dark
            ? AppColors.darkSecondaryBackground
            : CupertinoColors.white,
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
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
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
                    onChanged: (value) => setState(() => _useCustomHost = value),
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
