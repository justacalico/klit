/// Platform configuration based on compile-time flags.
///
/// Use these flags when building:
/// - Desktop only: `flutter build <target> --dart-define=FORCE_DESKTOP=true`
/// - Mobile only: `flutter build <target> --dart-define=FORCE_MOBILE=true`
///
/// If neither flag is set, the app will use responsive layout based on screen size.
class PlatformConfig {
  PlatformConfig._();

  /// Force desktop UI regardless of screen size
  static const bool forceDesktop = bool.fromEnvironment(
    'FORCE_DESKTOP',
    defaultValue: false,
  );

  /// Force mobile UI regardless of screen size
  static const bool forceMobile = bool.fromEnvironment(
    'FORCE_MOBILE',
    defaultValue: false,
  );

  /// Whether to use responsive layout (neither flag is set)
  static bool get useResponsiveLayout => !forceDesktop && !forceMobile;

  /// Get a description of the current UI mode for debugging
  static String get uiModeDescription {
    if (forceDesktop) return 'Desktop (forced)';
    if (forceMobile) return 'Mobile (forced)';
    return 'Responsive';
  }
}
