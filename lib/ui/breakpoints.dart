import 'package:flutter/widgets.dart';

import '../core/constants/platform_config.dart';

/// Breakpoints for responsive design.
/// ≥ 1024: sidebar (desktop); < 1024: navbar (mobile).
class Breakpoints {
  Breakpoints._();

  static const double desktop = 1024;
  static const double tablet = 768;
}

extension BreakpointCheck on num {
  bool get isDesktop => this >= Breakpoints.desktop;
  bool get isMobile => this < Breakpoints.desktop;
}

/// Check if current context should use desktop layout (sidebar).
bool isDesktopLayout(double width) {
  if (PlatformConfig.forceDesktop) return true;
  if (PlatformConfig.forceMobile) return false;
  return width >= Breakpoints.desktop;
}

/// Check if context has desktop-sized width.
bool isDesktop(BuildContext context) {
  if (PlatformConfig.forceDesktop) return true;
  if (PlatformConfig.forceMobile) return false;
  return MediaQuery.sizeOf(context).width >= Breakpoints.desktop;
}
