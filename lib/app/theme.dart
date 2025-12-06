import 'package:flutter/cupertino.dart';
import '../../core/constants/app_constants.dart';

/// App theme configuration with iOS Human Interface Guidelines
class AppTheme {
  AppTheme._();

  /// Light theme
  static CupertinoThemeData get lightTheme {
    return const CupertinoThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primaryBlue,
      primaryContrastingColor: CupertinoColors.white,
      scaffoldBackgroundColor: AppColors.lightBackground,
      barBackgroundColor: Color(0xF0F9F9F9),
    );
  }

  /// Dark theme
  static CupertinoThemeData get darkTheme {
    return const CupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryBlue,
      primaryContrastingColor: CupertinoColors.white,
      scaffoldBackgroundColor: AppColors.darkBackground,
      barBackgroundColor: Color(0xF01C1C1E),
    );
  }

  /// OLED theme (pure black for AMOLED screens)
  static CupertinoThemeData get oledTheme {
    return const CupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryBlue,
      primaryContrastingColor: CupertinoColors.white,
      scaffoldBackgroundColor: AppColors.oledBackground,
      barBackgroundColor: Color(0xF0000000),
    );
  }

  /// Get theme based on brightness
  static CupertinoThemeData getTheme(Brightness brightness) {
    return brightness == Brightness.dark ? darkTheme : lightTheme;
  }
}

/// Common text styles
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle headline = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.36,
  );

  static const TextStyle title1 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.35,
  );

  static const TextStyle title2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.38,
  );

  static const TextStyle title3 = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.41,
  );

  static const TextStyle body = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.normal,
    letterSpacing: -0.41,
  );

  static const TextStyle callout = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    letterSpacing: -0.32,
  );

  static const TextStyle subheadline = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    letterSpacing: -0.24,
  );

  static const TextStyle footnote = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    letterSpacing: -0.08,
  );

  static const TextStyle caption1 = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: 0,
  );

  static const TextStyle caption2 = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.07,
  );
}

/// Common box decorations
class AppDecorations {
  AppDecorations._();

  /// Card decoration for light theme
  static BoxDecoration cardLight = BoxDecoration(
    color: CupertinoColors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: CupertinoColors.black.withOpacity(0.08),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  /// Card decoration for dark theme
  static BoxDecoration cardDark = BoxDecoration(
    color: AppColors.darkSecondaryBackground,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: CupertinoColors.black.withOpacity(0.3),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  /// Get card decoration based on brightness
  static BoxDecoration getCard(Brightness brightness) {
    return brightness == Brightness.dark ? cardDark : cardLight;
  }

  /// Glassmorphism decoration
  static BoxDecoration glassmorphism(Brightness brightness) {
    return BoxDecoration(
      color: brightness == Brightness.dark
          ? CupertinoColors.black.withOpacity(0.5)
          : CupertinoColors.white.withOpacity(0.7),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: brightness == Brightness.dark
            ? CupertinoColors.white.withOpacity(0.1)
            : CupertinoColors.black.withOpacity(0.1),
      ),
    );
  }
}
