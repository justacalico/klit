import 'dart:ui';
import 'package:flutter/cupertino.dart';
import '../../core/theme/ui_style_manager.dart';

/// An adaptive container that switches between liquid glass and material styles
/// based on the current UI style setting.
/// 
/// In Liquid Glass mode: Uses frosted glass blur effects
/// In Material mode: Uses solid colors for better performance
class AdaptiveContainer extends StatelessWidget {
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
              border: border ??
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
        border: border ??
            Border.all(
              color: isDark
                  ? const Color(0xFF3A3A3C)
                  : const Color(0xFFD1D1D6),
              width: 0.5,
            ),
      ),
      child: child,
    );
  }
}

/// An adaptive sidebar that switches between liquid glass and material styles
class AdaptiveSidebar extends StatelessWidget {
  final Widget child;
  final double width;
  final bool isCollapsed;

  const AdaptiveSidebar({
    super.key,
    required this.child,
    required this.width,
    this.isCollapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    final isLiquidGlass = UIStyleManager.isLiquidGlass(context);
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;

    if (isLiquidGlass) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF2C2C2E).withValues(alpha: 0.85),
                          const Color(0xFF1C1C1E).withValues(alpha: 0.95),
                        ]
                      : [
                          const Color(0xFFF8F8FA).withValues(alpha: 0.85),
                          const Color(0xFFF2F2F7).withValues(alpha: 0.95),
                        ],
                ),
                border: Border(
                  right: BorderSide(
                    color: isDark
                        ? const Color(0xFF3A3A3C).withValues(alpha: 0.3)
                        : const Color(0xFFD1D1D6).withValues(alpha: 0.5),
                    width: 0.5,
                  ),
                ),
              ),
              child: child,
            ),
          ),
        ),
      );
    } else {
      // Material style - solid colors, no blur
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
          border: Border(
            right: BorderSide(
              color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFD1D1D6),
              width: 0.5,
            ),
          ),
        ),
        child: child,
      );
    }
  }
}

/// An adaptive toolbar that switches between liquid glass and material styles
class AdaptiveToolbar extends StatelessWidget {
  final Widget child;
  final double height;
  final bool showBorder;

  const AdaptiveToolbar({
    super.key,
    required this.child,
    this.height = 52,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final isLiquidGlass = UIStyleManager.isLiquidGlass(context);
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;

    if (isLiquidGlass) {
      return ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        const Color(0xFF2C2C2E).withValues(alpha: 0.8),
                        const Color(0xFF1C1C1E).withValues(alpha: 0.9),
                      ]
                    : [
                        const Color(0xFFFFFFFF).withValues(alpha: 0.8),
                        const Color(0xFFF8F8FA).withValues(alpha: 0.9),
                      ],
              ),
              border: showBorder
                  ? Border(
                      bottom: BorderSide(
                        color: isDark
                            ? const Color(0xFF3A3A3C).withValues(alpha: 0.3)
                            : const Color(0xFFD1D1D6).withValues(alpha: 0.5),
                        width: 0.5,
                      ),
                    )
                  : null,
            ),
            child: child,
          ),
        ),
      );
    } else {
      // Material style - solid colors, no blur
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
          border: showBorder
              ? Border(
                  bottom: BorderSide(
                    color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFD1D1D6),
                    width: 0.5,
                  ),
                )
              : null,
        ),
        child: child,
      );
    }
  }
}

/// An adaptive card that switches between liquid glass and material styles
class AdaptiveCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final bool isHoverable;

  const AdaptiveCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.borderRadius,
    this.isHoverable = true,
  });

  @override
  State<AdaptiveCard> createState() => _AdaptiveCardState();
}

class _AdaptiveCardState extends State<AdaptiveCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHoverChanged(bool isHovered) {
    if (!widget.isHoverable) return;
    if (isHovered) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLiquidGlass = UIStyleManager.isLiquidGlass(context);
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final effectiveBorderRadius = widget.borderRadius ?? BorderRadius.circular(16);

