import 'package:flutter/cupertino.dart';
import '../../core/constants/platform_config.dart';
import 'desktop_shell.dart';
import '../pages/main_tab_page.dart';

/// Breakpoints for responsive design
class Breakpoints {
  Breakpoints._();

  /// Mobile: < 768px
  static const double mobile = 768;

  /// Tablet: 768px - 1024px
  static const double tablet = 1024;

  /// Desktop: > 1024px
  static const double desktop = 1024;
}

/// Responsive layout wrapper that switches between mobile and desktop UI
///
/// Compile-time flags can force a specific UI:
/// - `--dart-define=FORCE_DESKTOP=true` - Always use desktop UI
/// - `--dart-define=FORCE_MOBILE=true` - Always use mobile UI
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({super.key});

  @override
  Widget build(BuildContext context) {
    // Check compile-time flags first
    if (PlatformConfig.forceDesktop) {
      return const DesktopShell();
    }

    if (PlatformConfig.forceMobile) {
      return const MainTabPage();
    }

    // Use responsive layout based on screen size
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use desktop layout for screens wider than desktop breakpoint
        if (constraints.maxWidth >= Breakpoints.desktop) {
          return const DesktopShell();
        }

        // Use mobile layout for smaller screens
        return const MainTabPage();
      },
    );
  }

  /// Helper to check if we're on a desktop-sized screen
  static bool isDesktop(BuildContext context) {
    if (PlatformConfig.forceDesktop) return true;
    if (PlatformConfig.forceMobile) return false;
    return MediaQuery.of(context).size.width >= Breakpoints.desktop;
  }

  /// Helper to check if we're on a tablet-sized screen
  static bool isTablet(BuildContext context) {
    if (PlatformConfig.forceDesktop || PlatformConfig.forceMobile) return false;
    final width = MediaQuery.of(context).size.width;
    return width >= Breakpoints.mobile && width < Breakpoints.desktop;
  }

  /// Helper to check if we're on a mobile-sized screen
  static bool isMobile(BuildContext context) {
    if (PlatformConfig.forceMobile) return true;
    if (PlatformConfig.forceDesktop) return false;
    return MediaQuery.of(context).size.width < Breakpoints.mobile;
  }
}
