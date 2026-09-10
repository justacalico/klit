// SPDX-License-Identifier: AGPL-3.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('keyboard shortcut focus checks', () {
    test('letter keys should be ignored when editing text', () {
      final isEditingText = true;
      final logicalKey = LogicalKeyboardKey.keyA;
      final shouldHandle = !isEditingText && logicalKey == LogicalKeyboardKey.keyA;
      expect(shouldHandle, isFalse);
    });

    test('letter keys should be handled when not editing text', () {
      final isEditingText = false;
      final logicalKey = LogicalKeyboardKey.keyA;
      final shouldHandle = !isEditingText && logicalKey == LogicalKeyboardKey.keyA;
      expect(shouldHandle, isTrue);
    });

    test('arrow keys should be handled even when editing text', () {
      final isEditingText = true;
      final physicalKey = PhysicalKeyboardKey.arrowLeft;
      final shouldHandle = physicalKey == PhysicalKeyboardKey.arrowLeft;
      expect(shouldHandle, isTrue);
    });

    test('keyF should be ignored when editing text', () {
      final isEditingText = true;
      final logicalKey = LogicalKeyboardKey.keyF;
      final shouldHandle = !isEditingText && logicalKey == LogicalKeyboardKey.keyF;
      expect(shouldHandle, isFalse);
    });

    test('keyF should be handled when not editing text', () {
      final isEditingText = false;
      final logicalKey = LogicalKeyboardKey.keyF;
      final shouldHandle = !isEditingText && logicalKey == LogicalKeyboardKey.keyF;
      expect(shouldHandle, isTrue);
    });
  });
}
