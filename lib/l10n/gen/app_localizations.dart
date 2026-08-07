import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

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
    Locale('zh'),
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

  /// No description provided for @settingsLanguageSimplifiedChinese.
  ///
  /// In en, this message translates to:
  /// **'Simplified Chinese'**
  String get settingsLanguageSimplifiedChinese;

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

  /// No description provided for @aboutSourceLocal.
  ///
  /// In en, this message translates to:
  /// **'Local build'**
  String get aboutSourceLocal;

  /// No description provided for @aboutSourceOther.
  ///
  /// In en, this message translates to:
  /// **'Other source'**
  String get aboutSourceOther;

  /// No description provided for @aboutSourceStore.
  ///
  /// In en, this message translates to:
  /// **'Store install'**
  String get aboutSourceStore;

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

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get commonReset;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get commonSend;

  /// No description provided for @commonShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get commonShare;

  /// No description provided for @commonBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get commonBrowse;

  /// No description provided for @commonReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get commonReport;

  /// No description provided for @commonClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// No description provided for @commonCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get commonCopy;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get commonLoading;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonCancelTask.
  ///
  /// In en, this message translates to:
  /// **'Cancelled task'**
  String get commonCancelTask;

  /// No description provided for @commonCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get commonCopiedToClipboard;

  /// No description provided for @commonTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonTryAgain;

  /// No description provided for @commonNothingHere.
  ///
  /// In en, this message translates to:
  /// **'Nothing to see here'**
  String get commonNothingHere;

  /// No description provided for @commonFailedLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get commonFailedLoad;

  /// No description provided for @commonFailedLoadSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Failed to load suggestions'**
  String get commonFailedLoadSuggestions;

  /// No description provided for @commonSaveFile.
  ///
  /// In en, this message translates to:
  /// **'Save file'**
  String get commonSaveFile;

  /// No description provided for @commonFileSavedAs.
  ///
  /// In en, this message translates to:
  /// **'File saved as {name}'**
  String commonFileSavedAs(Object name);

  /// No description provided for @commonItemProgress.
  ///
  /// In en, this message translates to:
  /// **'Item {current}/{total}'**
  String commonItemProgress(Object current, Object total);

  /// No description provided for @commonFailedItemAt.
  ///
  /// In en, this message translates to:
  /// **'Failed at Item {index}'**
  String commonFailedItemAt(Object index);

  /// No description provided for @commonItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String commonItemsCount(Object count);

  /// No description provided for @commonSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get commonSelectAll;

  /// No description provided for @commonAbort.
  ///
  /// In en, this message translates to:
  /// **'Abort'**
  String get commonAbort;

  /// No description provided for @commonPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get commonPrevious;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @commonInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get commonInfo;

  /// No description provided for @commonToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get commonToday;

  /// No description provided for @commonYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get commonYesterday;

  /// No description provided for @commonWrite.
  ///
  /// In en, this message translates to:
  /// **'Write'**
  String get commonWrite;

  /// No description provided for @commonPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get commonPreview;

  /// No description provided for @commonTypeHere.
  ///
  /// In en, this message translates to:
  /// **'type here...'**
  String get commonTypeHere;

  /// No description provided for @commonYourTextHere.
  ///
  /// In en, this message translates to:
  /// **'your text here'**
  String get commonYourTextHere;

  /// No description provided for @commonMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get commonMore;

  /// No description provided for @commonExpandSidebar.
  ///
  /// In en, this message translates to:
  /// **'Expand sidebar'**
  String get commonExpandSidebar;

  /// No description provided for @commonShrinkSidebar.
  ///
  /// In en, this message translates to:
  /// **'Shrink sidebar'**
  String get commonShrinkSidebar;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get navPopular;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navFeeds.
  ///
  /// In en, this message translates to:
  /// **'Feeds'**
  String get navFeeds;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navPools.
  ///
  /// In en, this message translates to:
  /// **'Pools'**
  String get navPools;

  /// No description provided for @navForum.
  ///
  /// In en, this message translates to:
  /// **'Forum'**
  String get navForum;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navFinishes.
  ///
  /// In en, this message translates to:
  /// **'Finishes'**
  String get navFinishes;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @commonActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get commonActive;

  /// No description provided for @commonInactive.
  ///
  /// In en, this message translates to:
  /// **'inactive'**
  String get commonInactive;

  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'yes'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'no'**
  String get commonNo;

  /// No description provided for @commonCreated.
  ///
  /// In en, this message translates to:
  /// **'created'**
  String get commonCreated;

  /// No description provided for @commonUpdated.
  ///
  /// In en, this message translates to:
  /// **'updated'**
  String get commonUpdated;

  /// No description provided for @commonId.
  ///
  /// In en, this message translates to:
  /// **'id'**
  String get commonId;

  /// No description provided for @commonPosts.
  ///
  /// In en, this message translates to:
  /// **'posts'**
  String get commonPosts;

  /// No description provided for @commonDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get commonDescription;

  /// No description provided for @commonName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get commonName;

  /// No description provided for @commonType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get commonType;

  /// No description provided for @commonTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get commonTags;

  /// No description provided for @commonScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get commonScore;

  /// No description provided for @commonRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get commonRating;

  /// No description provided for @commonRatingAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get commonRatingAll;

  /// No description provided for @commonRatingSafe.
  ///
  /// In en, this message translates to:
  /// **'Safe'**
  String get commonRatingSafe;

  /// No description provided for @commonRatingQuestionable.
  ///
  /// In en, this message translates to:
  /// **'Questionable'**
  String get commonRatingQuestionable;

  /// No description provided for @commonRatingExplicit.
  ///
  /// In en, this message translates to:
  /// **'Explicit'**
  String get commonRatingExplicit;

  /// No description provided for @commonRatingQ.
  ///
  /// In en, this message translates to:
  /// **'Q'**
  String get commonRatingQ;

  /// No description provided for @commonRatingE.
  ///
  /// In en, this message translates to:
  /// **'E'**
  String get commonRatingE;

  /// No description provided for @commonSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get commonSort;

  /// No description provided for @commonSortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get commonSortBy;

  /// No description provided for @commonSortDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get commonSortDefault;

  /// No description provided for @commonSortScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get commonSortScore;

  /// No description provided for @commonSortFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get commonSortFavorites;

  /// No description provided for @commonSortRank.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get commonSortRank;

  /// No description provided for @commonSortRandom.
  ///
  /// In en, this message translates to:
  /// **'Random'**
  String get commonSortRandom;

  /// No description provided for @commonSortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get commonSortName;

  /// No description provided for @commonSortCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get commonSortCreated;

  /// No description provided for @commonSortUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get commonSortUpdated;

  /// No description provided for @commonSortPostCount.
  ///
  /// In en, this message translates to:
  /// **'Post count'**
  String get commonSortPostCount;

  /// No description provided for @commonSortNewestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get commonSortNewestFirst;

  /// No description provided for @commonSortOldestFirst.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get commonSortOldestFirst;

  /// No description provided for @commonSortFavCount.
  ///
  /// In en, this message translates to:
  /// **'Fav count'**
  String get commonSortFavCount;

  /// No description provided for @commonEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get commonEnabled;

  /// No description provided for @commonDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get commonDisabled;

  /// No description provided for @commonShow.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get commonShow;

  /// No description provided for @commonHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get commonHide;

  /// No description provided for @commonCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get commonCamera;

  /// No description provided for @commonGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get commonGallery;

  /// No description provided for @commonSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get commonSkip;

  /// No description provided for @commonBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get commonBlock;

  /// No description provided for @commonUnblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get commonUnblock;

  /// No description provided for @commonFollow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get commonFollow;

  /// No description provided for @commonUnfollow.
  ///
  /// In en, this message translates to:
  /// **'Unfollow'**
  String get commonUnfollow;

  /// No description provided for @commonMute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get commonMute;

  /// No description provided for @commonNotify.
  ///
  /// In en, this message translates to:
  /// **'Notify'**
  String get commonNotify;

  /// No description provided for @commonBookmark.
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get commonBookmark;

  /// No description provided for @commonUnbookmark.
  ///
  /// In en, this message translates to:
  /// **'Unbookmark'**
  String get commonUnbookmark;

  /// No description provided for @commonSubtract.
  ///
  /// In en, this message translates to:
  /// **'Subtract'**
  String get commonSubtract;

  /// No description provided for @commonRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// No description provided for @commonResolve.
  ///
  /// In en, this message translates to:
  /// **'Resolve'**
  String get commonResolve;

  /// No description provided for @commonAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get commonAbout;

  /// No description provided for @commonUploads.
  ///
  /// In en, this message translates to:
  /// **'Uploads'**
  String get commonUploads;

  /// No description provided for @commonFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get commonFavorites;

  /// No description provided for @commonMain.
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get commonMain;

  /// No description provided for @commonNoDescription.
  ///
  /// In en, this message translates to:
  /// **'no description'**
  String get commonNoDescription;

  /// No description provided for @commonNoTags.
  ///
  /// In en, this message translates to:
  /// **'No tags'**
  String get commonNoTags;

  /// No description provided for @commonNoSources.
  ///
  /// In en, this message translates to:
  /// **'no sources'**
  String get commonNoSources;

  /// No description provided for @commonNoArtist.
  ///
  /// In en, this message translates to:
  /// **'no artist'**
  String get commonNoArtist;

  /// No description provided for @commonAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get commonAnonymous;

  /// No description provided for @commonLogin.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get commonLogin;

  /// No description provided for @commonAuthentication.
  ///
  /// In en, this message translates to:
  /// **'Authentication'**
  String get commonAuthentication;

  /// No description provided for @commonHost.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get commonHost;

  /// No description provided for @commonUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get commonUsername;

  /// No description provided for @commonApiKey.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get commonApiKey;

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

  /// No description provided for @feedsUnnamed.
  ///
  /// In en, this message translates to:
  /// **'Unnamed feed'**
  String get feedsUnnamed;

  /// No description provided for @feedsNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. My art feed'**
  String get feedsNameHint;

  /// No description provided for @feedsIncludeTags.
  ///
  /// In en, this message translates to:
  /// **'Include tags'**
  String get feedsIncludeTags;

  /// No description provided for @feedsIncludeTagsHint.
  ///
  /// In en, this message translates to:
  /// **'space separated, all required'**
  String get feedsIncludeTagsHint;

  /// No description provided for @feedsOrTags.
  ///
  /// In en, this message translates to:
  /// **'Or tags'**
  String get feedsOrTags;

  /// No description provided for @feedsOrTagsHint.
  ///
  /// In en, this message translates to:
  /// **'any of these'**
  String get feedsOrTagsHint;

  /// No description provided for @feedsExcludeTags.
  ///
  /// In en, this message translates to:
  /// **'Exclude tags'**
  String get feedsExcludeTags;

  /// No description provided for @feedsExcludeTagsHint.
  ///
  /// In en, this message translates to:
  /// **'posts with these are hidden'**
  String get feedsExcludeTagsHint;

  /// No description provided for @feedsSubfeeds.
  ///
  /// In en, this message translates to:
  /// **'Subfeeds'**
  String get feedsSubfeeds;

  /// No description provided for @feedsSubfeedsHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional filters; only one can be active at a time when viewing the feed.'**
  String get feedsSubfeedsHelper;

  /// No description provided for @feedsAddSubfeed.
  ///
  /// In en, this message translates to:
  /// **'Add subfeed'**
  String get feedsAddSubfeed;

  /// No description provided for @feedsSubfeedName.
  ///
  /// In en, this message translates to:
  /// **'Subfeed name'**
  String get feedsSubfeedName;

  /// No description provided for @feedsExtraIncludeTags.
  ///
  /// In en, this message translates to:
  /// **'Extra include tags'**
  String get feedsExtraIncludeTags;

  /// No description provided for @feedsExtraIncludeTagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Additional tags (all required)'**
  String get feedsExtraIncludeTagsLabel;

  /// No description provided for @feedsExtraExcludeTags.
  ///
  /// In en, this message translates to:
  /// **'Extra exclude tags'**
  String get feedsExtraExcludeTags;

  /// No description provided for @feedsExtraExcludeTagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tags to exclude in this subfeed'**
  String get feedsExtraExcludeTagsLabel;

  /// No description provided for @feedsExcludeFavorited.
  ///
  /// In en, this message translates to:
  /// **'Exclude favorited'**
  String get feedsExcludeFavorited;

  /// No description provided for @feedsExcludeFavoritedHelper.
  ///
  /// In en, this message translates to:
  /// **'Don\'t show posts you\'ve favorited in this feed'**
  String get feedsExcludeFavoritedHelper;

  /// No description provided for @feedsIncludeFavoritesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Includes favorited posts. Tap to exclude them.'**
  String get feedsIncludeFavoritesTooltip;

  /// No description provided for @feedsExcludeFavoritesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Excludes favorited posts. Tap to include them.'**
  String get feedsExcludeFavoritesTooltip;

  /// No description provided for @feedImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get feedImage;

  /// No description provided for @feedVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get feedVideo;

  /// No description provided for @feedImageAndVideo.
  ///
  /// In en, this message translates to:
  /// **'Image & video'**
  String get feedImageAndVideo;

  /// No description provided for @feedNoTags.
  ///
  /// In en, this message translates to:
  /// **'no tags'**
  String get feedNoTags;

  /// No description provided for @feedSubDefault.
  ///
  /// In en, this message translates to:
  /// **'Sub {index}'**
  String feedSubDefault(Object index);

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

  /// No description provided for @databaseErrorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading database'**
  String get databaseErrorLoading;

  /// No description provided for @databaseBackupFileName.
  ///
  /// In en, this message translates to:
  /// **'klit_database_backup.db'**
  String get databaseBackupFileName;

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

  /// No description provided for @postBlacklisted.
  ///
  /// In en, this message translates to:
  /// **'Blacklisted'**
  String get postBlacklisted;

  /// No description provided for @postComments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get postComments;

  /// No description provided for @postCommentsWithCount.
  ///
  /// In en, this message translates to:
  /// **'Comments ({count})'**
  String postCommentsWithCount(Object count);

  /// No description provided for @postDeletion.
  ///
  /// In en, this message translates to:
  /// **'Deletion'**
  String get postDeletion;

  /// No description provided for @postFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get postFile;

  /// No description provided for @postPools.
  ///
  /// In en, this message translates to:
  /// **'Pools'**
  String get postPools;

  /// No description provided for @postParent.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get postParent;

  /// No description provided for @postChildren.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get postChildren;

  /// No description provided for @postSources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get postSources;

  /// No description provided for @postScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get postScore;

  /// No description provided for @postFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get postFavorites;

  /// No description provided for @postCopiedId.
  ///
  /// In en, this message translates to:
  /// **'Copied post id #{id}'**
  String postCopiedId(Object id);

  /// No description provided for @postFailedUpvote.
  ///
  /// In en, this message translates to:
  /// **'Failed to upvote Post #{id}'**
  String postFailedUpvote(Object id);

  /// No description provided for @postFailedDownvote.
  ///
  /// In en, this message translates to:
  /// **'Failed to downvote Post #{id}'**
  String postFailedDownvote(Object id);

  /// No description provided for @postFailedVote.
  ///
  /// In en, this message translates to:
  /// **'Failed to {action} Post #{id}'**
  String postFailedVote(Object action, Object id);

  /// No description provided for @postTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo?'**
  String get postTakePhoto;

  /// No description provided for @postStatusDeleted.
  ///
  /// In en, this message translates to:
  /// **'deleted'**
  String get postStatusDeleted;

  /// No description provided for @postStatusUnsupported.
  ///
  /// In en, this message translates to:
  /// **'unsupported'**
  String get postStatusUnsupported;

  /// No description provided for @postStatusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'unavailable'**
  String get postStatusUnavailable;

  /// No description provided for @postStatusBlacklisted.
  ///
  /// In en, this message translates to:
  /// **'blacklisted'**
  String get postStatusBlacklisted;

  /// No description provided for @postDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get postDownload;

  /// No description provided for @postDownloadedOne.
  ///
  /// In en, this message translates to:
  /// **'Downloaded post #{id}'**
  String postDownloadedOne(Object id);

  /// No description provided for @postDownloadedMany.
  ///
  /// In en, this message translates to:
  /// **'Downloaded {count} posts'**
  String postDownloadedMany(Object count);

  /// No description provided for @postDownloadingOne.
  ///
  /// In en, this message translates to:
  /// **'Downloading post #{id}'**
  String postDownloadingOne(Object id);

  /// No description provided for @postDownloadingProgress.
  ///
  /// In en, this message translates to:
  /// **'Downloading post #{id} ({current}/{total})'**
  String postDownloadingProgress(Object id, Object current, Object total);

  /// No description provided for @postDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to download post #{id}'**
  String postDownloadFailed(Object id);

  /// No description provided for @postDownloadCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled download'**
  String get postDownloadCancelled;

  /// No description provided for @postFavoritedOne.
  ///
  /// In en, this message translates to:
  /// **'Favorited post #{id}'**
  String postFavoritedOne(Object id);

  /// No description provided for @postFavoritedMany.
  ///
  /// In en, this message translates to:
  /// **'Favorited {count} posts'**
  String postFavoritedMany(Object count);

  /// No description provided for @postUnfavoritedOne.
  ///
  /// In en, this message translates to:
  /// **'Unfavorited post #{id}'**
  String postUnfavoritedOne(Object id);

  /// No description provided for @postUnfavoritedMany.
  ///
  /// In en, this message translates to:
  /// **'Unfavorited {count} posts'**
  String postUnfavoritedMany(Object count);

  /// No description provided for @postFavoritingOne.
  ///
  /// In en, this message translates to:
  /// **'Favoriting post #{id}'**
  String postFavoritingOne(Object id);

  /// No description provided for @postFavoritingProgress.
  ///
  /// In en, this message translates to:
  /// **'Favoriting post #{id} ({current}/{total})'**
  String postFavoritingProgress(Object id, Object current, Object total);

  /// No description provided for @postUnfavoritingOne.
  ///
  /// In en, this message translates to:
  /// **'Unfavoriting post #{id}'**
  String postUnfavoritingOne(Object id);

  /// No description provided for @postUnfavoritingProgress.
  ///
  /// In en, this message translates to:
  /// **'Unfavoriting post #{id} ({current}/{total})'**
  String postUnfavoritingProgress(Object id, Object current, Object total);

  /// No description provided for @postFavoriteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to favorite post #{id}'**
  String postFavoriteFailed(Object id);

  /// No description provided for @postUnfavoriteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to unfavorite post #{id}'**
  String postUnfavoriteFailed(Object id);

  /// No description provided for @postFavoritingCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled favoriting'**
  String get postFavoritingCancelled;

  /// No description provided for @postUnfavoritingCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled unfavoriting'**
  String get postUnfavoritingCancelled;

  /// No description provided for @postSelectionOne.
  ///
  /// In en, this message translates to:
  /// **'post #{id}'**
  String postSelectionOne(Object id);

  /// No description provided for @postSelectionMany.
  ///
  /// In en, this message translates to:
  /// **'{count} posts'**
  String postSelectionMany(Object count);

  /// No description provided for @postFilterFavoriteCount.
  ///
  /// In en, this message translates to:
  /// **'Favorite count'**
  String get postFilterFavoriteCount;

  /// No description provided for @postFilterPool.
  ///
  /// In en, this message translates to:
  /// **'Pool'**
  String get postFilterPool;

  /// No description provided for @postFilterHasPool.
  ///
  /// In en, this message translates to:
  /// **'Has pool'**
  String get postFilterHasPool;

  /// No description provided for @postFilterChild.
  ///
  /// In en, this message translates to:
  /// **'Child'**
  String get postFilterChild;

  /// No description provided for @postFilterIsChild.
  ///
  /// In en, this message translates to:
  /// **'Is child post'**
  String get postFilterIsChild;

  /// No description provided for @postFilterIsParent.
  ///
  /// In en, this message translates to:
  /// **'Is parent post'**
  String get postFilterIsParent;

  /// No description provided for @postFilterUploadDate.
  ///
  /// In en, this message translates to:
  /// **'Upload date'**
  String get postFilterUploadDate;

  /// No description provided for @postFilterDateAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get postFilterDateAll;

  /// No description provided for @postFilterDateLastDay.
  ///
  /// In en, this message translates to:
  /// **'Last day'**
  String get postFilterDateLastDay;

  /// No description provided for @postFilterDateLastWeek.
  ///
  /// In en, this message translates to:
  /// **'Last week'**
  String get postFilterDateLastWeek;

  /// No description provided for @postFilterDateLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last Month'**
  String get postFilterDateLastMonth;

  /// No description provided for @postFilterDateLastYear.
  ///
  /// In en, this message translates to:
  /// **'Last Year'**
  String get postFilterDateLastYear;

  /// No description provided for @postFilterStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get postFilterStatus;

  /// No description provided for @postFilterStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get postFilterStatusActive;

  /// No description provided for @postFilterStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get postFilterStatusPending;

  /// No description provided for @postFilterStatusDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get postFilterStatusDeleted;

  /// No description provided for @postFilterStatusFlagged.
  ///
  /// In en, this message translates to:
  /// **'Flagged'**
  String get postFilterStatusFlagged;

  /// No description provided for @postFilterStatusAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get postFilterStatusAny;

  /// No description provided for @postSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get postSearch;

  /// No description provided for @postSearchTags.
  ///
  /// In en, this message translates to:
  /// **'Search tags'**
  String get postSearchTags;

  /// No description provided for @postHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get postHome;

  /// No description provided for @postPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get postPopular;

  /// No description provided for @postPosts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get postPosts;

  /// No description provided for @postFavsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Favorites are unavailable for anonymous users'**
  String get postFavsUnavailable;

  /// No description provided for @postFavOrder.
  ///
  /// In en, this message translates to:
  /// **'Favorite order'**
  String get postFavOrder;

  /// No description provided for @postFavOrderAdded.
  ///
  /// In en, this message translates to:
  /// **'added order'**
  String get postFavOrderAdded;

  /// No description provided for @postFavOrderId.
  ///
  /// In en, this message translates to:
  /// **'id order'**
  String get postFavOrderId;

  /// No description provided for @postDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get postDay;

  /// No description provided for @postWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get postWeek;

  /// No description provided for @postMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get postMonth;

  /// No description provided for @postHot.
  ///
  /// In en, this message translates to:
  /// **'Hot'**
  String get postHot;

  /// No description provided for @postPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick date'**
  String get postPickDate;

  /// No description provided for @postEditReasonOptional.
  ///
  /// In en, this message translates to:
  /// **'Edit reason (optional)'**
  String get postEditReasonOptional;

  /// No description provided for @postEditReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Why are you editing this post?'**
  String get postEditReasonHint;

  /// No description provided for @postEditDescriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'#{id} description'**
  String postEditDescriptionTitle(Object id);

  /// No description provided for @postEditDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Enter post description...'**
  String get postEditDescriptionHint;

  /// No description provided for @postEditNoDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get postEditNoDescription;

  /// No description provided for @postEditParentIdOptional.
  ///
  /// In en, this message translates to:
  /// **'Parent ID (optional)'**
  String get postEditParentIdOptional;

  /// No description provided for @postEditParentIdHint.
  ///
  /// In en, this message translates to:
  /// **'Parent post ID'**
  String get postEditParentIdHint;

  /// No description provided for @postEditInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number format'**
  String get postEditInvalidNumber;

  /// No description provided for @postEditInvalidParent.
  ///
  /// In en, this message translates to:
  /// **'Invalid parent post'**
  String get postEditInvalidParent;

  /// No description provided for @postEditSourcesTitle.
  ///
  /// In en, this message translates to:
  /// **'#{id} sources'**
  String postEditSourcesTitle(Object id);

  /// No description provided for @postEditNoSources.
  ///
  /// In en, this message translates to:
  /// **'No sources'**
  String get postEditNoSources;

  /// No description provided for @postEditSpaceSeparated.
  ///
  /// In en, this message translates to:
  /// **'space separated tags'**
  String get postEditSpaceSeparated;

  /// No description provided for @postEditTagNew.
  ///
  /// In en, this message translates to:
  /// **'new'**
  String get postEditTagNew;

  /// No description provided for @postEditTagInvalid.
  ///
  /// In en, this message translates to:
  /// **'invalid'**
  String get postEditTagInvalid;

  /// No description provided for @postEditTagEmpty.
  ///
  /// In en, this message translates to:
  /// **'empty'**
  String get postEditTagEmpty;

  /// No description provided for @postEditTagUnderused.
  ///
  /// In en, this message translates to:
  /// **'underused'**
  String get postEditTagUnderused;

  /// No description provided for @postFlaggedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Flagged post #{id}'**
  String postFlaggedSuccess(Object id);

  /// No description provided for @postFlagFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to flag post #{id}'**
  String postFlagFailed(Object id);

  /// No description provided for @postFlagTitle.
  ///
  /// In en, this message translates to:
  /// **'Post #{id}'**
  String postFlagTitle(Object id);

  /// No description provided for @postFlag.
  ///
  /// In en, this message translates to:
  /// **'Flag'**
  String get postFlag;

  /// No description provided for @postFlagParentId.
  ///
  /// In en, this message translates to:
  /// **'Parent ID'**
  String get postFlagParentId;

  /// No description provided for @postFlagParentIdEmpty.
  ///
  /// In en, this message translates to:
  /// **'Parent ID cannot be empty'**
  String get postFlagParentIdEmpty;

  /// No description provided for @postFlagParentIdNumber.
  ///
  /// In en, this message translates to:
  /// **'Parent ID must be a number'**
  String get postFlagParentIdNumber;

  /// No description provided for @settingsFailedLoadAccounts.
  ///
  /// In en, this message translates to:
  /// **'Failed to load accounts'**
  String get settingsFailedLoadAccounts;

  /// No description provided for @settingsTryReopen.
  ///
  /// In en, this message translates to:
  /// **'Try reopening Settings.'**
  String get settingsTryReopen;

  /// No description provided for @settingsLoadingAccounts.
  ///
  /// In en, this message translates to:
  /// **'Loading accounts...'**
  String get settingsLoadingAccounts;

  /// No description provided for @settingsSwitchingAccount.
  ///
  /// In en, this message translates to:
  /// **'Switching account...'**
  String get settingsSwitchingAccount;

  /// No description provided for @settingsFailedConnect.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect to {host}'**
  String settingsFailedConnect(Object host);

  /// No description provided for @settingsConnectedTo.
  ///
  /// In en, this message translates to:
  /// **'Connected to {host}'**
  String settingsConnectedTo(Object host);

  /// No description provided for @settingsDeleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get settingsDeleteAccountTitle;

  /// No description provided for @settingsDeleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'All local data will be removed, including follows and history.'**
  String get settingsDeleteAccountBody;

  /// No description provided for @settingsDeleteUpper.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get settingsDeleteUpper;

  /// No description provided for @settingsActiveAccount.
  ///
  /// In en, this message translates to:
  /// **'Active account • {host}'**
  String settingsActiveAccount(Object host);

  /// No description provided for @settingsActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get settingsActive;

  /// No description provided for @settingsAddAccount.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get settingsAddAccount;

  /// No description provided for @settingsActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get settingsActivate;

  /// No description provided for @settingsTest.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get settingsTest;

  /// No description provided for @settingsBlacklist.
  ///
  /// In en, this message translates to:
  /// **'Blacklist'**
  String get settingsBlacklist;

  /// No description provided for @settingsTagsBlocked.
  ///
  /// In en, this message translates to:
  /// **'{count} tags blocked'**
  String settingsTagsBlocked(Object count);

  /// No description provided for @settingsFollows.
  ///
  /// In en, this message translates to:
  /// **'Follows'**
  String get settingsFollows;

  /// No description provided for @settingsSearchesFollowed.
  ///
  /// In en, this message translates to:
  /// **'{count} searches followed'**
  String settingsSearchesFollowed(Object count);

  /// No description provided for @settingsHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get settingsHistory;

  /// No description provided for @settingsPagesVisited.
  ///
  /// In en, this message translates to:
  /// **'{count} pages visited'**
  String settingsPagesVisited(Object count);

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsAccentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get settingsAccentColor;

  /// No description provided for @settingsAccentPreset.
  ///
  /// In en, this message translates to:
  /// **'Preset'**
  String get settingsAccentPreset;

  /// No description provided for @settingsAccentPresetDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get settingsAccentPresetDefault;

  /// No description provided for @settingsAccentPresetPink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get settingsAccentPresetPink;

  /// No description provided for @settingsAccentPresetRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get settingsAccentPresetRed;

  /// No description provided for @settingsAccentPresetPurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get settingsAccentPresetPurple;

  /// No description provided for @settingsAccentPresetIndigo.
  ///
  /// In en, this message translates to:
  /// **'Indigo'**
  String get settingsAccentPresetIndigo;

  /// No description provided for @settingsAccentPresetBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get settingsAccentPresetBlue;

  /// No description provided for @settingsAccentPresetTeal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get settingsAccentPresetTeal;

  /// No description provided for @settingsAccentPresetGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get settingsAccentPresetGreen;

  /// No description provided for @settingsTileSize.
  ///
  /// In en, this message translates to:
  /// **'Tile size'**
  String get settingsTileSize;

  /// No description provided for @settingsTileSizeValue.
  ///
  /// In en, this message translates to:
  /// **'{value} px'**
  String settingsTileSizeValue(Object value);

  /// No description provided for @settingsQuilt.
  ///
  /// In en, this message translates to:
  /// **'Quilt'**
  String get settingsQuilt;

  /// No description provided for @settingsGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get settingsGrid;

  /// No description provided for @settingsQuiltQuadratic.
  ///
  /// In en, this message translates to:
  /// **'tiles are quadratic'**
  String get settingsQuiltQuadratic;

  /// No description provided for @settingsQuiltExpand.
  ///
  /// In en, this message translates to:
  /// **'tiles expand vertically'**
  String get settingsQuiltExpand;

  /// No description provided for @settingsPostInfo.
  ///
  /// In en, this message translates to:
  /// **'Post info'**
  String get settingsPostInfo;

  /// No description provided for @settingsPostInfoOnTiles.
  ///
  /// In en, this message translates to:
  /// **'Info on post tiles'**
  String get settingsPostInfoOnTiles;

  /// No description provided for @settingsPostInfoImageOnly.
  ///
  /// In en, this message translates to:
  /// **'Image tiles only'**
  String get settingsPostInfoImageOnly;

  /// No description provided for @settingsPopularHotTab.
  ///
  /// In en, this message translates to:
  /// **'Hot tab'**
  String get settingsPopularHotTab;

  /// No description provided for @settingsPopularHotTabSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show the Hot option in the Popular page'**
  String get settingsPopularHotTabSubtitle;

  /// No description provided for @settingsPostActionBar.
  ///
  /// In en, this message translates to:
  /// **'Post action bar'**
  String get settingsPostActionBar;

  /// No description provided for @settingsActionsPinned.
  ///
  /// In en, this message translates to:
  /// **'{count} actions pinned'**
  String settingsActionsPinned(Object count);

  /// No description provided for @settingsActionBarPlacement.
  ///
  /// In en, this message translates to:
  /// **'Action bar placement'**
  String get settingsActionBarPlacement;

  /// No description provided for @settingsPlacementFloating.
  ///
  /// In en, this message translates to:
  /// **'Mobile: floating above navbar'**
  String get settingsPlacementFloating;

  /// No description provided for @settingsPlacementInline.
  ///
  /// In en, this message translates to:
  /// **'Mobile: inline on post page'**
  String get settingsPlacementInline;

  /// No description provided for @settingsDownloadLocation.
  ///
  /// In en, this message translates to:
  /// **'Download location'**
  String get settingsDownloadLocation;

  /// No description provided for @settingsChooseDirectory.
  ///
  /// In en, this message translates to:
  /// **'Choose directory'**
  String get settingsChooseDirectory;

  /// No description provided for @settingsUpvoteFavorites.
  ///
  /// In en, this message translates to:
  /// **'Upvote favorites'**
  String get settingsUpvoteFavorites;

  /// No description provided for @settingsUpvoteAndFav.
  ///
  /// In en, this message translates to:
  /// **'Upvote and favorite'**
  String get settingsUpvoteAndFav;

  /// No description provided for @settingsFavOnly.
  ///
  /// In en, this message translates to:
  /// **'Favorite only'**
  String get settingsFavOnly;

  /// No description provided for @settingsVideoVolume.
  ///
  /// In en, this message translates to:
  /// **'Video volume'**
  String get settingsVideoVolume;

  /// No description provided for @settingsMuted.
  ///
  /// In en, this message translates to:
  /// **'Muted'**
  String get settingsMuted;

  /// No description provided for @settingsWithSound.
  ///
  /// In en, this message translates to:
  /// **'With sound'**
  String get settingsWithSound;

  /// No description provided for @settingsAutoplayVideos.
  ///
  /// In en, this message translates to:
  /// **'Autoplay videos'**
  String get settingsAutoplayVideos;

  /// No description provided for @settingsPlayAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Play automatically'**
  String get settingsPlayAutomatically;

  /// No description provided for @settingsPlayOnTap.
  ///
  /// In en, this message translates to:
  /// **'Play on tap'**
  String get settingsPlayOnTap;

  /// No description provided for @settingsVideoResolution.
  ///
  /// In en, this message translates to:
  /// **'Video resolution'**
  String get settingsVideoResolution;

  /// No description provided for @settingsIFinished.
  ///
  /// In en, this message translates to:
  /// **'I Finished'**
  String get settingsIFinished;

  /// No description provided for @settingsIFinishedDesc.
  ///
  /// In en, this message translates to:
  /// **'Button on post detail to mark finished'**
  String get settingsIFinishedDesc;

  /// No description provided for @settingsIFinishedOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsIFinishedOff;

  /// No description provided for @settingsRequestPhoto.
  ///
  /// In en, this message translates to:
  /// **'Request image on completion'**
  String get settingsRequestPhoto;

  /// No description provided for @settingsRequestPhotoDesc.
  ///
  /// In en, this message translates to:
  /// **'Ask for a photo when marking I Finished'**
  String get settingsRequestPhotoDesc;

  /// No description provided for @settingsRequestPhotoOff.
  ///
  /// In en, this message translates to:
  /// **'No photo'**
  String get settingsRequestPhotoOff;

  /// No description provided for @settingsSecureDisplay.
  ///
  /// In en, this message translates to:
  /// **'Secure display'**
  String get settingsSecureDisplay;

  /// No description provided for @settingsScreenProtected.
  ///
  /// In en, this message translates to:
  /// **'Screen protected'**
  String get settingsScreenProtected;

  /// No description provided for @settingsScreenVisible.
  ///
  /// In en, this message translates to:
  /// **'Screen visible'**
  String get settingsScreenVisible;

  /// No description provided for @settingsIncognitoKeyboard.
  ///
  /// In en, this message translates to:
  /// **'Incognito keyboard'**
  String get settingsIncognitoKeyboard;

  /// No description provided for @settingsAllowHttpHosts.
  ///
  /// In en, this message translates to:
  /// **'Allow HTTP hosts'**
  String get settingsAllowHttpHosts;

  /// No description provided for @settingsAllowHttpDesc.
  ///
  /// In en, this message translates to:
  /// **'http:// for local or self-hosted (unencrypted)'**
  String get settingsAllowHttpDesc;

  /// No description provided for @settingsHttpsOnly.
  ///
  /// In en, this message translates to:
  /// **'https:// only'**
  String get settingsHttpsOnly;

  /// No description provided for @settingsPinLock.
  ///
  /// In en, this message translates to:
  /// **'PIN lock'**
  String get settingsPinLock;

  /// No description provided for @settingsPinEnabled.
  ///
  /// In en, this message translates to:
  /// **'PIN enabled'**
  String get settingsPinEnabled;

  /// No description provided for @settingsPinDisabled.
  ///
  /// In en, this message translates to:
  /// **'PIN disabled'**
  String get settingsPinDisabled;

  /// No description provided for @settingsBiometricLock.
  ///
  /// In en, this message translates to:
  /// **'Biometric lock'**
  String get settingsBiometricLock;

  /// No description provided for @settingsBiometricsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Biometrics enabled'**
  String get settingsBiometricsEnabled;

  /// No description provided for @settingsBiometricsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Biometrics disabled'**
  String get settingsBiometricsDisabled;

  /// No description provided for @settingsDeveloperMode.
  ///
  /// In en, this message translates to:
  /// **'Developer mode'**
  String get settingsDeveloperMode;

  /// No description provided for @settingsOptionsShown.
  ///
  /// In en, this message translates to:
  /// **'Options shown'**
  String get settingsOptionsShown;

  /// No description provided for @settingsLogs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get settingsLogs;

  /// No description provided for @settingsErrorsLogged.
  ///
  /// In en, this message translates to:
  /// **'{count} errors logged'**
  String settingsErrorsLogged(Object count);

  /// No description provided for @settingsDatabase.
  ///
  /// In en, this message translates to:
  /// **'Database'**
  String get settingsDatabase;

  /// No description provided for @settingsPinnedActions.
  ///
  /// In en, this message translates to:
  /// **'Pinned actions are shown first on post detail. Drag to reorder.'**
  String get settingsPinnedActions;

  /// No description provided for @settingsAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get settingsAvailable;

  /// No description provided for @settingsNotOnList.
  ///
  /// In en, this message translates to:
  /// **'Not on the list? contact us!'**
  String get settingsNotOnList;

  /// No description provided for @identityEditAccount.
  ///
  /// In en, this message translates to:
  /// **'Edit account'**
  String get identityEditAccount;

  /// No description provided for @identityAddAccount.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get identityAddAccount;

  /// No description provided for @identityNoAccountSignUp.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up here'**
  String get identityNoAccountSignUp;

  /// No description provided for @identityWhereApiKey.
  ///
  /// In en, this message translates to:
  /// **'Where do I find my API key?'**
  String get identityWhereApiKey;

  /// No description provided for @identityConnectingTo.
  ///
  /// In en, this message translates to:
  /// **'Connecting to {host} as {user}...'**
  String identityConnectingTo(Object host, Object user);

  /// No description provided for @identityHostRequired.
  ///
  /// In en, this message translates to:
  /// **'You must provide a host URL.'**
  String get identityHostRequired;

  /// No description provided for @identityHostInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid host URL'**
  String get identityHostInvalid;

  /// No description provided for @identityUsernameRequired.
  ///
  /// In en, this message translates to:
  /// **'You must provide a username.'**
  String get identityUsernameRequired;

  /// No description provided for @identityApiKeyRequired.
  ///
  /// In en, this message translates to:
  /// **'You must provide an API key.\ne.g. {example}'**
  String identityApiKeyRequired(Object example);

  /// No description provided for @identityApiKeyInvalid.
  ///
  /// In en, this message translates to:
  /// **'API key is 16–80 characters (letters, digits, optional underscore)\ne.g. {example}'**
  String identityApiKeyInvalid(Object example);

  /// No description provided for @identityCheckNetwork.
  ///
  /// In en, this message translates to:
  /// **'Check your network connection and login details'**
  String get identityCheckNetwork;

  /// No description provided for @identityFailedLogin.
  ///
  /// In en, this message translates to:
  /// **'Failed to login.\n{value}'**
  String identityFailedLogin(Object value);

  /// No description provided for @identityDuplicate.
  ///
  /// In en, this message translates to:
  /// **'You already have an identity under this host and username.'**
  String get identityDuplicate;

  /// No description provided for @identityHostUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Host unavailable'**
  String get identityHostUnavailable;

  /// No description provided for @identityHostUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'It appears that {host} is not available!'**
  String identityHostUnavailableBody(Object host);

  /// No description provided for @identityResolveBody.
  ///
  /// In en, this message translates to:
  /// **'Please resolve the issue in the following browser window. \n\nCloudflare captcha cookies will be saved. '**
  String get identityResolveBody;

  /// No description provided for @identityWaitForHost.
  ///
  /// In en, this message translates to:
  /// **'\nPlease wait for {host} to resolve the situation on their end.'**
  String identityWaitForHost(Object host);

  /// No description provided for @identityDesktopLogin.
  ///
  /// In en, this message translates to:
  /// **'On desktop, log in using your browser and add an API key in Settings.'**
  String get identityDesktopLogin;

  /// No description provided for @identityOpenLoginBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open login in browser'**
  String get identityOpenLoginBrowser;

  /// No description provided for @identityMustBeLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'You must be logged in to perform this action.'**
  String get identityMustBeLoggedIn;

  /// No description provided for @identityChooseIdentity.
  ///
  /// In en, this message translates to:
  /// **'Choose identity'**
  String get identityChooseIdentity;

  /// No description provided for @identityApiKeyExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. {example}'**
  String identityApiKeyExample(Object example);

  /// No description provided for @appEnterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get appEnterPin;

  /// No description provided for @appEnterNewPin.
  ///
  /// In en, this message translates to:
  /// **'Enter new PIN'**
  String get appEnterNewPin;

  /// No description provided for @appConfirmNewPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm new PIN'**
  String get appConfirmNewPin;

  /// No description provided for @appFailedAuthenticate.
  ///
  /// In en, this message translates to:
  /// **'Failed to authenticate'**
  String get appFailedAuthenticate;

  /// No description provided for @appPleaseAuthenticate.
  ///
  /// In en, this message translates to:
  /// **'Please authenticate'**
  String get appPleaseAuthenticate;

  /// No description provided for @appAuthenticateToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to unlock.'**
  String get appAuthenticateToUnlock;

  /// No description provided for @appBiometricFailure.
  ///
  /// In en, this message translates to:
  /// **'Severe failure in biometric authentication'**
  String get appBiometricFailure;

  /// No description provided for @appFailedInitialize.
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize'**
  String get appFailedInitialize;

  /// No description provided for @commentSent.
  ///
  /// In en, this message translates to:
  /// **'Comment sent!'**
  String get commentSent;

  /// No description provided for @commentLogInToAdd.
  ///
  /// In en, this message translates to:
  /// **'Log in to add a comment'**
  String get commentLogInToAdd;

  /// No description provided for @commentAddComment.
  ///
  /// In en, this message translates to:
  /// **'Add comment'**
  String get commentAddComment;

  /// No description provided for @commentNoComments.
  ///
  /// In en, this message translates to:
  /// **'No comments'**
  String get commentNoComments;

  /// No description provided for @commentFailedLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load comments'**
  String get commentFailedLoad;

  /// No description provided for @commentPostComments.
  ///
  /// In en, this message translates to:
  /// **'#{id} comments'**
  String commentPostComments(Object id);

  /// No description provided for @commentFailedUpvote.
  ///
  /// In en, this message translates to:
  /// **'Failed to upvote comment #{id}'**
  String commentFailedUpvote(Object id);

  /// No description provided for @commentFailedDownvote.
  ///
  /// In en, this message translates to:
  /// **'Failed to downvote comment #{id}'**
  String commentFailedDownvote(Object id);

  /// No description provided for @commentHidden.
  ///
  /// In en, this message translates to:
  /// **'This comment is hidden'**
  String get commentHidden;

  /// No description provided for @commentMustLoginEdit.
  ///
  /// In en, this message translates to:
  /// **'You must be logged in to edit comments!'**
  String get commentMustLoginEdit;

  /// No description provided for @commentMustLoginReply.
  ///
  /// In en, this message translates to:
  /// **'You must be logged in to reply to comments!'**
  String get commentMustLoginReply;

  /// No description provided for @commentMustLoginReport.
  ///
  /// In en, this message translates to:
  /// **'You must be logged in to report comments!'**
  String get commentMustLoginReport;

  /// No description provided for @commentCopiedId.
  ///
  /// In en, this message translates to:
  /// **'Copied comment id #{id}'**
  String commentCopiedId(Object id);

  /// No description provided for @commentReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get commentReply;

  /// No description provided for @commentCopyId.
  ///
  /// In en, this message translates to:
  /// **'Copy ID'**
  String get commentCopyId;

  /// No description provided for @commentCommentOrder.
  ///
  /// In en, this message translates to:
  /// **'Comment order'**
  String get commentCommentOrder;

  /// No description provided for @commentOldestFirst.
  ///
  /// In en, this message translates to:
  /// **'oldest first'**
  String get commentOldestFirst;

  /// No description provided for @commentNewestFirst.
  ///
  /// In en, this message translates to:
  /// **'newest first'**
  String get commentNewestFirst;

  /// No description provided for @commentCommentTitle.
  ///
  /// In en, this message translates to:
  /// **'Comment #{id}'**
  String commentCommentTitle(Object id);

  /// No description provided for @commentFailedLoadOne.
  ///
  /// In en, this message translates to:
  /// **'Failed to load comment'**
  String get commentFailedLoadOne;

  /// No description provided for @commentNotFound.
  ///
  /// In en, this message translates to:
  /// **'Comment not found'**
  String get commentNotFound;

  /// No description provided for @commentDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'#{id} comment'**
  String commentDialogTitle(Object id);

  /// No description provided for @commentRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get commentRefresh;

  /// No description provided for @topicHideTagsEdits.
  ///
  /// In en, this message translates to:
  /// **'hide tags edits'**
  String get topicHideTagsEdits;

  /// No description provided for @topicHideTagsAliasShow.
  ///
  /// In en, this message translates to:
  /// **'show tag alias and implications'**
  String get topicHideTagsAliasShow;

  /// No description provided for @topicHideTagsAliasHide.
  ///
  /// In en, this message translates to:
  /// **'hide tag alias and implications'**
  String get topicHideTagsAliasHide;

  /// No description provided for @topicNoTopics.
  ///
  /// In en, this message translates to:
  /// **'No topics'**
  String get topicNoTopics;

  /// No description provided for @topicFailedLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load topics'**
  String get topicFailedLoad;

  /// No description provided for @topicReplies.
  ///
  /// In en, this message translates to:
  /// **'replies'**
  String get topicReplies;

  /// No description provided for @topicLocked.
  ///
  /// In en, this message translates to:
  /// **'locked'**
  String get topicLocked;

  /// No description provided for @topicCreated.
  ///
  /// In en, this message translates to:
  /// **'created'**
  String get topicCreated;

  /// No description provided for @topicUpdated.
  ///
  /// In en, this message translates to:
  /// **'updated'**
  String get topicUpdated;

  /// No description provided for @topicCopiedId.
  ///
  /// In en, this message translates to:
  /// **'Copied topic id #{id}'**
  String topicCopiedId(Object id);

  /// No description provided for @topicTitle.
  ///
  /// In en, this message translates to:
  /// **'Topic #{id}'**
  String topicTitle(Object id);

  /// No description provided for @topicFailedLoadOne.
  ///
  /// In en, this message translates to:
  /// **'Failed to load topic'**
  String get topicFailedLoadOne;

  /// No description provided for @topicNotFound.
  ///
  /// In en, this message translates to:
  /// **'Topic not found'**
  String get topicNotFound;

  /// No description provided for @topicTopics.
  ///
  /// In en, this message translates to:
  /// **'Topics'**
  String get topicTopics;

  /// No description provided for @replyReplies.
  ///
  /// In en, this message translates to:
  /// **'Replies'**
  String get replyReplies;

  /// No description provided for @replyOrder.
  ///
  /// In en, this message translates to:
  /// **'Reply order'**
  String get replyOrder;

  /// No description provided for @replyNoReplies.
  ///
  /// In en, this message translates to:
  /// **'No replies'**
  String get replyNoReplies;

  /// No description provided for @replyFailedLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load replies'**
  String get replyFailedLoad;

  /// No description provided for @replyHidden.
  ///
  /// In en, this message translates to:
  /// **'This reply is hidden'**
  String get replyHidden;

  /// No description provided for @replyTitle.
  ///
  /// In en, this message translates to:
  /// **'Reply #{id}'**
  String replyTitle(Object id);

  /// No description provided for @replyFailedLoadOne.
  ///
  /// In en, this message translates to:
  /// **'Failed to load reply'**
  String get replyFailedLoadOne;

  /// No description provided for @replyNotFound.
  ///
  /// In en, this message translates to:
  /// **'Reply not found'**
  String get replyNotFound;

  /// No description provided for @followFollowsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} follows'**
  String followFollowsCount(Object count);

  /// No description provided for @followDisableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Disable notifications'**
  String get followDisableNotifications;

  /// No description provided for @followEnableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get followEnableNotifications;

  /// No description provided for @followSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get followSubscribe;

  /// No description provided for @followBookmark.
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get followBookmark;

  /// No description provided for @followMarkSeen.
  ///
  /// In en, this message translates to:
  /// **'mark {count} posts as seen'**
  String followMarkSeen(Object count);

  /// No description provided for @followNoUnseen.
  ///
  /// In en, this message translates to:
  /// **'no unseen posts'**
  String get followNoUnseen;

  /// No description provided for @followBookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get followBookmarks;

  /// No description provided for @followAddToBookmarks.
  ///
  /// In en, this message translates to:
  /// **'Add to bookmarks'**
  String get followAddToBookmarks;

  /// No description provided for @followNoBookmarks.
  ///
  /// In en, this message translates to:
  /// **'No bookmarks'**
  String get followNoBookmarks;

  /// No description provided for @followFailedLoadBookmarks.
  ///
  /// In en, this message translates to:
  /// **'Failed to load bookmarks'**
  String get followFailedLoadBookmarks;

  /// No description provided for @followUnseenPosts.
  ///
  /// In en, this message translates to:
  /// **'unseen posts'**
  String get followUnseenPosts;

  /// No description provided for @followShowUnseenFirst.
  ///
  /// In en, this message translates to:
  /// **'show unseen first'**
  String get followShowUnseenFirst;

  /// No description provided for @followFilteringUnseen.
  ///
  /// In en, this message translates to:
  /// **'filtering for unseen'**
  String get followFilteringUnseen;

  /// No description provided for @followAllPostsShown.
  ///
  /// In en, this message translates to:
  /// **'all posts shown'**
  String get followAllPostsShown;

  /// No description provided for @followEditFollows.
  ///
  /// In en, this message translates to:
  /// **'Edit follows'**
  String get followEditFollows;

  /// No description provided for @followForceSync.
  ///
  /// In en, this message translates to:
  /// **'Force sync'**
  String get followForceSync;

  /// No description provided for @followSyncAll.
  ///
  /// In en, this message translates to:
  /// **'sync all follows'**
  String get followSyncAll;

  /// No description provided for @followSyncing.
  ///
  /// In en, this message translates to:
  /// **'syncing follows...'**
  String get followSyncing;

  /// No description provided for @followEditFollow.
  ///
  /// In en, this message translates to:
  /// **'Edit follow'**
  String get followEditFollow;

  /// No description provided for @followMarkAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get followMarkAsRead;

  /// No description provided for @followRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get followRename;

  /// No description provided for @followFollowTitle.
  ///
  /// In en, this message translates to:
  /// **'Follow title'**
  String get followFollowTitle;

  /// No description provided for @followNewPost.
  ///
  /// In en, this message translates to:
  /// **'new post'**
  String get followNewPost;

  /// No description provided for @followNewPosts.
  ///
  /// In en, this message translates to:
  /// **'new posts'**
  String get followNewPosts;

  /// No description provided for @followAlias.
  ///
  /// In en, this message translates to:
  /// **'alias {name}'**
  String followAlias(Object name);

  /// No description provided for @followNewPostsNotif.
  ///
  /// In en, this message translates to:
  /// **'New posts!'**
  String get followNewPostsNotif;

  /// No description provided for @poolPosts.
  ///
  /// In en, this message translates to:
  /// **'posts'**
  String get poolPosts;

  /// No description provided for @poolCopiedId.
  ///
  /// In en, this message translates to:
  /// **'Copied pool id #{id}'**
  String poolCopiedId(Object id);

  /// No description provided for @poolActivity.
  ///
  /// In en, this message translates to:
  /// **'activity'**
  String get poolActivity;

  /// No description provided for @poolPoolOrder.
  ///
  /// In en, this message translates to:
  /// **'Pool order'**
  String get poolPoolOrder;

  /// No description provided for @poolReaderMode.
  ///
  /// In en, this message translates to:
  /// **'Pool reader mode'**
  String get poolReaderMode;

  /// No description provided for @poolLargeImages.
  ///
  /// In en, this message translates to:
  /// **'large images'**
  String get poolLargeImages;

  /// No description provided for @poolNormalGrid.
  ///
  /// In en, this message translates to:
  /// **'normal grid'**
  String get poolNormalGrid;

  /// No description provided for @poolNoPools.
  ///
  /// In en, this message translates to:
  /// **'No pools'**
  String get poolNoPools;

  /// No description provided for @poolFailedLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load pools'**
  String get poolFailedLoad;

  /// No description provided for @poolPoolTitle.
  ///
  /// In en, this message translates to:
  /// **'Pool #{id}'**
  String poolPoolTitle(Object id);

  /// No description provided for @poolFailedLoadOne.
  ///
  /// In en, this message translates to:
  /// **'Failed to load pool'**
  String get poolFailedLoadOne;

  /// No description provided for @poolNotFound.
  ///
  /// In en, this message translates to:
  /// **'Pool not found'**
  String get poolNotFound;

  /// No description provided for @poolPools.
  ///
  /// In en, this message translates to:
  /// **'Pools'**
  String get poolPools;

  /// No description provided for @poolCreator.
  ///
  /// In en, this message translates to:
  /// **'Creator'**
  String get poolCreator;

  /// No description provided for @poolIsActive.
  ///
  /// In en, this message translates to:
  /// **'Is active'**
  String get poolIsActive;

  /// No description provided for @poolCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get poolCategory;

  /// No description provided for @poolCategorySeries.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get poolCategorySeries;

  /// No description provided for @poolCategoryCollection.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get poolCategoryCollection;

  /// No description provided for @poolPoolTitleField.
  ///
  /// In en, this message translates to:
  /// **'Pool title'**
  String get poolPoolTitleField;

  /// No description provided for @wikiCopiedId.
  ///
  /// In en, this message translates to:
  /// **'Copied wiki id #{id}'**
  String wikiCopiedId(Object id);

  /// No description provided for @wikiAlias.
  ///
  /// In en, this message translates to:
  /// **'alias'**
  String get wikiAlias;

  /// No description provided for @wikiWikiTitle.
  ///
  /// In en, this message translates to:
  /// **'Wiki #{id}'**
  String wikiWikiTitle(Object id);

  /// No description provided for @wikiFailedLoadOne.
  ///
  /// In en, this message translates to:
  /// **'Failed to load wiki'**
  String get wikiFailedLoadOne;

  /// No description provided for @wikiNotFound.
  ///
  /// In en, this message translates to:
  /// **'Wiki not found'**
  String get wikiNotFound;

  /// No description provided for @wikiUnableRetrieve.
  ///
  /// In en, this message translates to:
  /// **'unable to retrieve wiki entry'**
  String get wikiUnableRetrieve;

  /// No description provided for @wikiNoWikiEntry.
  ///
  /// In en, this message translates to:
  /// **'no wiki entry'**
  String get wikiNoWikiEntry;

  /// No description provided for @wikiFailedLoadTags.
  ///
  /// In en, this message translates to:
  /// **'failed to load tags'**
  String get wikiFailedLoadTags;

  /// No description provided for @userProfileUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Profile is not available for anonymous users'**
  String get userProfileUnavailable;

  /// No description provided for @userFailedLoadProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile'**
  String get userFailedLoadProfile;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get userNotFound;

  /// No description provided for @userMustLoginReport.
  ///
  /// In en, this message translates to:
  /// **'You must be logged in to report users!'**
  String get userMustLoginReport;

  /// No description provided for @userCopiedId.
  ///
  /// In en, this message translates to:
  /// **'Copied user id #{id}'**
  String userCopiedId(Object id);

  /// No description provided for @userCommission.
  ///
  /// In en, this message translates to:
  /// **'Commission'**
  String get userCommission;

  /// No description provided for @userJoined.
  ///
  /// In en, this message translates to:
  /// **'joined'**
  String get userJoined;

  /// No description provided for @userRank.
  ///
  /// In en, this message translates to:
  /// **'rank'**
  String get userRank;

  /// No description provided for @userEdits.
  ///
  /// In en, this message translates to:
  /// **'edits'**
  String get userEdits;

  /// No description provided for @userComments.
  ///
  /// In en, this message translates to:
  /// **'comments'**
  String get userComments;

  /// No description provided for @userForum.
  ///
  /// In en, this message translates to:
  /// **'forum'**
  String get userForum;

  /// No description provided for @historyHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyHistory;

  /// No description provided for @historyEntriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} entries'**
  String historyEntriesCount(Object count);

  /// No description provided for @historyEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get historyEnabled;

  /// No description provided for @historyPagesVisited.
  ///
  /// In en, this message translates to:
  /// **'{count} pages visited'**
  String historyPagesVisited(Object count);

  /// No description provided for @historyClearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get historyClearHistory;

  /// No description provided for @historyDeleteAllEntries.
  ///
  /// In en, this message translates to:
  /// **'Delete all entries'**
  String get historyDeleteAllEntries;

  /// No description provided for @historyClearHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear history?'**
  String get historyClearHistoryTitle;

  /// No description provided for @historyClearHistoryBody.
  ///
  /// In en, this message translates to:
  /// **'All history entries will be permanently deleted. This action cannot be undone.'**
  String get historyClearHistoryBody;

  /// No description provided for @historyHistoryLimit.
  ///
  /// In en, this message translates to:
  /// **'History limit'**
  String get historyHistoryLimit;

  /// No description provided for @historyHistoryLimitBody.
  ///
  /// In en, this message translates to:
  /// **'Enabling history limit means all history entries beyond {count} and all entries older than {months} months are automatically deleted.'**
  String historyHistoryLimitBody(Object count, Object months);

  /// No description provided for @historyLimitHistory.
  ///
  /// In en, this message translates to:
  /// **'Limit history'**
  String get historyLimitHistory;

  /// No description provided for @historyLimitedTo.
  ///
  /// In en, this message translates to:
  /// **'Limited to newer than {months} months or less than {count} entries.'**
  String historyLimitedTo(Object months, Object count);

  /// No description provided for @historyInfinite.
  ///
  /// In en, this message translates to:
  /// **'history is infinite'**
  String get historyInfinite;

  /// No description provided for @historyEntries.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get historyEntries;

  /// No description provided for @historyYourHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your history is empty'**
  String get historyYourHistoryEmpty;

  /// No description provided for @historyFailedLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load history'**
  String get historyFailedLoad;

  /// No description provided for @logsLogsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} logs'**
  String logsLogsCount(Object count);

  /// No description provided for @logsLogFilesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} log files'**
  String logsLogFilesCount(Object count);

  /// No description provided for @logsLogsDate.
  ///
  /// In en, this message translates to:
  /// **'Logs - {date}'**
  String logsLogsDate(Object date);

  /// No description provided for @logsDeleteFilesTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} log files?'**
  String logsDeleteFilesTitle(Object count);

  /// No description provided for @logsCannotUndone.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get logsCannotUndone;

  /// No description provided for @logsLogs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get logsLogs;

  /// No description provided for @logsLevels.
  ///
  /// In en, this message translates to:
  /// **'Levels'**
  String get logsLevels;

  /// No description provided for @logsCriticalError.
  ///
  /// In en, this message translates to:
  /// **'A critical error has occurred!'**
  String get logsCriticalError;

  /// No description provided for @logsLogFiles.
  ///
  /// In en, this message translates to:
  /// **'Log Files'**
  String get logsLogFiles;

  /// No description provided for @logsFailedLoadFiles.
  ///
  /// In en, this message translates to:
  /// **'Failed to load log files!'**
  String get logsFailedLoadFiles;

  /// No description provided for @logsNoLogFiles.
  ///
  /// In en, this message translates to:
  /// **'No log files available!'**
  String get logsNoLogFiles;

  /// No description provided for @logsLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get logsLive;

  /// No description provided for @logsNoLogItems.
  ///
  /// In en, this message translates to:
  /// **'No log items!'**
  String get logsNoLogItems;

  /// No description provided for @markupSection.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get markupSection;

  /// No description provided for @markupQuote.
  ///
  /// In en, this message translates to:
  /// **'Quote'**
  String get markupQuote;

  /// No description provided for @markupCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get markupCode;

  /// No description provided for @markupSpoiler.
  ///
  /// In en, this message translates to:
  /// **'Spoiler'**
  String get markupSpoiler;

  /// No description provided for @markupBold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get markupBold;

  /// No description provided for @markupItalic.
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get markupItalic;

  /// No description provided for @markupUnderlined.
  ///
  /// In en, this message translates to:
  /// **'Underlined'**
  String get markupUnderlined;

  /// No description provided for @markupStrikethrough.
  ///
  /// In en, this message translates to:
  /// **'Strikethrough'**
  String get markupStrikethrough;

  /// No description provided for @traitsBlacklist.
  ///
  /// In en, this message translates to:
  /// **'Blacklist'**
  String get traitsBlacklist;

  /// No description provided for @traitsBlockedPosts.
  ///
  /// In en, this message translates to:
  /// **'blocked {count} posts'**
  String traitsBlockedPosts(Object count);

  /// No description provided for @traitsFailedUpdate.
  ///
  /// In en, this message translates to:
  /// **'Failed to update blacklist!'**
  String get traitsFailedUpdate;

  /// No description provided for @traitsOneTagPerLine.
  ///
  /// In en, this message translates to:
  /// **'One tag per line'**
  String get traitsOneTagPerLine;

  /// No description provided for @traitsAddTag.
  ///
  /// In en, this message translates to:
  /// **'Add tag'**
  String get traitsAddTag;

  /// No description provided for @traitsBlacklistEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your blacklist is empty'**
  String get traitsBlacklistEmpty;

  /// No description provided for @traitsEditTag.
  ///
  /// In en, this message translates to:
  /// **'Edit tag'**
  String get traitsEditTag;

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

  /// No description provided for @tagPreviewLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Error loading tag preview: {error}'**
  String tagPreviewLoadFailed(Object error);
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
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
