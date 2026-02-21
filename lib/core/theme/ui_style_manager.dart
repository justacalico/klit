import 'package:flutter/cupertino.dart';

/// Enum representing the UI style of the application
enum UIStyle {
  /// Liquid Glass - macOS-style frosted glass effects with blur and animations
  /// Beautiful but more GPU-intensive
  liquidGlass,

  /// Material - Performance-focused UI with solid colors and minimal effects
  /// Optimized for lower-end devices and better battery life
  material,
}

/// Extension to get human-readable names for UI styles
extension UIStyleExtension on UIStyle {
  String get displayName {
    switch (this) {
      case UIStyle.liquidGlass:
        return 'Liquid Glass';
      case UIStyle.material:
        return 'Material';
    }
  }

  String get description {
    switch (this) {
      case UIStyle.liquidGlass:
        return 'Beautiful frosted glass effects with blur and animations';
      case UIStyle.material:
        return 'Performance-focused with solid colors and minimal effects';
    }
  }

  IconData get icon {
    switch (this) {
      case UIStyle.liquidGlass:
        return CupertinoIcons.sparkles;
      case UIStyle.material:
        return CupertinoIcons.bolt_fill;
    }
  }
}

/// Manager for UI style that can be accessed throughout the app
class UIStyleManager extends InheritedWidget {
  final UIStyle style;

  const UIStyleManager({super.key, required this.style, required super.child});

  static UIStyle of(BuildContext context) {
    final manager = context
        .dependOnInheritedWidgetOfExactType<UIStyleManager>();
    return manager?.style ?? UIStyle.liquidGlass;
  }

  static bool isLiquidGlass(BuildContext context) {
    return of(context) == UIStyle.liquidGlass;
  }

  static bool isMaterial(BuildContext context) {
    return of(context) == UIStyle.material;
  }

  @override
  bool updateShouldNotify(UIStyleManager oldWidget) {
    return style != oldWidget.style;
  }
}
