// SPDX-License-Identifier: AGPL-3.0

import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    this.child,
    this.color,
    this.borderRadius = 20,
    this.padding,
    this.margin,
    this.blurSigma = 14,
  });

  final Widget? child;
  final Color? color;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final base = isDark
        ? Color.lerp(theme.canvasColor, Colors.white, 0.08)!
        : theme.colorScheme.surfaceContainerHigh;
    final bg = (color ?? base).withValues(alpha: 0.7);
    final radius = BorderRadius.circular(borderRadius);

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: radius,
              border: Border.all(
                color: CupertinoColors.systemGrey.withValues(alpha: 0.18),
                width: 0.5,
              ),
            ),
            child: Padding(
              padding: padding ?? EdgeInsets.zero,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    this.child,
    this.margin,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 16,
    this.blurSigma = 14,
    this.color,
    this.elevation = 8,
  });

  final Widget? child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blurSigma;
  final Color? color;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shadowColor = theme.shadowColor.withAlpha(77);

    return GlassSurface(
      margin: margin,
      padding: padding,
      borderRadius: borderRadius,
      blurSigma: blurSigma,
      color: color,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: elevation > 0
              ? [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: elevation * 2,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: child,
      ),
    );
  }
}

class GlassBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassBar({
    super.key,
    this.child,
    this.height = 56,
    this.borderRadius = 24,
    this.margin,
    this.blurSigma = 14,
    this.color,
  });

  final Widget? child;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;
  final double blurSigma;
  final Color? color;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: GlassSurface(
          margin: margin,
          borderRadius: borderRadius,
          blurSigma: blurSigma,
          color: color,
          padding: EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}
