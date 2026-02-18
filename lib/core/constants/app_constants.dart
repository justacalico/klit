import 'package:flutter/cupertino.dart';

/// App-wide constants
class AppConstants {
  AppConstants._();

  /// App name
  static const String appName = 'Klit';

  /// App version
  static const String appVersion = '1.0.0';

  /// Storage keys
  static const String activeAccountKey = 'active_account';
  static const String accountsKey = 'accounts';
  static const String hostKey = 'api_host';
  static const String themeKey = 'theme_mode';
  static const String gridSizeKey = 'grid_size';
  static const String safeModeKey = 'safe_mode';
  static const String leftHandedModeKey = 'left_handed_mode';
  static const String upvoteWhenFavoritedKey = 'upvote_when_favorited';
  static const String confettiOnFavoriteKey = 'confetti_on_favorite';
  static const String mobileNavOrderKey = 'mobile_nav_order';
  static const String desktopNavOrderKey = 'desktop_nav_order';
  static const String searchHistoryKey = 'search_history';
  static const String proxyConfigKey = 'proxy_config';
  static const String blacklistKey = 'user_blacklist';
  static const String blacklistEnabledKey = 'blacklist_enabled';
  static const String uiStyleKey = 'ui_style';
  static const String videoAutoPlayKey = 'video_auto_play';
  static const String videoMuteByDefaultKey = 'video_mute_by_default';
  static const String videoModeEnabledKey = 'video_mode_enabled';
  static const String searchHistoryEnabledKey = 'search_history_enabled';
  static const String scoreThresholdKey = 'score_threshold';

  /// Score threshold defaults
  static const int defaultScoreThreshold = 20;
  static const int minScoreThreshold = 0;
  static const int maxScoreThreshold = 100;

  /// Default grid columns
  static const int defaultGridColumns = 2;
  static const int maxGridColumns = 4;
  static const int minGridColumns = 1;

  /// Grid spacing and padding
  static const double defaultGridSpacing = 4.0;
  static const double minGridSpacing = 0.0;
  static const double maxGridSpacing = 16.0;
  static const double defaultGridPadding = 4.0;
  static const double minGridPadding = 0.0;
  static const double maxGridPadding = 24.0;

  /// Storage keys for grid settings
  static const String gridSpacingKey = 'grid_spacing';
  static const String gridPaddingKey = 'grid_padding';
  static const String gridAutoModeKey = 'grid_auto_mode';

  /// Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  /// Cache durations
  static const Duration imageCacheDuration = Duration(days: 7);
  static const Duration searchHistoryLimit = Duration(days: 30);

  /// Max search history items
  static const int maxSearchHistoryItems = 50;
}

/// iOS Human Interface Guidelines Colors
class AppColors {
  AppColors._();

  // Primary colors
  static const Color primaryBlue = Color(0xFF007AFF);
  static const Color primaryGreen = Color(0xFF34C759);
  static const Color primaryOrange = Color(0xFFFF9500);
  static const Color primaryRed = Color(0xFFFF3B30);
  static const Color primaryPurple = Color(0xFFAF52DE);
  static const Color primaryPink = Color(0xFFFF2D55);
  static const Color primaryTeal = Color(0xFF5AC8FA);
  static const Color primaryYellow = Color(0xFFFFCC00);

  // Light theme backgrounds
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSecondaryBackground = Color(0xFFF2F2F7);
  static const Color lightGroupedBackground = Color(0xFFF2F2F7);
  static const Color lightSeparator = Color(0xFFC6C6C8);

  // Dark theme backgrounds
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSecondaryBackground = Color(0xFF1C1C1E);
  static const Color darkGroupedBackground = Color(0xFF000000);
  static const Color darkSeparator = Color(0xFF38383A);

  // OLED theme backgrounds (pure black for power saving)
  static const Color oledBackground = Color(0xFF000000);
  static const Color oledSecondaryBackground = Color(0xFF0A0A0A);
  static const Color oledGroupedBackground = Color(0xFF000000);
  static const Color oledSeparator = Color(0xFF1C1C1C);

  // Rating colors
  static const Color safeColor = Color(0xFF34C759);
  static const Color questionableColor = Color(0xFFFF9500);
  static const Color explicitColor = Color(0xFFFF3B30);

  // Tag colors
  static const Color generalTagColor = Color(0xFF007AFF);
  static const Color artistTagColor = Color(0xFFFF9500);
  static const Color copyrightTagColor = Color(0xFFAF52DE);
  static const Color characterTagColor = Color(0xFF34C759);
  static const Color speciesTagColor = Color(0xFFFF3B30);
  static const Color metaTagColor = Color(0xFF8E8E93);
  static const Color lorTagColor = Color(0xFF5AC8FA);
}
