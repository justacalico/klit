import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'glass.dart';

class ColoredCard extends StatelessWidget {
  const ColoredCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.color,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.leading,
    this.trailing,
  });

  final Widget child;
  final Color? backgroundColor;
  final Color? color;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSecondaryTap;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final content = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color case final accent?)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
            if (leading != null) leading!,
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: child,
              ),
            ),
            if (trailing case final trailing?) trailing,
          ],
        );
    final body = (onTap != null || onLongPress != null)
        ? CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            onPressed: onTap,
            child: content,
          )
        : content;
    return GlassCard(
      margin: null,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      borderRadius: 8,
      elevation: 0,
      color: backgroundColor,
      child: body,
    );
  }
}

class IndentedCard extends StatelessWidget {
  const IndentedCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.color,
  });

  final Widget child;
  final Color? backgroundColor;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: null,
      padding: EdgeInsets.zero,
      borderRadius: 8,
      elevation: 0,
      color: backgroundColor,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Padding(padding: const EdgeInsets.only(left: 5), child: child),
          if (color != null)
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              child: Container(
                width: 5,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    bottomLeft: Radius.circular(4),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ThemedSectionCard extends StatelessWidget {
  const ThemedSectionCard({
    super.key,
    required this.child,
    this.margin,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.borderRadius = 16,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOled = theme.scaffoldBackgroundColor == Colors.black;
    final resolvedMargin = margin ?? const EdgeInsets.only(bottom: 8);

    if (isOled) {
      return GlassCard(
        margin: resolvedMargin,
        padding: padding,
        borderRadius: borderRadius,
        child: child,
      );
    }

    return Card(
      margin: resolvedMargin,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
