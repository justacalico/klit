// SPDX-License-Identifier: AGPL-3.0

/// Browser-style zoom levels and stepping for the desktop UI.
abstract final class AppZoom {
  /// The same discrete levels browsers use for page zoom.
  static const levels = <double>[
    0.25,
    0.33,
    0.5,
    0.67,
    0.75,
    0.8,
    0.9,
    1,
    1.1,
    1.25,
    1.5,
    1.75,
    2,
    2.5,
    3,
    4,
    5,
  ];

  /// The next level in [direction] (positive for in, negative for out),
  /// clamped to the ends of [levels].
  static double step(double factor, int direction) {
    if (direction > 0) {
      for (final level in levels) {
        if (level > factor + 0.001) return level;
      }
      return levels.last;
    }
    for (var i = levels.length - 1; i >= 0; i--) {
      if (levels[i] < factor - 0.001) return levels[i];
    }
    return levels.first;
  }

  /// [factor] as a rounded percentage for display (`1.1` -> `110`).
  static int percent(double factor) => (factor * 100).round();

  /// [factor] clamped into the supported range.
  static double clamped(double factor) =>
      factor.clamp(levels.first, levels.last);
}
