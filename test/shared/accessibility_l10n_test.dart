// SPDX-License-Identifier: AGPL-3.0

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';

void main() {
  group('accessibility l10n', () {
    test('commonComments exists in English', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(l10n.commonComments, 'Comments');
    });

    test('commonComments exists in Chinese', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('zh'));
      expect(l10n.commonComments, '评论');
    });

    test('commonShare exists in English', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(l10n.commonShare, 'Share');
    });

    test('tooltipDelete exists in English', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(l10n.tooltipDelete, 'Delete');
    });
  });
}
