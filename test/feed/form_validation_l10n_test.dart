// SPDX-License-Identifier: AGPL-3.0

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';

void main() {
  group('feed form validation l10n', () {
    test('feedsNameRequired exists in English', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(l10n.feedsNameRequired, 'Please enter a feed name');
    });

    test('feedsNameRequired exists in Chinese', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('zh'));
      expect(l10n.feedsNameRequired, '请输入订阅名称');
    });
  });
}
