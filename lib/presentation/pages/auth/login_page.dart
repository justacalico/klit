import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../../app/routes.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/helpers.dart';
import '../../providers/providers.dart';

/// Login page for authentication
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _hostController = TextEditingController();

  bool _useCustomHost = false;
  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    _hostController.text = ApiConstants.defaultHost;
    // Defer session check to after first frame to avoid build-time errors
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkExistingSession();
    });
  }

  Future<void> _checkExistingSession() async {
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    await authProvider.initialize();

    if (authProvider.isLoggedIn && mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _apiKeyController.dispose();
    _hostController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final apiKey = _apiKeyController.text.trim();
    final host = _useCustomHost ? _hostController.text.trim() : null;

    // Validate inputs
    final usernameError = Validators.username(username);
    final apiKeyError = Validators.apiKey(apiKey);

    if (usernameError != null) {
      _showError(usernameError);
      return;
    }

    if (apiKeyError != null) {
      _showError(apiKeyError);
      return;
    }

    if (_useCustomHost) {
      final hostError = Validators.url(host);
      if (hostError != null) {
        _showError(hostError);
        return;
      }
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      username: username,
      apiKey: apiKey,
      host: host,
    );

    if (success && mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
    } else if (authProvider.error != null && mounted) {
      _showError(authProvider.error!);
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

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightSecondaryBackground,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              _buildHeader(),
              const SizedBox(height: 48),
              _buildForm(),
              const SizedBox(height: 32),
              _buildLoginButton(),
              const SizedBox(height: 16),
              _buildGuestButton(),
              const SizedBox(height: 24),
              _buildHelpText(),
            ],
          ),
        ),
      ),
    );
  }

  void _continueAsGuest() {
    final authProvider = context.read<AuthProvider>();
    authProvider.continueAsGuest();
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
  }

  Widget _buildGuestButton() {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 16),
      onPressed: _continueAsGuest,
      child: Text(
        'Continue as Guest',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'K',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: CupertinoColors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Welcome to Klit',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in with your e926 account',
          style: TextStyle(
            fontSize: 16,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.darkSecondaryBackground
        : CupertinoColors.white;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: _usernameController,
            placeholder: 'Username',
            icon: CupertinoIcons.person,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _apiKeyController,
            placeholder: 'API Key',
            icon: CupertinoIcons.lock,
            obscureText: _obscureApiKey,
            suffix: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),
              child: Icon(
                _obscureApiKey ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                size: 20,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildCustomHostToggle(),
          if (_useCustomHost) ...[
            const SizedBox(height: 16),
            _buildTextField(
              controller: _hostController,
              placeholder: 'API Host URL',
              icon: CupertinoIcons.globe,
              keyboardType: TextInputType.url,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    bool obscureText = false,
    Widget? suffix,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
  }) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      padding: const EdgeInsets.all(16),
      prefix: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Icon(icon, size: 20, color: CupertinoColors.secondaryLabel),
      ),
      suffix: suffix != null
          ? Padding(padding: const EdgeInsets.only(right: 8), child: suffix)
          : null,
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildCustomHostToggle() {
    return Row(
      children: [
        CupertinoSwitch(
          value: _useCustomHost,
          onChanged: (value) => setState(() => _useCustomHost = value),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Use custom host',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              Text(
                'Connect to a different e926-compatible server',
                style: TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return CupertinoButton.filled(
          padding: const EdgeInsets.symmetric(vertical: 16),
          borderRadius: BorderRadius.circular(12),
          onPressed: auth.isLoading ? null : _login,
          child: auth.isLoading
              ? const CupertinoActivityIndicator(color: CupertinoColors.white)
              : const Text(
                  'Sign In',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
        );
      },
    );
  }

  Widget _buildHelpText() {
    return Column(
      children: [
        Text(
          'Don\'t have an API key?',
          style: TextStyle(
            fontSize: 14,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
        const SizedBox(height: 4),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            // Could open a URL to e926 API key page
            _showApiKeyHelp();
          },
          child: const Text(
            'Learn how to get one',
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  void _showApiKeyHelp() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Getting an API Key'),
        message: const Text(
          '1. Log in to e926.net\n'
          '2. Go to Account → Manage API Access\n'
          '3. Create a new API key\n'
          '4. Copy the key and use it here',
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          isDestructiveAction: true,
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}
