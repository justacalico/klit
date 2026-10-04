// SPDX-License-Identifier: AGPL-3.0

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/app/app.dart';
import 'package:kilt/settings/settings.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AppZoom', () {
    test('steps in and out through the levels', () {
      expect(AppZoom.step(1, 1), 1.1);
      expect(AppZoom.step(1.1, 1), 1.25);
      expect(AppZoom.step(1, -1), 0.9);
      expect(AppZoom.step(0.9, -1), 0.8);
    });

    test('clamps at both ends', () {
      expect(AppZoom.step(5, 1), 5);
      expect(AppZoom.step(0.25, -1), 0.25);
    });

    test('snaps to the nearest level from arbitrary values', () {
      expect(AppZoom.step(1.05, 1), 1.1);
      expect(AppZoom.step(1.05, -1), 1);
      expect(AppZoom.step(0.99, 1), 1);
    });

    test('percent rounds the factor', () {
      expect(AppZoom.percent(1), 100);
      expect(AppZoom.percent(1.1), 110);
      expect(AppZoom.percent(0.33), 33);
    });

    test('clamped keeps factors inside the level range', () {
      expect(AppZoom.clamped(10), 5);
      expect(AppZoom.clamped(0.1), 0.25);
      expect(AppZoom.clamped(1.3), 1.3);
    });
  });

  group('DesktopZoom', () {
    late SharedPreferences prefs;
    late Settings settings;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      settings = Settings(prefs);
    });

    Future<Size> pumpZoom(WidgetTester tester, {bool? enabled}) async {
      Size? innerSize;
      await tester.pumpWidget(
        Provider<Settings>.value(
          value: settings,
          child: MaterialApp(
            builder: (context, child) =>
                DesktopZoom(enabled: enabled, child: child!),
            home: Builder(
              builder: (context) {
                innerSize = MediaQuery.of(context).size;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );
      return innerSize!;
    }

    Future<void> pressCtrlKey(
      WidgetTester tester,
      LogicalKeyboardKey key, {
      PhysicalKeyboardKey? physicalKey,
    }) async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(key, physicalKey: physicalKey);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
    }

    testWidgets('lays out the child at the scaled logical size', (
      tester,
    ) async {
      settings.zoomFactor.value = 1.25;
      final size = await pumpZoom(tester, enabled: true);
      expect(size, const Size(640, 480));
    });

    testWidgets('clamps stored out-of-range factors', (tester) async {
      settings.zoomFactor.value = 10;
      final size = await pumpZoom(tester, enabled: true);
      expect(size, const Size(160, 120));
    });

    testWidgets('renders the child unscaled when disabled', (tester) async {
      final size = await pumpZoom(tester, enabled: false);
      expect(size, const Size(800, 600));
      expect(find.byType(FittedBox), findsNothing);
      await pressCtrlKey(tester, LogicalKeyboardKey.equal);
      expect(settings.zoomFactor.value, 1);
    });

    testWidgets('defaults to enabled on desktop test hosts', (tester) async {
      // flutter test only runs on desktop platforms, so
      // PlatformCapabilities.isDesktop is always true here.
      final size = await pumpZoom(tester);
      expect(size, const Size(800, 600));
      expect(find.byType(FittedBox), findsOneWidget);
    });

    testWidgets('ctrl+= zooms in, ctrl+- zooms out, ctrl+0 resets', (
      tester,
    ) async {
      await pumpZoom(tester, enabled: true);

      await pressCtrlKey(tester, LogicalKeyboardKey.equal);
      expect(settings.zoomFactor.value, 1.1);
      expect(prefs.getDouble('zoomFactor'), 1.1);

      await pressCtrlKey(tester, LogicalKeyboardKey.minus);
      expect(settings.zoomFactor.value, 1);

      await pressCtrlKey(tester, LogicalKeyboardKey.minus);
      expect(settings.zoomFactor.value, 0.9);

      await pressCtrlKey(tester, LogicalKeyboardKey.digit0);
      expect(settings.zoomFactor.value, 1);
    });

    testWidgets('handles numpad and plus keys', (tester) async {
      await pumpZoom(tester, enabled: true);

      await pressCtrlKey(tester, LogicalKeyboardKey.numpadAdd);
      expect(settings.zoomFactor.value, 1.1);

      await pressCtrlKey(tester, LogicalKeyboardKey.numpadSubtract);
      expect(settings.zoomFactor.value, 1);

      // The dedicated "+" key has no physical counterpart in the
      // key simulator's default map, so supply one explicitly.
      await pressCtrlKey(
        tester,
        LogicalKeyboardKey.add,
        physicalKey: PhysicalKeyboardKey.equal,
      );
      expect(settings.zoomFactor.value, 1.1);

      await pressCtrlKey(tester, LogicalKeyboardKey.numpad0);
      expect(settings.zoomFactor.value, 1);
    });

    testWidgets('repeats zoom while the key is held', (tester) async {
      await pumpZoom(tester, enabled: true);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.equal);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.equal);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.equal);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(settings.zoomFactor.value, 1.25);
    });

    testWidgets('ignores other modifiers and unrelated keys', (tester) async {
      await pumpZoom(tester, enabled: true);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.equal);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      expect(settings.zoomFactor.value, 1);

      await pressCtrlKey(tester, LogicalKeyboardKey.keyA);
      expect(settings.zoomFactor.value, 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.equal);
      await tester.pump();
      expect(settings.zoomFactor.value, 1);
    });

    testWidgets('uses cmd on macOS', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        await pumpZoom(tester, enabled: true);

        await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.equal);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
        await tester.pump();
        expect(settings.zoomFactor.value, 1.1);

        await pressCtrlKey(tester, LogicalKeyboardKey.equal);
        expect(settings.zoomFactor.value, 1.1);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('flashes a percentage badge on zoom', (tester) async {
      await pumpZoom(tester, enabled: true);
      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        0,
      );

      await pressCtrlKey(tester, LogicalKeyboardKey.minus);
      expect(find.text('90%'), findsOneWidget);
      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        1,
      );

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        0,
      );
    });

    testWidgets('does not flash the badge at the zoom limits', (tester) async {
      settings.zoomFactor.value = 5;
      await pumpZoom(tester, enabled: true);

      await pressCtrlKey(tester, LogicalKeyboardKey.equal);
      expect(settings.zoomFactor.value, 5);
      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        0,
      );
    });
  });
}
