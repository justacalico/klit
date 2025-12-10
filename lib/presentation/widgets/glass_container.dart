import 'dart:ui';
import 'package:flutter/cupertino.dart';

/// A frosted glass container widget that provides macOS-style vibrancy effects.
/// 
/// This widget creates a translucent, blurred background effect similar to
/// macOS Big Sur and later's "liquid glass" design language.
class GlassContainer extends StatelessWidget {
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

  const GlassContainer({
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
}

/// A more subtle glass panel for sidebars and navigation areas
class GlassSidebar extends StatelessWidget {
  final Widget child;
  final double width;
  final bool isCollapsed;

  const GlassSidebar({
    super.key,
    required this.child,
    required this.width,
    this.isCollapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;

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
  }
}

/// A glass toolbar/header component
class GlassToolbar extends StatelessWidget {
  final Widget child;
  final double height;
  final bool showBorder;

  const GlassToolbar({
    super.key,
    required this.child,
    this.height = 52,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;

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
  }
}

/// A card with glass morphism effect
class GlassCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final bool isHoverable;

  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.borderRadius,
    this.isHoverable = true,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard>
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
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final effectiveBorderRadius = widget.borderRadius ?? BorderRadius.circular(16);

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
                  borderRadius: effectiveBorderRadius,
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
                          ? Colors.black.withValues(alpha: 0.3)
                          : Colors.black.withValues(alpha: 0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: effectiveBorderRadius,
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
                        borderRadius: effectiveBorderRadius,
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
}

/// A shimmer highlight effect for glass surfaces
class GlassShimmer extends StatefulWidget {
  final Widget child;
  final bool isActive;

  const GlassShimmer({
    super.key,
    required this.child,
    this.isActive = true,
  });

  @override
  State<GlassShimmer> createState() => _GlassShimmerState();
}

class _GlassShimmerState extends State<GlassShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(GlassShimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0x00FFFFFF),
                Color(0x33FFFFFF),
                Color(0x00FFFFFF),
              ],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value,
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
              transform: GradientRotation(_controller.value * 2 * 3.14159),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}

// Minimal Colors class for standalone use
class Colors {
  Colors._();
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color transparent = Color(0x00000000);
}
