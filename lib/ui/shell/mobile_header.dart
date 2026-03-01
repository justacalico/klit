import 'dart:ui';

import 'package:flutter/cupertino.dart';

import '../../core/constants/constants.dart';
import '../theme.dart';

/// Shared height tokens for mobile header rows.
abstract final class MobileHeaderHeights {
  static const double compact = 56;
  static const double large = 60;
}

enum MobileHeaderVariant { solid, glass }

/// Simple helper object used for anchoring overlays below stacked headers.
class MobileHeaderMetrics {
  const MobileHeaderMetrics({required this.safeTop, required this.barHeight});

  final double safeTop;
  final double barHeight;

  double get totalHeight => safeTop + barHeight;

  static MobileHeaderMetrics of(BuildContext context, {double barHeight = 56}) {
    return MobileHeaderMetrics(
      safeTop: MediaQuery.paddingOf(context).top,
      barHeight: barHeight,
    );
  }
}

/// Shared mobile header surface with notch/cutout-safe top inset handling.
class MobileHeaderSection extends StatelessWidget {
  const MobileHeaderSection({
    super.key,
    required this.child,
    this.barHeight = MobileHeaderHeights.compact,
    this.horizontalPadding = 16,
    this.variant = MobileHeaderVariant.solid,
    this.showBottomBorder = true,
    this.isDark = false,
    this.isOled = false,
    this.applySafeTopInset = true,
  });

  final Widget child;
  final double barHeight;
  final double horizontalPadding;
  final MobileHeaderVariant variant;
  final bool showBottomBorder;
  final bool isDark;
  final bool isOled;
  final bool applySafeTopInset;

  @override
  Widget build(BuildContext context) {
    final safeTop = applySafeTopInset ? MediaQuery.paddingOf(context).top : 0.0;
    final borderColor = AppColors.resolveSeparator(isDark, isOled: isOled);
    final childContent = SizedBox(
      height: barHeight,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: child,
      ),
    );

    if (variant == MobileHeaderVariant.glass) {
      if (isOled) {
        return Container(
          height: safeTop + barHeight,
          padding: EdgeInsets.only(top: safeTop),
          decoration: BoxDecoration(
            color: AppColors.oledBackground,
            border: showBottomBorder
                ? Border(bottom: BorderSide(color: borderColor, width: 0.5))
                : null,
          ),
          child: childContent,
        );
      }
      return ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: safeTop + barHeight,
            padding: EdgeInsets.only(top: safeTop),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF18181B).withValues(alpha: 0.85),
                        const Color(0xFF1F1F23).withValues(alpha: 0.9),
                      ]
                    : [
                        const Color(0xFFFFFFFF).withValues(alpha: 0.85),
                        const Color(0xFFFAFAFC).withValues(alpha: 0.9),
                      ],
              ),
              border: showBottomBorder
                  ? Border(bottom: BorderSide(color: borderColor, width: 0.5))
                  : null,
            ),
            child: childContent,
          ),
        ),
      );
    }

    return Container(
      height: safeTop + barHeight,
      padding: EdgeInsets.only(top: safeTop),
      decoration: BoxDecoration(
        color: AppColors.resolveSecondaryBackground(isDark, isOled: isOled),
        border: showBottomBorder
            ? Border(bottom: BorderSide(color: borderColor, width: 0.5))
            : null,
      ),
      child: childContent,
    );
  }
}

/// Shared mobile title bar.
class MobileHeader extends StatelessWidget {
  const MobileHeader({
    super.key,
    required this.title,
    this.icon,
    this.leading,
    this.actions,
    this.barHeight = MobileHeaderHeights.large,
    this.variant = MobileHeaderVariant.solid,
    this.isDark = false,
    this.isOled = false,
    this.applySafeTopInset = true,
  });

  final String title;
  final IconData? icon;
  final Widget? leading;
  final List<Widget>? actions;
  final double barHeight;
  final MobileHeaderVariant variant;
  final bool isDark;
  final bool isOled;
  final bool applySafeTopInset;

  @override
  Widget build(BuildContext context) {
    return MobileHeaderSection(
      barHeight: barHeight,
      variant: variant,
      isDark: isDark,
      isOled: isOled,
      applySafeTopInset: applySafeTopInset,
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 12),
          ] else if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [UIColors.primaryIndigo, UIColors.primaryPurple],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: CupertinoColors.white),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? CupertinoColors.white : const Color(0xFF1F2937),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}
