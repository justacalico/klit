import 'dart:io';

/// Provides information about what features are available on this Platform.
abstract final class PlatformCapabilities {
  static bool get isDesktop =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  /// Whether this platform supports background workers.
  /// False on desktop; on iOS requires 13+.
  static bool get hasBackgroundWorker {
    if (isDesktop) return false;
    if (Platform.isIOS) {
      final version = Platform.operatingSystemVersion.split(' ')[1];
      final majorVersion = int.parse(version.split('.')[0]);
      return majorVersion >= 13;
    }
    return Platform.isAndroid;
  }

  /// Whether this platform supports sending notifications.
  /// False on desktop.
  static bool get hasNotifications =>
      hasBackgroundWorker && [Platform.isAndroid, Platform.isIOS].any((e) => e);

  /// Whether this platform supports biometric / device lock.
  /// False on desktop.
  static bool get supportsBiometrics =>
      !isDesktop && [Platform.isAndroid, Platform.isIOS].any((e) => e);

  /// Whether this platform supports playing videos.
  static bool get hasVideos => true;

  /// Whether this platform supports secure display.
  /// This means that the platform supports hiding the app from the app switcher.
  static bool get hasSecureDisplay =>
      [Platform.isAndroid, Platform.isIOS].any((e) => e);

  /// Whether this platform supports deep links.
  static bool get hasDeepLinks =>
      [Platform.isAndroid, Platform.isIOS].any((e) => e);

  /// Whether in-app WebView login (cookie capture) is supported.
  /// Desktop uses external browser flow instead.
  static bool get supportsWebViewLogin =>
      [Platform.isAndroid, Platform.isIOS].any((e) => e);
}
