import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material;

/// Wraps the app to allow live resize of the content area in debug mode.
/// Useful for testing responsive layouts without resizing the window.
///
/// Only active when [kDebugMode] is true. Use the bottom-right handle to drag
/// and resize; double-tap to reset to full size.
class ResponsiveFrame extends StatefulWidget {
  const ResponsiveFrame({
    super.key,
    required this.child,
    this.enabled = kDebugMode,
  });

  final Widget child;
  final bool enabled;

  @override
  State<ResponsiveFrame> createState() => _ResponsiveFrameState();
}

class _ResponsiveFrameState extends State<ResponsiveFrame> {
  Size? _overrideSize;
  static const double _handleSize = 24;
  static const double _minWidth = 320;
  static const double _minHeight = 480;

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      final w = _overrideSize?.width ?? _minWidth;
      final h = _overrideSize?.height ?? _minHeight;
      _overrideSize = Size(
        (w + details.delta.dx).clamp(_minWidth, double.infinity),
        (h - details.delta.dy).clamp(_minHeight, double.infinity),
      );
    });
  }

  void _onHandleTap() {
    if (_overrideSize != null) {
      setState(() => _overrideSize = null);
    }
  }

  void _onHandleDoubleTap() {
    setState(() => _overrideSize = null);
  }

  void _onHandlePanStart(DragStartDetails details) {
    if (_overrideSize == null && context.mounted) {
      final box = context.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        setState(() {
          _overrideSize = Size(
            (box.size.width * 0.6).clamp(_minWidth, box.size.width),
            (box.size.height * 0.7).clamp(_minHeight, box.size.height),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;
        final effectiveSize = _overrideSize != null
            ? Size(
                _overrideSize!.width.clamp(_minWidth, maxW),
                _overrideSize!.height.clamp(_minHeight, maxH),
              )
            : null;

        Widget content = widget.child;
        if (effectiveSize != null) {
          content = MediaQuery(
            data: MediaQuery.of(context).copyWith(
              size: effectiveSize,
              padding: EdgeInsets.zero,
              viewPadding: EdgeInsets.zero,
            ),
            child: SizedBox(
              width: effectiveSize.width,
              height: effectiveSize.height,
              child: ClipRect(child: widget.child),
            ),
          );
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: effectiveSize != null
                  ? Center(child: content)
                  : widget.child,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onPanStart: _onHandlePanStart,
                onPanUpdate: _onDragUpdate,
                onTap: _onHandleTap,
                onDoubleTap: _onHandleDoubleTap,
                child: Material(
                  color: const Color(0x00000000),
                  child: Container(
                    width: _handleSize,
                    height: _handleSize,
                    decoration: BoxDecoration(
                      color: CupertinoColors.activeBlue.withValues(alpha: 0.7),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                      ),
                    ),
                    child: Icon(
                      CupertinoIcons.arrow_up_left_arrow_down_right,
                      size: 14,
                      color: CupertinoColors.white.withValues(alpha: 0.95),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
