// SPDX-License-Identifier: AGPL-3.0

import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'dart:ui';

void main() {
  group('post display l10n', () {
    final en = AppLocalizations.delegate.load(const Locale('en'));

    test('postNoPosts exists in English', () async {
      final l10n = await en;
      expect(l10n.postNoPosts, 'No posts');
    });

    test('postFailedLoadPosts exists in English', () async {
      final l10n = await en;
      expect(l10n.postFailedLoadPosts, 'Failed to load posts');
    });

    test('postNoPosts exists in Chinese', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('zh'));
      expect(l10n.postNoPosts, '没有帖子');
    });

    test('postFailedLoadPosts exists in Chinese', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('zh'));
      expect(l10n.postFailedLoadPosts, '加载帖子失败');
    });
  });
}
