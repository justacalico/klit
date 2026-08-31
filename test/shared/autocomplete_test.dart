// SPDX-License-Identifier: AGPL-3.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/shared/shared.dart';

void main() {
  group('AutocompleteTextField', () {
    testWidgets('forwards the supplied focusNode to the inner TextField',
        (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutocompleteTextField<String>(
              focusNode: focusNode,
              autofocus: false,
              onSelected: (_) {},
              suggestionsCallback: (_) async => const [],
              itemBuilder: (_, value) => ListTile(title: Text(value)),
            ),
          ),
        ),
      );
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.focusNode, same(focusNode));
    });

    testWidgets('requesting focus on the supplied node focuses the field',
        (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutocompleteTextField<String>(
              focusNode: focusNode,
              autofocus: false,
              onSelected: (_) {},
              suggestionsCallback: (_) async => const [],
              itemBuilder: (_, value) => ListTile(title: Text(value)),
            ),
          ),
        ),
      );
      await tester.pump();

      focusNode.requestFocus();
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);
    });
  });
}
