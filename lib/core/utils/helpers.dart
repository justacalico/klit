// SPDX-License-Identifier: AGPL-3.0

import 'package:flutter/material.dart';

const String defaultAccentColorHex = '#F7A8B8';

const Color defaultAccentColor = Color(0xFFF7A8B8);

Color colorFromHex(String hex) {
  final normalized = hex.trim().replaceFirst('#', '');
  if (normalized.length != 6) return defaultAccentColor;
  final value = int.tryParse(normalized, radix: 16);
  if (value == null) return defaultAccentColor;
  return Color(0xFF000000 | value);
}

String hexFromColor(Color color) =>
    '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

MaterialColor materialSwatchFromColor(Color color) {
  final hsl = HSLColor.fromColor(color);
  Color tone(double lightness) =>
      hsl.withLightness(lightness.clamp(0.0, 1.0)).toColor();

  return MaterialColor(color.toARGB32(), {
    50: tone(0.95),
    100: tone(0.88),
    200: tone(0.78),
    300: tone(0.68),
    400: tone(0.60),
    500: tone(0.54),
    600: tone(0.47),
    700: tone(0.40),
    800: tone(0.33),
    900: tone(0.26),
  });
}