    if (isLiquidGlass) {
      return _buildLiquidGlassCard(isDark, effectiveBorderRadius);
    } else {
      return _buildMaterialCard(isDark, effectiveBorderRadius);
    }
  }

  Widget _buildLiquidGlassCard(bool isDark, BorderRadius borderRadius) {
    return MouseRegion(
      onEnter: (_) => _onHoverChanged(true),
      onExit: (_) => _onHoverChanged(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? const Color(0xFF007AFF).withValues(
                              alpha: 0.15 * _glowAnimation.value,
                            )
                          : const Color(0xFF007AFF).withValues(
                              alpha: 0.1 * _glowAnimation.value,
                            ),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: isDark
                          ? const Color(0xFF000000).withValues(alpha: 0.3)
                          : const Color(0xFF000000).withValues(alpha: 0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: borderRadius,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: widget.padding,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  Color.lerp(
                                    const Color(0xFF2C2C2E),
                                    const Color(0xFF3A3A3C),
                                    _glowAnimation.value * 0.3,
                                  )!
                                      .withValues(alpha: 0.7),
                                  Color.lerp(
                                    const Color(0xFF1C1C1E),
                                    const Color(0xFF2C2C2E),
                                    _glowAnimation.value * 0.3,
                                  )!
                                      .withValues(alpha: 0.8),
                                ]
                              : [
                                  Color.lerp(
                                    const Color(0xFFFFFFFF),
                                    const Color(0xFFF0F5FF),
                                    _glowAnimation.value * 0.5,
                                  )!
                                      .withValues(alpha: 0.7),
                                  Color.lerp(
                                    const Color(0xFFF8F8FA),
                                    const Color(0xFFE8F0FF),
                                    _glowAnimation.value * 0.5,
                                  )!
                                      .withValues(alpha: 0.8),
                                ],
                        ),
                        borderRadius: borderRadius,
                        border: Border.all(
                          color: isDark
                              ? Color.lerp(
                                  const Color(0xFF3A3A3C),
                                  const Color(0xFF007AFF),
                                  _glowAnimation.value * 0.3,
                                )!
                                  .withValues(alpha: 0.5)
                              : Color.lerp(
                                  const Color(0xFFD1D1D6),
                                  const Color(0xFF007AFF),
                                  _glowAnimation.value * 0.3,
                                )!
                                  .withValues(alpha: 0.5),
                          width: 0.5,
                        ),
                      ),
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMaterialCard(bool isDark, BorderRadius borderRadius) {
    return MouseRegion(
      onEnter: (_) => _onHoverChanged(true),
      onExit: (_) => _onHoverChanged(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.isHoverable ? _scaleAnimation.value : 1.0,
              child: Container(
                padding: widget.padding,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white,
                  borderRadius: borderRadius,
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF3A3A3C)
                        : const Color(0xFFD1D1D6),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? const Color(0xFF000000).withValues(alpha: 0.2)
                          : const Color(0xFF000000).withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: widget.child,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Helper widget to conditionally apply backdrop blur only in liquid glass mode
class ConditionalBlur extends StatelessWidget {
  final Widget child;
  final double sigmaX;
  final double sigmaY;

  const ConditionalBlur({
    super.key,
    required this.child,
    this.sigmaX = 30.0,
    this.sigmaY = 30.0,
  });

  @override
  Widget build(BuildContext context) {
    if (UIStyleManager.isLiquidGlass(context)) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
        child: child,
      );
    }
    return child;
  }
}

/// Helper extension to get themed colors based on UI style
extension UIStyleColors on BuildContext {
  /// Get background color based on UI style and brightness
  Color get adaptiveBackground {
    final isDark = CupertinoTheme.brightnessOf(this) == Brightness.dark;
    final isLiquidGlass = UIStyleManager.isLiquidGlass(this);
    
    if (isLiquidGlass) {
      return isDark
          ? const Color(0xFF1C1C1E).withValues(alpha: 0.8)
          : const Color(0xFFF2F2F7).withValues(alpha: 0.8);
    } else {
      return isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
    }
  }

  /// Get card color based on UI style and brightness
  Color get adaptiveCardColor {
    final isDark = CupertinoTheme.brightnessOf(this) == Brightness.dark;
    final isLiquidGlass = UIStyleManager.isLiquidGlass(this);
    
    if (isLiquidGlass) {
      return isDark
          ? const Color(0xFF2C2C2E).withValues(alpha: 0.7)
          : CupertinoColors.white.withValues(alpha: 0.7);
    } else {
      return isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white;
    }
  }

  /// Get separator color based on UI style and brightness
  Color get adaptiveSeparatorColor {
    final isDark = CupertinoTheme.brightnessOf(this) == Brightness.dark;
    final isLiquidGlass = UIStyleManager.isLiquidGlass(this);
    
    if (isLiquidGlass) {
      return isDark
          ? const Color(0xFF3A3A3C).withValues(alpha: 0.5)
          : const Color(0xFFD1D1D6).withValues(alpha: 0.5);
    } else {
      return isDark ? const Color(0xFF3A3A3C) : const Color(0xFFD1D1D6);
    }
  }
}
