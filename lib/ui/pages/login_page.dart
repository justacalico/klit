import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app/routes.dart';
import '../../core/constants/constants.dart';
import '../../core/input/input.dart';
import '../../core/utils/helpers.dart';
import '../../providers/providers.dart';
import '../layout/layout_scope.dart';

/// Login page for authentication
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin, GamepadInputMixin {
  final _usernameController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _hostController = TextEditingController();

  // Focus nodes for controller navigation
  final _usernameFocusNode = FocusNode();
  final _apiKeyFocusNode = FocusNode();
  final _hostFocusNode = FocusNode();

  // Controller navigation state
  int _focusedIndex =
      0; // 0: username, 1: apiKey, 2: customHost toggle, 3: host field, 4: login, 5: guest
  bool _showControllerHints = false;

  bool _useCustomHost = false;
  bool _obscureApiKey = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _hostController.text = ApiConstants.defaultHost;

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    _animationController.forward();

    // Defer session check to after first frame to avoid build-time errors
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkExistingSession();
    });

    // Check if controller is connected
    _showControllerHints = gamepad.isConnected;

    // Listen for controller connection changes
    gamepad.stateChanges.listen((state) {
      if (mounted && state.isConnected != _showControllerHints) {
        setState(() => _showControllerHints = state.isConnected);
      }
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

  /// Get the maximum focusable index based on custom host state
  int get _maxFocusIndex => _useCustomHost ? 5 : 4;

  /// Handle gamepad D-pad navigation
  @override
  void onGamepadDirection(GamepadDirection direction) {
    if (!mounted) return;

    switch (direction) {
      case GamepadDirection.up:
        _moveFocus(-1);
      case GamepadDirection.down:
        _moveFocus(1);
      default:
        break;
    }
  }

  /// Handle gamepad button presses
  @override
  void onGamepadButton(GamepadButton button) {
    if (!mounted) return;

    switch (button) {
      case GamepadButton.a:
        // Activate/select the focused item
        _activateFocusedItem();
        HapticFeedback.mediumImpact();

      case GamepadButton.b:
        // Toggle API key visibility when on API key field
        if (_focusedIndex == 1) {
          setState(() => _obscureApiKey = !_obscureApiKey);
          HapticFeedback.lightImpact();
        }

      case GamepadButton.y:
        // Quick action: Continue as guest
        _continueAsGuest();
        HapticFeedback.mediumImpact();

      case GamepadButton.x:
        // Toggle custom host
        setState(() => _useCustomHost = !_useCustomHost);
        HapticFeedback.lightImpact();

      default:
        break;
    }
  }

  /// Move focus up or down
  void _moveFocus(int delta) {
    setState(() {
      _focusedIndex = (_focusedIndex + delta).clamp(0, _maxFocusIndex);
    });
    HapticFeedback.selectionClick();
    _updateTextFieldFocus();
  }

  /// Update text field focus based on focused index
  void _updateTextFieldFocus() {
    // Unfocus all first
    _usernameFocusNode.unfocus();
    _apiKeyFocusNode.unfocus();
    _hostFocusNode.unfocus();

    // Focus the appropriate field
    switch (_focusedIndex) {
      case 0:
        _usernameFocusNode.requestFocus();
      case 1:
        _apiKeyFocusNode.requestFocus();
      case 3 when _useCustomHost:
        _hostFocusNode.requestFocus();
    }
  }

  /// Activate the currently focused item
  void _activateFocusedItem() {
    switch (_focusedIndex) {
      case 0:
        _usernameFocusNode.requestFocus();
      case 1:
        _apiKeyFocusNode.requestFocus();
      case 2:
        // Toggle custom host
        setState(() => _useCustomHost = !_useCustomHost);
      case 3 when _useCustomHost:
        _hostFocusNode.requestFocus();
      case 3 when !_useCustomHost:
        // This is the login button when custom host is disabled
        _login();
      case 4 when _useCustomHost:
        // Login button when custom host is enabled
        _login();
      case 4 when !_useCustomHost:
        // Guest button when custom host is disabled
        _continueAsGuest();
      case 5:
        // Guest button when custom host is enabled
        _continueAsGuest();
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _apiKeyController.dispose();
    _hostController.dispose();
    _usernameFocusNode.dispose();
    _apiKeyFocusNode.dispose();
    _hostFocusNode.dispose();
    _animationController.dispose();
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
    final isOled = context.watch<SettingsProvider>().themeMode == 3;
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;
    final mode = LayoutScope.of(context);

    return KeyedSubtree(
      key: const ValueKey('login-page'),
      child: CupertinoPageScaffold(
        backgroundColor: AppColors.resolveScaffoldBackground(isDark, isOled: isOled),
        child: Stack(
          children: [
            _buildAnimatedBackground(isDark),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: mode.isDesktop ? size.width * 0.25 : 24,
                    vertical: 24,
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: isLandscape && mode.isMobile
                          ? _buildLandscapeLayout(isDark, isOled)
                          : _buildPortraitLayout(isDark, isOled),
                    ),
                  ),
                ),
              ),
            ),

            // Controller hints overlay
            if (_showControllerHints)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: _buildControllerHints(isDark, isOled),
              ),
          ],
        ),
      ),
    );
  }

  /// Builds the controller button hints overlay
  Widget _buildControllerHints(bool isDark, bool isOled) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.resolveSecondaryBackground(isDark, isOled: isOled)
              .withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E7EB),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHintItem('D-Pad', 'Navigate', isDark),
            const SizedBox(width: 20),
            _buildHintItem(
              'A',
              'Select',
              isDark,
              color: const Color(0xFF22C55E),
            ),
            const SizedBox(width: 20),
            _buildHintItem(
              'Y',
              'Guest',
              isDark,
              color: const Color(0xFFEAB308),
            ),
            const SizedBox(width: 20),
            _buildHintItem(
              'X',
              'Custom Host',
              isDark,
              color: const Color(0xFF3B82F6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHintItem(
    String button,
    String label,
    bool isDark, {
    Color? color,
  }) {
    final buttonColor =
        color ?? (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: buttonColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: buttonColor.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Text(
            button,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: buttonColor,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFFE4E4E7) : const Color(0xFF3F3F46),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedBackground(bool isDark) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _BackgroundPainter(
          isDark: isDark,
          animation: _animationController,
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(bool isDark, bool isOled) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLogo(isDark),
          const SizedBox(height: 16),
          _buildWelcomeText(isDark),
          const SizedBox(height: 40),
          _buildForm(isDark, isOled),
          const SizedBox(height: 24),
          _buildLoginButton(),
          const SizedBox(height: 12),
          _buildGuestButton(isDark),
          const SizedBox(height: 32),
          _buildHelpText(isDark),
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout(bool isDark, bool isOled) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLogo(isDark, size: 100),
              const SizedBox(height: 16),
              _buildWelcomeText(isDark),
            ],
          ),
        ),
        const SizedBox(width: 48),
        Expanded(
          flex: 3,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildForm(isDark, isOled),
              const SizedBox(height: 24),
              _buildLoginButton(),
              const SizedBox(height: 12),
              _buildGuestButton(isDark),
              const SizedBox(height: 24),
              _buildHelpText(isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogo(bool isDark, {double size = 120}) {
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6366F1), // Indigo
              Color(0xFF8B5CF6), // Purple
              Color(0xFFA855F7), // Violet
            ],
          ),
          borderRadius: BorderRadius.circular(size * 0.28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
              blurRadius: 30,
              offset: const Offset(0, 15),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.2),
              blurRadius: 60,
              offset: const Offset(0, 30),
              spreadRadius: -10,
            ),
          ],
        ),
        child: Center(
          child: Text(
            'K',
            style: TextStyle(
              fontSize: size * 0.5,
              fontWeight: FontWeight.w700,
              color: CupertinoColors.white,
              letterSpacing: -2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeText(bool isDark) {
    return Column(
      children: [
        Text(
          'Welcome to Klit',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: isDark ? CupertinoColors.white : const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your gateway to e926',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            color: isDark
                ? CupertinoColors.systemGrey
                : CupertinoColors.systemGrey,
          ),
        ),
      ],
    );
  }

  void _continueAsGuest() {
    final authProvider = context.read<AuthProvider>();
    authProvider.continueAsGuest();
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
  }

  Widget _buildGuestButton(bool isDark) {
    // Guest button focus index depends on custom host state
    final guestFocusIndex = _useCustomHost ? 5 : 4;
    final isGuestFocused =
        _showControllerHints && _focusedIndex == guestFocusIndex;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: isGuestFocused
            ? Border.all(color: const Color(0xFF8B5CF6), width: 2)
            : null,
        boxShadow: isGuestFocused
            ? [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 16),
        onPressed: _continueAsGuest,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.arrow_right_circle,
              size: 18,
              color: isGuestFocused
                  ? const Color(0xFF8B5CF6)
                  : (isDark
                        ? CupertinoColors.systemGrey
                        : CupertinoColors.systemGrey),
            ),
            const SizedBox(width: 8),
            Text(
              'Continue as Guest',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isGuestFocused
                    ? const Color(0xFF8B5CF6)
                    : (isDark
                          ? CupertinoColors.systemGrey
                          : CupertinoColors.systemGrey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(bool isDark, bool isOled) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.resolveSecondaryBackground(isDark, isOled: isOled).withValues(alpha: 0.8)
            : CupertinoColors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? CupertinoColors.systemGrey.darkColor.withValues(alpha: 0.3)
              : CupertinoColors.systemGrey.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Account', CupertinoIcons.person_circle, isDark),
          const SizedBox(height: 16),
          _buildFocusableTextField(
            controller: _usernameController,
            focusNode: _usernameFocusNode,
            placeholder: 'Username',
            icon: CupertinoIcons.person,
            textInputAction: TextInputAction.next,
            isDark: isDark,
            isOled: isOled,
            isFocused: _showControllerHints && _focusedIndex == 0,
          ),
          const SizedBox(height: 12),
          _buildFocusableTextField(
            controller: _apiKeyController,
            focusNode: _apiKeyFocusNode,
            placeholder: 'API Key',
            icon: CupertinoIcons.lock,
            obscureText: _obscureApiKey,
            isDark: isDark,
            isOled: isOled,
            isFocused: _showControllerHints && _focusedIndex == 1,
            suffix: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),
              minimumSize: Size(0, 0),
              child: Icon(
                _obscureApiKey ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                size: 20,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildCustomHostSection(isDark, isOled),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF8B5CF6)),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? CupertinoColors.white : const Color(0xFF374151),
          ),
        ),
      ],
    );
  }

  Widget _buildFocusableTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String placeholder,
    required IconData icon,
    required bool isDark,
    required bool isOled,
    required bool isFocused,
    bool obscureText = false,
    Widget? suffix,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
  }) {
    final bgColor = AppColors.resolveSecondaryBackground(isDark, isOled: isOled);
    final borderColor = isFocused
        ? const Color(0xFF8B5CF6)
        : (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E7EB));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: isFocused ? 2 : 1),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: CupertinoTextField(
        controller: controller,
        focusNode: focusNode,
        placeholder: placeholder,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        style: TextStyle(
          fontSize: 16,
          color: isDark ? CupertinoColors.white : const Color(0xFF1F2937),
        ),
        placeholderStyle: TextStyle(
          fontSize: 16,
          color: isDark
              ? CupertinoColors.systemGrey
              : CupertinoColors.systemGrey,
        ),
        prefix: Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Icon(
            icon,
            size: 20,
            color: isFocused
                ? const Color(0xFF8B5CF6)
                : (isDark
                      ? CupertinoColors.systemGrey
                      : CupertinoColors.systemGrey),
          ),
        ),
        suffix: suffix != null
            ? Padding(padding: const EdgeInsets.only(right: 14), child: suffix)
            : null,
        decoration: const BoxDecoration(),
      ),
    );
  }

  Widget _buildCustomHostSection(bool isDark, bool isOled) {
    final isToggleFocused = _showControllerHints && _focusedIndex == 2;
    final isHostFieldFocused =
        _showControllerHints && _focusedIndex == 3 && _useCustomHost;

    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _useCustomHost = !_useCustomHost),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.resolveSecondaryBackground(isDark, isOled: isOled),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isToggleFocused
                    ? const Color(0xFF8B5CF6)
                    : (_useCustomHost
                          ? const Color(0xFF8B5CF6).withValues(alpha: 0.5)
                          : (isDark
                                ? const Color(0xFF3A3A3C)
                                : const Color(0xFFE5E7EB))),
                width: isToggleFocused ? 2 : 1,
              ),
              boxShadow: isToggleFocused
                  ? [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _useCustomHost
                        ? const Color(0xFF8B5CF6)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _useCustomHost
                          ? const Color(0xFF8B5CF6)
                          : CupertinoColors.systemGrey,
                      width: 2,
                    ),
                  ),
                  child: _useCustomHost
                      ? const Icon(
                          CupertinoIcons.checkmark,
                          size: 16,
                          color: CupertinoColors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Custom Server',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? CupertinoColors.white
                              : const Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Connect to a different e926-compatible server',
                        style: TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _useCustomHost
                      ? CupertinoIcons.chevron_up
                      : CupertinoIcons.chevron_down,
                  size: 16,
                  color: CupertinoColors.systemGrey,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _useCustomHost
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _buildFocusableTextField(
              controller: _hostController,
              focusNode: _hostFocusNode,
              placeholder: 'API Host URL',
              icon: CupertinoIcons.globe,
              keyboardType: TextInputType.url,
              isDark: isDark,
              isOled: isOled,
              isFocused: isHostFieldFocused,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    // Login button focus index depends on custom host state
    final loginFocusIndex = _useCustomHost ? 4 : 3;
    final isLoginFocused =
        _showControllerHints && _focusedIndex == loginFocusIndex;

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF6366F1,
                ).withValues(alpha: isLoginFocused ? 0.6 : 0.4),
                blurRadius: isLoginFocused ? 24 : 16,
                offset: const Offset(0, 6),
                spreadRadius: isLoginFocused ? 2 : 0,
              ),
            ],
            border: isLoginFocused
                ? Border.all(
                    color: CupertinoColors.white.withValues(alpha: 0.5),
                    width: 2,
                  )
                : null,
          ),
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 16),
            borderRadius: BorderRadius.circular(14),
            color: Colors.transparent,
            onPressed: auth.isLoading ? null : _login,
            child: auth.isLoading
                ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        CupertinoIcons.arrow_right,
                        size: 18,
                        color: CupertinoColors.white,
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildHelpText(bool isDark) {
    return Center(
      child: Column(
        children: [
          Text(
            'Don\'t have an API key?',
            style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey),
          ),
          const SizedBox(height: 4),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _showApiKeyHelp,
            minimumSize: Size(0, 0),
            child: const Text(
              'Learn how to get one',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF8B5CF6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showApiKeyHelp() {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final isOled = context.read<SettingsProvider>().themeMode == 3;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.resolveSecondaryBackground(isDark, isOled: isOled),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                CupertinoIcons.lock_shield,
                size: 32,
                color: Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Getting an API Key',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? CupertinoColors.white : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            _buildStep('1', 'Log in to e926.net', isDark),
            _buildStep('2', 'Go to Account → Manage API Access', isDark),
            _buildStep('3', 'Create a new API key', isDark),
            _buildStep('4', 'Copy the key and use it here', isDark),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                color: const Color(0xFF8B5CF6),
                borderRadius: BorderRadius.circular(12),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Got it',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8B5CF6),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? CupertinoColors.white : const Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for animated background
class _BackgroundPainter extends CustomPainter {
  final bool isDark;
  final Animation<double> animation;

  _BackgroundPainter({required this.isDark, required this.animation})
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Draw gradient orbs
    final colors = isDark
        ? [
            const Color(0xFF6366F1).withValues(alpha: 0.15),
            const Color(0xFF8B5CF6).withValues(alpha: 0.1),
            const Color(0xFFA855F7).withValues(alpha: 0.08),
          ]
        : [
            const Color(0xFF6366F1).withValues(alpha: 0.08),
            const Color(0xFF8B5CF6).withValues(alpha: 0.06),
            const Color(0xFFA855F7).withValues(alpha: 0.05),
          ];

    // Animated positions based on animation value
    final animValue = animation.value;

    // Top right orb
    paint.shader =
        RadialGradient(
          colors: [colors[0], colors[0].withValues(alpha: 0)],
        ).createShader(
          Rect.fromCircle(
            center: Offset(
              size.width * 0.85 + math.sin(animValue * math.pi * 2) * 20,
              size.height * 0.15 + math.cos(animValue * math.pi * 2) * 20,
            ),
            radius: size.width * 0.5,
          ),
        );
    canvas.drawCircle(
      Offset(
        size.width * 0.85 + math.sin(animValue * math.pi * 2) * 20,
        size.height * 0.15 + math.cos(animValue * math.pi * 2) * 20,
      ),
      size.width * 0.5,
      paint,
    );

    // Bottom left orb
    paint.shader =
        RadialGradient(
          colors: [colors[1], colors[1].withValues(alpha: 0)],
        ).createShader(
          Rect.fromCircle(
            center: Offset(
              size.width * 0.15 + math.cos(animValue * math.pi * 2) * 15,
              size.height * 0.85 + math.sin(animValue * math.pi * 2) * 15,
            ),
            radius: size.width * 0.4,
          ),
        );
    canvas.drawCircle(
      Offset(
        size.width * 0.15 + math.cos(animValue * math.pi * 2) * 15,
        size.height * 0.85 + math.sin(animValue * math.pi * 2) * 15,
      ),
      size.width * 0.4,
      paint,
    );

    // Center orb
    paint.shader =
        RadialGradient(
          colors: [colors[2], colors[2].withValues(alpha: 0)],
        ).createShader(
          Rect.fromCircle(
            center: Offset(
              size.width * 0.5,
              size.height * 0.5 + math.sin(animValue * math.pi * 2 + 1) * 30,
            ),
            radius: size.width * 0.35,
          ),
        );
    canvas.drawCircle(
      Offset(
        size.width * 0.5,
        size.height * 0.5 + math.sin(animValue * math.pi * 2 + 1) * 30,
      ),
      size.width * 0.35,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}
