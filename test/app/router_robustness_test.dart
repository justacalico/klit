// SPDX-License-Identifier: AGPL-3.0

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';

void main() {
  group('router error l10n', () {
    test('routeNotFoundTitle exists in English', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(l10n.routeNotFoundTitle, 'Page Not Found');
    });

    test('routeNotFoundBody exists in English', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(l10n.routeNotFoundBody, 'The page you requested could not be found.');
    });

    test('routeInvalidPostId formats with id in English', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(l10n.routeInvalidPostId('abc'), 'Invalid post ID: abc');
    });

    test('routeNotFoundTitle exists in Chinese', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('zh'));
      expect(l10n.routeNotFoundTitle, '页面未找到');
    });

    test('routeInvalidPostId formats with id in Chinese', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('zh'));
      expect(l10n.routeInvalidPostId('abc'), '无效的帖子 ID：abc');
    });
  });
}
