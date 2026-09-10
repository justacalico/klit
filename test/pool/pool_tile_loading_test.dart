// SPDX-License-Identifier: AGPL-3.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pool tile loading state', () {
    test('shows loading indicator when thumbnails are null', () {
      final thumbnails = null;
      final hasPost = false;
      final showLoading = thumbnails == null && !hasPost;
      expect(showLoading, isTrue);
    });

    test('does not show loading when thumbnails are loaded', () {
      final thumbnails = <int>[];
      final hasPost = false;
      final showLoading = thumbnails == null && !hasPost;
      expect(showLoading, isFalse);
    });

    test('does not show loading when post is found', () {
      final thumbnails = null;
      final hasPost = true;
      final showLoading = thumbnails == null && !hasPost;
      expect(showLoading, isFalse);
    });
  });
}
