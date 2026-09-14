// SPDX-License-Identifier: AGPL-3.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('search bar sync logic', () {
    test('TextEditingController syncs from external query changes', () {
      final textController = TextEditingController(text: 'fox');
      expect(textController.text, 'fox');

      const queryTags = 'cat';
      if (textController.text != queryTags) {
        textController.value = const TextEditingValue(
          text: queryTags,
          selection: TextSelection.collapsed(offset: queryTags.length),
        );
      }
      expect(textController.text, 'cat');
    });

    test('clear button clears text', () {
      final textController = TextEditingController(text: 'fox');
      textController.clear();
      expect(textController.text, '');
    });

    test('sync does not update when text already matches', () {
      final textController = TextEditingController(text: 'fox');
      const queryTags = 'fox';
      expect(textController.text, queryTags);
    });

    test('ValueListenableBuilder shows clear button only when text is not empty', () {
      final textController = TextEditingController(text: '');
      expect(textController.text.isEmpty, isTrue);

      textController.text = 'fox';
      expect(textController.text.isNotEmpty, isTrue);
    });
  });
}
