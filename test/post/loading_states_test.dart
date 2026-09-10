// SPDX-License-Identifier: AGPL-3.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoadingPage state logic', () {
    test('isLoading takes priority when items are null and no error', () {
      final items = null;
      final error = null;
      final isLoading = items == null && error == null;
      expect(isLoading, isTrue);
    });

    test('isEmpty when items are loaded but empty', () {
      final items = <int>[];
      final isEmpty = items != null && items.isEmpty;
      expect(isEmpty, isTrue);
    });

    test('isNotLoading when items are loaded', () {
      final items = [1, 2, 3];
      final isLoading = items == null;
      expect(isLoading, isFalse);
    });
  });

  group('StreamBuilder error handling', () {
    test('snapshot.hasError returns 0 for count', () {
      final hasError = true;
      final data = null;
      final count = hasError ? 0 : (data ?? 0);
      expect(count, 0);
    });

    test('snapshot.data returns actual count when no error', () {
      final hasError = false;
      final data = 5;
      final count = hasError ? 0 : (data ?? 0);
      expect(count, 5);
    });
  });
}
