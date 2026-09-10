// SPDX-License-Identifier: AGPL-3.0

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';

void main() {
  group('destructive action l10n', () {
    test('finishDeleteTitle exists in English', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(l10n.finishDeleteTitle, 'Delete finish?');
    });

    test('finishDeleteBody formats with id in English', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(l10n.finishDeleteBody(42), 'Delete the finish for post #42?');
    });

    test('historyDeleteSelectedTitle exists in English', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(l10n.historyDeleteSelectedTitle, 'Delete selected entries?');
    });

    test('historyDeleteSelectedBody formats with count in English', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(
        l10n.historyDeleteSelectedBody(3),
        'This will permanently delete 3 history entries.',
      );
    });

    test('finishDeleteTitle exists in Chinese', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('zh'));
      expect(l10n.finishDeleteTitle, '删除完成记录？');
    });

    test('finishDeleteBody formats with id in Chinese', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('zh'));
      expect(l10n.finishDeleteBody(42), '删除帖子 #42 的完成记录？');
    });
  });
}
