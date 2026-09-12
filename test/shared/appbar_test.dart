// SPDX-License-Identifier: AGPL-3.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/shared/shared.dart';

void main() {
  const secondaryKey = Key('secondary');

  Widget buildApp({AppHeaderDensity density = AppHeaderDensity.regular}) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppHeaderBar(
          title: const Text('Title'),
          density: density,
          secondary: const SizedBox(key: secondaryKey),
        ),
      ),
    );
  }

  group('AppHeaderBar secondary', () {
    for (final entry in {
      AppHeaderDensity.compact: 38.0,
      AppHeaderDensity.regular: 46.0,
      AppHeaderDensity.spacious: 54.0,
    }.entries) {
      testWidgets('secondary height is band minus padding (${entry.key.name})',
          (tester) async {
        await tester.pumpWidget(buildApp(density: entry.key));
        await tester.pumpAndSettle();

        expect(
          tester.getSize(find.byKey(secondaryKey)).height,
          entry.value,
        );
        expect(tester.takeException(), isNull);
      });
    }

    test('preferredSize reserves the full secondary band', () {
      const appBar = AppHeaderBar(secondary: SizedBox());
      expect(appBar.preferredSize.height, defaultAppBarHeight + 60);
    });
  });
}
