import 'package:flutter/cupertino.dart';
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
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({super.key});

  @override
  Widget build(BuildContext context) {
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
    return MediaQuery.of(context).size.width >= Breakpoints.desktop;
  }

  /// Helper to check if we're on a tablet-sized screen
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= Breakpoints.mobile && width < Breakpoints.desktop;
  }

  /// Helper to check if we're on a mobile-sized screen
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < Breakpoints.mobile;
  }
}
