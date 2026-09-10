// SPDX-License-Identifier: AGPL-3.0

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';

void main() {
  group('misc l10n', () {
    test('commonFilter exists in English', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(l10n.commonFilter, 'Filter');
    });

    test('commonFilter exists in Chinese', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('zh'));
      expect(l10n.commonFilter, '筛选');
    });

    test('feedsDeleteDialogBody formats with name in English', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(l10n.feedsDeleteDialogBody('My Feed'), 'Delete "My Feed"?');
    });

    test('databaseExporting exists in English', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(l10n.databaseExporting, 'Exporting database...');
    });

    test('databaseImporting exists in English', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(l10n.databaseImporting, 'Importing database...');
    });

    test('databaseExportSuccess exists in English', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(l10n.databaseExportSuccess, 'Database exported successfully');
    });

    test('databaseImportInvalidFile formats with error', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(l10n.databaseImportInvalidFile('bad format'), 'Invalid database file: bad format');
    });

    test('databaseImportFailed formats with error', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(l10n.databaseImportFailed('io error'), 'Import failed: io error');
    });

    test('commonOkUpper exists in English', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(l10n.commonOkUpper, 'OK');
    });
  });
}
