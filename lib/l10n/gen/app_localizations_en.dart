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
  String get settingsLanguageEnglishTraditiation => 'English Traditiation';

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
  String get aboutCheckForUpdate => 'Check for update';

  @override
  String get aboutCheckingForUpdates => 'Checking for updates...';
}

/// The translations for English, as used in Australia (`en_AU`).
class AppLocalizationsEnAu extends AppLocalizationsEn {
  AppLocalizationsEnAu() : super('en_AU');

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
  String get settingsLanguageEnglishTraditiation => 'English Traditiation';

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
  String get aboutCheckForUpdate => 'Check for update';

  @override
  String get aboutCheckingForUpdates => 'Checking for updates...';
}
