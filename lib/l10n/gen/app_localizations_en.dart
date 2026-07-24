// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionAccounts => 'Accounts';

  @override
  String get settingsSectionUser => 'User';

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get settingsSectionInteractions => 'Interactions';

  @override
  String get settingsSectionSecurity => 'Security';

  @override
  String get settingsSectionDevelopment => 'Development';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageSystem => 'System default';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get aboutSectionTitle => 'About';

  @override
  String get aboutDevEnabled => 'You are now a developer!';

  @override
  String get aboutVersionTitle => 'Version';

  @override
  String get aboutWebsiteTitle => 'Website';

  @override
  String get aboutFetchingUpdates => 'Fetching updates...';

  @override
  String get aboutFailedCheckUpdates => 'Failed to check for updates';

  @override
  String get aboutNewestVersion => 'You have the newest version';

  @override
  String aboutNewerVersionAvailable(Object version) {
    return 'A newer version is available: $version';
  }

  @override
  String get aboutNewerVersionAvailablePrefix =>
      'A newer version is available:';

  @override
  String get commonCancelUpper => 'CANCEL';

  @override
  String get commonDownloadUpper => 'DOWNLOAD';

  @override
  String get commonLaterUpper => 'LATER';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonSave => 'Save';

  @override
  String get commonImportUpper => 'IMPORT';

  @override
  String get commonOkUpper => 'OK';

  @override
  String get commonRestartNowUpper => 'RESTART NOW';

  @override
  String get aboutCheckForUpdate => 'Check for update';

  @override
  String get aboutCheckingForUpdates => 'Checking for updates...';

  @override
  String get feedsTitle => 'Feeds';

  @override
  String get feedsNewFeedTitle => 'New feed';

  @override
  String get feedsEditFeedTitle => 'Edit feed';

  @override
  String get feedsDeleteDialogTitle => 'Delete feed';

  @override
  String feedsDeleteDialogBody(Object name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get feedsEmptyTitle => 'No feeds yet';

  @override
  String get feedsEmptyBody =>
      'Create a feed with tags and image or video type to browse posts in one tap';

  @override
  String get feedsCreateFeed => 'Create feed';

  @override
  String get databaseExporting => 'Exporting database...';

  @override
  String get databaseImporting => 'Importing database...';

  @override
  String get databaseExportDialogTitle => 'Export Database';

  @override
  String get databaseExportSuccess => 'Database exported successfully';

  @override
  String get databaseExportFailed => 'Export failed';

  @override
  String get databaseExportTitle => 'Export';

  @override
  String get databaseExportSubtitle => 'Save a backup copy of your database';

  @override
  String get databaseImportDialogTitle => 'Import Database';

  @override
  String databaseImportInvalidFile(Object error) {
    return 'Invalid database file: $error';
  }

  @override
  String databaseImportFailed(Object error) {
    return 'Import failed: $error';
  }

  @override
  String get databaseImportTitle => 'Import';

  @override
  String get databaseImportSubtitle =>
      'Replace current database with imported one';

  @override
  String get databaseImportWarningBody =>
      'This will replace your current database. \\nAll data will be lost. This cannot be undone!';

  @override
  String get databaseRestartRequiredTitle => 'Restart Required';

  @override
  String get databaseRestartRequiredBody =>
      'The app needs to restart to apply changes.';

  @override
  String postUpdateSuccess(Object id) {
    return 'Updated post #$id';
  }

  @override
  String postUpdateFailed(Object id) {
    return 'Failed to update post #$id';
  }

  @override
  String tagPreviewLoadFailed(Object error) {
    return 'Error loading tag preview: $error';
  }

  @override
  String get tooltipInfo => 'Info';

  @override
  String get tooltipCopy => 'Copy';

  @override
  String get tooltipDelete => 'Delete';

  @override
  String get tooltipAbort => 'Abort';

  @override
  String get tooltipSelectAll => 'Select all';

  @override
  String get tooltipPrevious => 'Previous';

  @override
  String get tooltipNext => 'Next';
}
