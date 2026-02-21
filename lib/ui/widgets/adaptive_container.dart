import 'dart:ui';

import 'package:flutter/cupertino.dart';

import '../../core/theme/ui_style_manager.dart';

/// An adaptive container that switches between liquid glass and material styles
/// based on the current UI style setting.
///
/// In Liquid Glass mode: Uses frosted glass blur effects
/// In Material mode: Uses solid colors for better performance
class AdaptiveContainer extends StatelessWidget {
  const AdaptiveContainer({
    super.key,
    required this.child,
    this.blur = 30.0,
    this.opacity = 0.7,
    this.tintColor,
    this.borderRadius,
    this.border,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.constraints,
  });

  final Widget child;
  final double blur;
  final double opacity;
  final Color? tintColor;
  final BorderRadius? borderRadius;
  final Border? border;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;

  @override
  Widget build(BuildContext context) {
    final isLiquidGlass = UIStyleManager.isLiquidGlass(context);

    if (isLiquidGlass) {
      return _buildLiquidGlass(context);
    } else {
      return _buildMaterial(context);
    }
  }

  Widget _buildLiquidGlass(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;

    final defaultTint = isDark
        ? const Color(0xFF1C1C1E).withValues(alpha: opacity)
        : const Color(0xFFF2F2F7).withValues(alpha: opacity);

    final effectiveTint = tintColor?.withValues(alpha: opacity) ?? defaultTint;
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(12);

    return Container(
      width: width,
      height: height,
      margin: margin,
      constraints: constraints,
      child: ClipRRect(
        borderRadius: effectiveBorderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: effectiveTint,
              borderRadius: effectiveBorderRadius,
              border:
                  border ??
                  Border.all(
                    color: isDark
                        ? const Color(0xFF3A3A3C).withValues(alpha: 0.5)
                        : const Color(0xFFD1D1D6).withValues(alpha: 0.5),
                    width: 0.5,
                  ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildMaterial(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;

    final defaultColor = isDark
        ? const Color(0xFF1C1C1E)
        : const Color(0xFFF2F2F7);

    final effectiveColor = tintColor ?? defaultColor;
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(12);

    return Container(
      width: width,
      height: height,
      margin: margin,
      constraints: constraints,
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: effectiveBorderRadius,
        border:
            border ??
            Border.all(
              color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFD1D1D6),
              width: 0.5,
            ),
      ),
      child: child,
    );
  }
}
