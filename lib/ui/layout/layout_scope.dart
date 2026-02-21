import 'package:flutter/widgets.dart';

import '../../core/constants/platform_config.dart';

/// Single source of truth for layout mode based on screen size.
/// Wraps the app so every route gets a consistent layout mode.
enum LayoutMode {
  desktop,
  mobile;

  bool get isDesktop => this == LayoutMode.desktop;
  bool get isMobile => this == LayoutMode.mobile;

  static LayoutMode fromWidth(double width) {
    if (PlatformConfig.forceDesktop) return LayoutMode.desktop;
    if (PlatformConfig.forceMobile) return LayoutMode.mobile;
    return width >= _desktopBreakpoint ? LayoutMode.desktop : LayoutMode.mobile;
  }

  static const double _desktopBreakpoint = 1024;
  static const double desktopBreakpoint = _desktopBreakpoint;
}

/// InheritedWidget that provides [LayoutMode] to the widget tree.
/// Mounted at app root so all pages read layout from one place.
class LayoutScope extends InheritedWidget {
  const LayoutScope({super.key, required this.mode, required super.child});

  final LayoutMode mode;

  static LayoutMode of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LayoutScope>();
    assert(scope != null, 'LayoutScope not found. Wrap app with LayoutScope.');
    return scope!.mode;
  }

  static LayoutMode? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LayoutScope>()?.mode;
  }

  @override
  bool updateShouldNotify(LayoutScope oldWidget) => mode != oldWidget.mode;
}
