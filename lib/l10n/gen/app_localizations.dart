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
