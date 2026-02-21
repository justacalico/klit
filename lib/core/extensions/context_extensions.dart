import 'package:flutter/cupertino.dart';

/// Extension methods for BuildContext
extension ContextExtensions on BuildContext {
  /// Get the current brightness
  Brightness get brightness => CupertinoTheme.brightnessOf(this);

  /// Check if dark mode
  bool get isDarkMode => brightness == Brightness.dark;

  /// Get screen size
  Size get screenSize => MediaQuery.sizeOf(this);

  /// Get screen width
  double get screenWidth => screenSize.width;

  /// Get screen height
  double get screenHeight => screenSize.height;

  /// Get safe area padding
  EdgeInsets get safeAreaPadding => MediaQuery.paddingOf(this);

  /// Get the CupertinoThemeData
  CupertinoThemeData get theme => CupertinoTheme.of(this);

  /// Get primary color
  Color get primaryColor => theme.primaryColor;

  /// Get text theme
  CupertinoTextThemeData get textTheme => theme.textTheme;

  /// Show a Cupertino dialog
  Future<T?> showCupertinoDialog<T>({
    required Widget child,
    bool barrierDismissible = true,
  }) {
    return showCupertinoModalPopup<T>(context: this, builder: (_) => child);
  }

  /// Show a snackbar-like notification
  void showNotification(String message, {bool isError = false}) {
    showCupertinoModalPopup(
      context: this,
      builder: (context) =>
          _NotificationBanner(message: message, isError: isError),
    );
  }
}

class _NotificationBanner extends StatefulWidget {
  final String message;
  final bool isError;

  const _NotificationBanner({required this.message, required this.isError});

  @override
  State<_NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<_NotificationBanner> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isError
                ? CupertinoColors.destructiveRed.withValues(alpha: 0.9)
                : CupertinoColors.activeGreen.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.message,
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
