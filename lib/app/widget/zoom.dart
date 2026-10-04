// SPDX-License-Identifier: AGPL-3.0

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kilt/app/app.dart';
import 'package:kilt/settings/settings.dart';
import 'package:kilt/shared/shared.dart';

/// Browser-style UI zoom for desktop builds.
///
/// Lays the app out at a smaller or larger logical size and scales the result
/// back to the window, so the whole UI reflows the way a web page does under
/// page zoom. Ctrl (Cmd on macOS) + `+`/`-` steps through [AppZoom.levels]
/// and `0` returns to 100%. The factor persists in [Settings.zoomFactor].
class DesktopZoom extends StatefulWidget {
  const DesktopZoom({super.key, required this.child, this.enabled});

  /// The app content to zoom.
  final Widget child;

  /// Whether zooming is active. Defaults to
  /// [PlatformCapabilities.isDesktop]; overridable for tests.
  final bool? enabled;

  @override
  State<DesktopZoom> createState() => _DesktopZoomState();
}

class _DesktopZoomState extends State<DesktopZoom> {
  Timer? _badgeTimer;
  bool _badgeVisible = false;

  bool get _enabled => widget.enabled ?? PlatformCapabilities.isDesktop;

  @override
  void initState() {
    super.initState();
    if (_enabled) {
      HardwareKeyboard.instance.addHandler(_onKeyEvent);
    }
  }

  @override
  void dispose() {
    _badgeTimer?.cancel();
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    super.dispose();
  }

  bool _onKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;
    if (!mounted || !_enabled) return false;

    final keyboard = HardwareKeyboard.instance;
    // Exactly one modifier, like browsers: Ctrl on Linux/Windows, Cmd on macOS.
    // Shift is allowed (Ctrl+Shift+= is the "+" key on US layouts), Alt is not.
    final isMac = defaultTargetPlatform == TargetPlatform.macOS;
    final modifier = isMac ? keyboard.isMetaPressed : keyboard.isControlPressed;
    final other = isMac ? keyboard.isControlPressed : keyboard.isMetaPressed;
    if (!modifier || other || keyboard.isAltPressed) return false;

    final zoomFactor = context.read<Settings>().zoomFactor;
    final factor = AppZoom.clamped(zoomFactor.value);
    final key = event.logicalKey;
    final double next;
    if (key == LogicalKeyboardKey.equal ||
        key == LogicalKeyboardKey.add ||
        key == LogicalKeyboardKey.numpadAdd ||
        key == LogicalKeyboardKey.numpadEqual) {
      next = AppZoom.step(factor, 1);
    } else if (key == LogicalKeyboardKey.minus ||
        key == LogicalKeyboardKey.numpadSubtract) {
      next = AppZoom.step(factor, -1);
    } else if (key == LogicalKeyboardKey.digit0 ||
        key == LogicalKeyboardKey.numpad0) {
      next = 1.0;
    } else {
      return false;
    }
    if (next == factor) return false;
    zoomFactor.value = next;
    _flashBadge();
    return true;
  }

  void _flashBadge() {
    _badgeTimer?.cancel();
    setState(() => _badgeVisible = true);
    _badgeTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _badgeVisible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_enabled) return widget.child;

    // FittedBox sizes itself to the window and hit-tests the child in the
    // child's own coordinates, so pointer input lands correctly at every
    // zoom level (Transform.scale + OverflowBox leaves dead zones at the
    // edges for one of the two zoom directions).
    return ValueListenableBuilder<double>(
      valueListenable: context.read<Settings>().zoomFactor,
      builder: (context, value, child) {
        final factor = AppZoom.clamped(value);
        final mediaQuery = MediaQuery.of(context);
        final scaledSize = mediaQuery.size / factor;
        final content = MediaQuery(
          data: mediaQuery.copyWith(
            size: scaledSize,
            padding: mediaQuery.padding / factor,
            viewPadding: mediaQuery.viewPadding / factor,
            viewInsets: mediaQuery.viewInsets / factor,
            systemGestureInsets: mediaQuery.systemGestureInsets / factor,
          ),
          child: FittedBox(
            fit: BoxFit.fill,
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: scaledSize.width,
              height: scaledSize.height,
              child: widget.child,
            ),
          ),
        );
        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _badgeVisible ? 1.0 : 0.0,
                    duration: defaultAnimationDuration,
                    child: _ZoomBadge(percent: AppZoom.percent(factor)),
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

class _ZoomBadge extends StatelessWidget {
  const _ZoomBadge({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.inverseSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          '$percent%',
          style: TextStyle(color: colors.onInverseSurface),
        ),
      ),
    );
  }
}
