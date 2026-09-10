// SPDX-License-Identifier: AGPL-3.0

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';

void main() {
  group('finishes page l10n', () {
    test('finishTitle exists in English', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(l10n.finishTitle, 'Finishes');
    });

    test('finishEnablePrompt exists in English', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(l10n.finishEnablePrompt, 'Turn on I Finished in Settings');
    });

    test('finishOpenSettings exists in English', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(l10n.finishOpenSettings, 'Open Settings');
    });

    test('finishEmpty exists in English', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(l10n.finishEmpty, 'No finished posts yet');
    });

    test('finishError formats with error in English', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(l10n.finishError('disk full'), 'Error: disk full');
    });

    test('finishToday formats with time in English', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(l10n.finishToday('14:30'), 'Today 14:30');
    });

    test('finishTitle exists in Chinese', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('zh'));
      expect(l10n.finishTitle, '完成');
    });

    test('finishEmpty exists in Chinese', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('zh'));
      expect(l10n.finishEmpty, '还没有完成的帖子');
    });

    test('finishToday formats with time in Chinese', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('zh'));
      expect(l10n.finishToday('14:30'), '今天 14:30');
    });
  });
}
