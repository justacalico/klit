import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('en', 'AU'),
  ];

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSectionAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get settingsSectionAccounts;

  /// No description provided for @settingsSectionUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get settingsSectionUser;

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsSectionInteractions.
  ///
  /// In en, this message translates to:
  /// **'Interactions'**
  String get settingsSectionInteractions;

  /// No description provided for @settingsSectionSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settingsSectionSecurity;

  /// No description provided for @settingsSectionDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Development'**
  String get settingsSectionDevelopment;

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageTitle;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageEnglishTraditiation.
  ///
  /// In en, this message translates to:
  /// **'English Traditiation'**
  String get settingsLanguageEnglishTraditiation;

  /// No description provided for @aboutSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSectionTitle;

  /// No description provided for @aboutDevEnabled.
  ///
  /// In en, this message translates to:
  /// **'You are now a developer!'**
  String get aboutDevEnabled;

  /// No description provided for @aboutVersionTitle.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get aboutVersionTitle;

  /// No description provided for @aboutWebsiteTitle.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get aboutWebsiteTitle;

  /// No description provided for @aboutFetchingUpdates.
  ///
  /// In en, this message translates to:
  /// **'Fetching updates...'**
  String get aboutFetchingUpdates;

  /// No description provided for @aboutFailedCheckUpdates.
  ///
  /// In en, this message translates to:
  /// **'Failed to check for updates'**
  String get aboutFailedCheckUpdates;

  /// No description provided for @aboutNewestVersion.
  ///
  /// In en, this message translates to:
  /// **'You have the newest version'**
  String get aboutNewestVersion;

  /// No description provided for @aboutNewerVersionAvailable.
  ///
  /// In en, this message translates to:
  /// **'A newer version is available: {version}'**
  String aboutNewerVersionAvailable(Object version);

  /// No description provided for @aboutNewerVersionAvailablePrefix.
  ///
  /// In en, this message translates to:
  /// **'A newer version is available:'**
  String get aboutNewerVersionAvailablePrefix;

  /// No description provided for @commonCancelUpper.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get commonCancelUpper;

  /// No description provided for @commonDownloadUpper.
  ///
  /// In en, this message translates to:
  /// **'DOWNLOAD'**
  String get commonDownloadUpper;

  /// No description provided for @commonLaterUpper.
  ///
  /// In en, this message translates to:
  /// **'LATER'**
  String get commonLaterUpper;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonImportUpper.
  ///
  /// In en, this message translates to:
  /// **'IMPORT'**
  String get commonImportUpper;

  /// No description provided for @commonOkUpper.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOkUpper;

  /// No description provided for @commonRestartNowUpper.
  ///
  /// In en, this message translates to:
  /// **'RESTART NOW'**
  String get commonRestartNowUpper;

  /// No description provided for @aboutCheckForUpdate.
  ///
  /// In en, this message translates to:
  /// **'Check for update'**
  String get aboutCheckForUpdate;

  /// No description provided for @aboutCheckingForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates...'**
  String get aboutCheckingForUpdates;

  /// No description provided for @feedsTitle.
  ///
  /// In en, this message translates to:
  /// **'Feeds'**
  String get feedsTitle;

  /// No description provided for @feedsNewFeedTitle.
  ///
  /// In en, this message translates to:
  /// **'New feed'**
  String get feedsNewFeedTitle;

  /// No description provided for @feedsEditFeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit feed'**
  String get feedsEditFeedTitle;

  /// No description provided for @feedsDeleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete feed'**
  String get feedsDeleteDialogTitle;

  /// No description provided for @feedsDeleteDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String feedsDeleteDialogBody(Object name);

  /// No description provided for @feedsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No feeds yet'**
  String get feedsEmptyTitle;

  /// No description provided for @feedsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Create a feed with tags and image or video type to browse posts in one tap'**
  String get feedsEmptyBody;

  /// No description provided for @feedsCreateFeed.
  ///
  /// In en, this message translates to:
  /// **'Create feed'**
  String get feedsCreateFeed;

  /// No description provided for @databaseExporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting database...'**
  String get databaseExporting;

  /// No description provided for @databaseImporting.
  ///
  /// In en, this message translates to:
  /// **'Importing database...'**
  String get databaseImporting;

  /// No description provided for @databaseExportDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Database'**
  String get databaseExportDialogTitle;

  /// No description provided for @databaseExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Database exported successfully'**
  String get databaseExportSuccess;

  /// No description provided for @databaseExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get databaseExportFailed;

  /// No description provided for @databaseExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get databaseExportTitle;

  /// No description provided for @databaseExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save a backup copy of your database'**
  String get databaseExportSubtitle;

  /// No description provided for @databaseImportDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Database'**
  String get databaseImportDialogTitle;

  /// No description provided for @databaseImportInvalidFile.
  ///
  /// In en, this message translates to:
  /// **'Invalid database file: {error}'**
  String databaseImportInvalidFile(Object error);

  /// No description provided for @databaseImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String databaseImportFailed(Object error);

  /// No description provided for @databaseImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get databaseImportTitle;

  /// No description provided for @databaseImportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Replace current database with imported one'**
  String get databaseImportSubtitle;

  /// No description provided for @databaseImportWarningBody.
  ///
  /// In en, this message translates to:
  /// **'This will replace your current database. \\nAll data will be lost. This cannot be undone!'**
  String get databaseImportWarningBody;

  /// No description provided for @databaseRestartRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Restart Required'**
  String get databaseRestartRequiredTitle;

  /// No description provided for @databaseRestartRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'The app needs to restart to apply changes.'**
  String get databaseRestartRequiredBody;

  /// No description provided for @postUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Updated post #{id}'**
  String postUpdateSuccess(Object id);

  /// No description provided for @postUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update post #{id}'**
  String postUpdateFailed(Object id);

  /// No description provided for @tagPreviewLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Error loading tag preview: {error}'**
  String tagPreviewLoadFailed(Object error);

  /// No description provided for @tooltipInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get tooltipInfo;

  /// No description provided for @tooltipCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get tooltipCopy;

  /// No description provided for @tooltipDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get tooltipDelete;

  /// No description provided for @tooltipAbort.
  ///
  /// In en, this message translates to:
  /// **'Abort'**
  String get tooltipAbort;

  /// No description provided for @tooltipSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get tooltipSelectAll;

  /// No description provided for @tooltipPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get tooltipPrevious;

  /// No description provided for @tooltipNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tooltipNext;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'en':
      {
        switch (locale.countryCode) {
          case 'AU':
            return AppLocalizationsEnAu();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
