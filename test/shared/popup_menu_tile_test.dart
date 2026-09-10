// SPDX-License-Identifier: AGPL-3.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/shared/widget/popups.dart';

void main() {
  group('PopupMenuTile', () {
    test('supports optional textColor and iconColor', () {
      final tile = PopupMenuTile<int>(
        value: 1,
        icon: Icons.home,
        title: 'Home',
      );
      expect(tile.textColor, isNull);
      expect(tile.iconColor, isNull);
    });

    test('accepts textColor and iconColor parameters', () {
      final tile = PopupMenuTile<int>(
        value: 1,
        icon: Icons.home,
        title: 'Home',
        textColor: Colors.red,
        iconColor: Colors.blue,
      );
      expect(tile.textColor, Colors.red);
      expect(tile.iconColor, Colors.blue);
    });
  });
}
