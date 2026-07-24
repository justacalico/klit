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
  String get settingsLanguageSimplifiedChinese => 'Simplified Chinese';

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
  String get aboutSourceLocal => 'Local build';

  @override
  String get aboutSourceOther => 'Other source';

  @override
  String get aboutSourceStore => 'Store install';

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
  String get commonAdd => 'Add';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonReset => 'Reset';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonSend => 'Send';

  @override
  String get commonShare => 'Share';

  @override
  String get commonBrowse => 'Browse';

  @override
  String get commonReport => 'Report';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonDone => 'Done';

  @override
  String get commonCancelTask => 'Cancelled task';

  @override
  String get commonCopiedToClipboard => 'Copied to clipboard';

  @override
  String get commonTryAgain => 'Try again';

  @override
  String get commonNothingHere => 'Nothing to see here';

  @override
  String get commonFailedLoad => 'Failed to load';

  @override
  String get commonFailedLoadSuggestions => 'Failed to load suggestions';

  @override
  String get commonSaveFile => 'Save file';

  @override
  String commonFileSavedAs(Object name) {
    return 'File saved as $name';
  }

  @override
  String commonItemProgress(Object current, Object total) {
    return 'Item $current/$total';
  }

  @override
  String commonFailedItemAt(Object index) {
    return 'Failed at Item $index';
  }

  @override
  String commonItemsCount(Object count) {
    return '$count items';
  }

  @override
  String get commonSelectAll => 'Select all';

  @override
  String get commonAbort => 'Abort';

  @override
  String get commonPrevious => 'Previous';

  @override
  String get commonNext => 'Next';

  @override
  String get commonInfo => 'Info';

  @override
  String get commonToday => 'Today';

  @override
  String get commonYesterday => 'Yesterday';

  @override
  String get commonWrite => 'Write';

  @override
  String get commonPreview => 'Preview';

  @override
  String get commonTypeHere => 'type here...';

  @override
  String get commonYourTextHere => 'your text here';

  @override
  String get commonMore => 'More';

  @override
  String get commonExpandSidebar => 'Expand sidebar';

  @override
  String get commonShrinkSidebar => 'Shrink sidebar';

  @override
  String get commonActive => 'Active';

  @override
  String get commonInactive => 'inactive';

  @override
  String get commonYes => 'yes';

  @override
  String get commonNo => 'no';

  @override
  String get commonCreated => 'created';

  @override
  String get commonUpdated => 'updated';

  @override
  String get commonId => 'id';

  @override
  String get commonPosts => 'posts';

  @override
  String get commonDescription => 'Description';

  @override
  String get commonName => 'Name';

  @override
  String get commonType => 'Type';

  @override
  String get commonTags => 'Tags';

  @override
  String get commonScore => 'Score';

  @override
  String get commonRating => 'Rating';

  @override
  String get commonRatingAll => 'All';

  @override
  String get commonRatingSafe => 'Safe';

  @override
  String get commonRatingQuestionable => 'Questionable';

  @override
  String get commonRatingExplicit => 'Explicit';

  @override
  String get commonRatingQ => 'Q';

  @override
  String get commonRatingE => 'E';

  @override
  String get commonSort => 'Sort';

  @override
  String get commonSortBy => 'Sort by';

  @override
  String get commonSortDefault => 'Default';

  @override
  String get commonSortScore => 'Score';

  @override
  String get commonSortFavorites => 'Favorites';

  @override
  String get commonSortRank => 'Rank';

  @override
  String get commonSortRandom => 'Random';

  @override
  String get commonSortName => 'Name';

  @override
  String get commonSortCreated => 'Created';

  @override
  String get commonSortUpdated => 'Updated';

  @override
  String get commonSortPostCount => 'Post count';

  @override
  String get commonSortNewestFirst => 'Newest first';

  @override
  String get commonSortOldestFirst => 'Oldest first';

  @override
  String get commonSortFavCount => 'Fav count';

  @override
  String get commonEnabled => 'Enabled';

  @override
  String get commonDisabled => 'Disabled';

  @override
  String get commonShow => 'Show';

  @override
  String get commonHide => 'Hide';

  @override
  String get commonCamera => 'Camera';

  @override
  String get commonGallery => 'Gallery';

  @override
  String get commonSkip => 'Skip';

  @override
  String get commonBlock => 'Block';

  @override
  String get commonUnblock => 'Unblock';

  @override
  String get commonFollow => 'Follow';

  @override
  String get commonUnfollow => 'Unfollow';

  @override
  String get commonMute => 'Mute';

  @override
  String get commonNotify => 'Notify';

  @override
  String get commonBookmark => 'Bookmark';

  @override
  String get commonUnbookmark => 'Unbookmark';

  @override
  String get commonSubtract => 'Subtract';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonResolve => 'Resolve';

  @override
  String get commonAbout => 'About';

  @override
  String get commonUploads => 'Uploads';

  @override
  String get commonFavorites => 'Favorites';

  @override
  String get commonMain => 'Main';

  @override
  String get commonNoDescription => 'no description';

  @override
  String get commonNoTags => 'No tags';

  @override
  String get commonNoSources => 'no sources';

  @override
  String get commonNoArtist => 'no artist';

  @override
  String get commonAnonymous => 'Anonymous';

  @override
  String get commonLogin => 'Login';

  @override
  String get commonAuthentication => 'Authentication';

  @override
  String get commonHost => 'Host';

  @override
  String get commonUsername => 'Username';

  @override
  String get commonApiKey => 'API key';

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
  String get feedsUnnamed => 'Unnamed feed';

  @override
  String get feedsNameHint => 'e.g. My art feed';

  @override
  String get feedsIncludeTags => 'Include tags';

  @override
  String get feedsIncludeTagsHint => 'space separated, all required';

  @override
  String get feedsOrTags => 'Or tags';

  @override
  String get feedsOrTagsHint => 'any of these';

  @override
  String get feedsExcludeTags => 'Exclude tags';

  @override
  String get feedsExcludeTagsHint => 'posts with these are hidden';

  @override
  String get feedsSubfeeds => 'Subfeeds';

  @override
  String get feedsSubfeedsHelper =>
      'Optional filters; only one can be active at a time when viewing the feed.';

  @override
  String get feedsAddSubfeed => 'Add subfeed';

  @override
  String get feedsSubfeedName => 'Subfeed name';

  @override
  String get feedsExtraIncludeTags => 'Extra include tags';

  @override
  String get feedsExtraIncludeTagsLabel => 'Additional tags (all required)';

  @override
  String get feedsExtraExcludeTags => 'Extra exclude tags';

  @override
  String get feedsExtraExcludeTagsLabel => 'Tags to exclude in this subfeed';

  @override
  String get feedsExcludeFavorited => 'Exclude favorited';

  @override
  String get feedsExcludeFavoritedHelper =>
      'Don\'t show posts you\'ve favorited in this feed';

  @override
  String get feedImage => 'Image';

  @override
  String get feedVideo => 'Video';

  @override
  String get feedImageAndVideo => 'Image & video';

  @override
  String get feedNoTags => 'no tags';

  @override
  String feedSubDefault(Object index) {
    return 'Sub $index';
  }

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
  String get databaseErrorLoading => 'Error loading database';

  @override
  String get databaseBackupFileName => 'klit_database_backup.db';

  @override
  String postUpdateSuccess(Object id) {
    return 'Updated post #$id';
  }

  @override
  String postUpdateFailed(Object id) {
    return 'Failed to update post #$id';
  }

  @override
  String get postBlacklisted => 'Blacklisted';

  @override
  String get postComments => 'Comments';

  @override
  String postCommentsWithCount(Object count) {
    return 'Comments ($count)';
  }

  @override
  String get postDeletion => 'Deletion';

  @override
  String get postFile => 'File';

  @override
  String get postPools => 'Pools';

  @override
  String get postParent => 'Parent';

  @override
  String get postChildren => 'Children';

  @override
  String get postSources => 'Sources';

  @override
  String get postScore => 'Score';

  @override
  String get postFavorites => 'Favorites';

  @override
  String postCopiedId(Object id) {
    return 'Copied post id #$id';
  }

  @override
  String postFailedUpvote(Object id) {
    return 'Failed to upvote Post #$id';
  }

  @override
  String postFailedDownvote(Object id) {
    return 'Failed to downvote Post #$id';
  }

  @override
  String postFailedVote(Object action, Object id) {
    return 'Failed to $action Post #$id';
  }

  @override
  String get postTakePhoto => 'Take a photo?';

  @override
  String get postStatusDeleted => 'deleted';

  @override
  String get postStatusUnsupported => 'unsupported';

  @override
  String get postStatusUnavailable => 'unavailable';

  @override
  String get postStatusBlacklisted => 'blacklisted';

  @override
  String get postDownload => 'Download';

  @override
  String postDownloadedOne(Object id) {
    return 'Downloaded post #$id';
  }

  @override
  String postDownloadedMany(Object count) {
    return 'Downloaded $count posts';
  }

  @override
  String postDownloadingOne(Object id) {
    return 'Downloading post #$id';
  }

  @override
  String postDownloadingProgress(Object id, Object current, Object total) {
    return 'Downloading post #$id ($current/$total)';
  }

  @override
  String postDownloadFailed(Object id) {
    return 'Failed to download post #$id';
  }

  @override
  String get postDownloadCancelled => 'Cancelled download';

  @override
  String postFavoritedOne(Object id) {
    return 'Favorited post #$id';
  }

  @override
  String postFavoritedMany(Object count) {
    return 'Favorited $count posts';
  }

  @override
  String postUnfavoritedOne(Object id) {
    return 'Unfavorited post #$id';
  }

  @override
  String postUnfavoritedMany(Object count) {
    return 'Unfavorited $count posts';
  }

  @override
  String postFavoritingOne(Object id) {
    return 'Favoriting post #$id';
  }

  @override
  String postFavoritingProgress(Object id, Object current, Object total) {
    return 'Favoriting post #$id ($current/$total)';
  }

  @override
  String postUnfavoritingOne(Object id) {
    return 'Unfavoriting post #$id';
  }

  @override
  String postUnfavoritingProgress(Object id, Object current, Object total) {
    return 'Unfavoriting post #$id ($current/$total)';
  }

  @override
  String postFavoriteFailed(Object id) {
    return 'Failed to favorite post #$id';
  }

  @override
  String postUnfavoriteFailed(Object id) {
    return 'Failed to unfavorite post #$id';
  }

  @override
  String get postFavoritingCancelled => 'Cancelled favoriting';

  @override
  String get postUnfavoritingCancelled => 'Cancelled unfavoriting';

  @override
  String postSelectionOne(Object id) {
    return 'post #$id';
  }

  @override
  String postSelectionMany(Object count) {
    return '$count posts';
  }

  @override
  String get postFilterFavoriteCount => 'Favorite count';

  @override
  String get postFilterPool => 'Pool';

  @override
  String get postFilterHasPool => 'Has pool';

  @override
  String get postFilterChild => 'Child';

  @override
  String get postFilterIsChild => 'Is child post';

  @override
  String get postFilterIsParent => 'Is parent post';

  @override
  String get postFilterUploadDate => 'Upload date';

  @override
  String get postFilterDateAll => 'All';

  @override
  String get postFilterDateLastDay => 'Last day';

  @override
  String get postFilterDateLastWeek => 'Last week';

  @override
  String get postFilterDateLastMonth => 'Last Month';

  @override
  String get postFilterDateLastYear => 'Last Year';

  @override
  String get postFilterStatus => 'Status';

  @override
  String get postFilterStatusActive => 'Active';

  @override
  String get postFilterStatusPending => 'Pending';

  @override
  String get postFilterStatusDeleted => 'Deleted';

  @override
  String get postFilterStatusFlagged => 'Flagged';

  @override
  String get postFilterStatusAny => 'Any';

  @override
  String get postSearch => 'Search';

  @override
  String get postSearchTags => 'Search tags';

  @override
  String get postHome => 'Home';

  @override
  String get postPopular => 'Popular';

  @override
  String get postPosts => 'Posts';

  @override
  String get postFavsUnavailable =>
      'Favorites are unavailable for anonymous users';

  @override
  String get postFavOrder => 'Favorite order';

  @override
  String get postFavOrderAdded => 'added order';

  @override
  String get postFavOrderId => 'id order';

  @override
  String get postDay => 'Day';

  @override
  String get postWeek => 'Week';

  @override
  String get postMonth => 'Month';

  @override
  String get postHot => 'Hot';

  @override
  String get postPickDate => 'Pick date';

  @override
  String get postEditReasonOptional => 'Edit reason (optional)';

  @override
  String get postEditReasonHint => 'Why are you editing this post?';

  @override
  String postEditDescriptionTitle(Object id) {
    return '#$id description';
  }

  @override
  String get postEditDescriptionHint => 'Enter post description...';

  @override
  String get postEditNoDescription => 'No description';

  @override
  String get postEditParentIdOptional => 'Parent ID (optional)';

  @override
  String get postEditParentIdHint => 'Parent post ID';

  @override
  String get postEditInvalidNumber => 'Invalid number format';

  @override
  String get postEditInvalidParent => 'Invalid parent post';

  @override
  String postEditSourcesTitle(Object id) {
    return '#$id sources';
  }

  @override
  String get postEditNoSources => 'No sources';

  @override
  String get postEditSpaceSeparated => 'space separated tags';

  @override
  String get postEditTagNew => 'new';

  @override
  String get postEditTagInvalid => 'invalid';

  @override
  String get postEditTagEmpty => 'empty';

  @override
  String get postEditTagUnderused => 'underused';

  @override
  String postFlaggedSuccess(Object id) {
    return 'Flagged post #$id';
  }

  @override
  String postFlagFailed(Object id) {
    return 'Failed to flag post #$id';
  }

  @override
  String postFlagTitle(Object id) {
    return 'Post #$id';
  }

  @override
  String get postFlag => 'Flag';

  @override
  String get postFlagParentId => 'Parent ID';

  @override
  String get postFlagParentIdEmpty => 'Parent ID cannot be empty';

  @override
  String get postFlagParentIdNumber => 'Parent ID must be a number';

  @override
  String get settingsFailedLoadAccounts => 'Failed to load accounts';

  @override
  String get settingsTryReopen => 'Try reopening Settings.';

  @override
  String get settingsLoadingAccounts => 'Loading accounts...';

  @override
  String get settingsSwitchingAccount => 'Switching account...';

  @override
  String settingsFailedConnect(Object host) {
    return 'Failed to connect to $host';
  }

  @override
  String settingsConnectedTo(Object host) {
    return 'Connected to $host';
  }

  @override
  String get settingsDeleteAccountTitle => 'Delete account?';

  @override
  String get settingsDeleteAccountBody =>
      'All local data will be removed, including follows and history.';

  @override
  String get settingsDeleteUpper => 'DELETE';

  @override
  String settingsActiveAccount(Object host) {
    return 'Active account • $host';
  }

  @override
  String get settingsActive => 'Active';

  @override
  String get settingsAddAccount => 'Add account';

  @override
  String get settingsActivate => 'Activate';

  @override
  String get settingsTest => 'Test';

  @override
  String get settingsBlacklist => 'Blacklist';

  @override
  String settingsTagsBlocked(Object count) {
    return '$count tags blocked';
  }

  @override
  String get settingsFollows => 'Follows';

  @override
  String settingsSearchesFollowed(Object count) {
    return '$count searches followed';
  }

  @override
  String get settingsHistory => 'History';

  @override
  String settingsPagesVisited(Object count) {
    return '$count pages visited';
  }

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsAccentColor => 'Accent color';

  @override
  String get settingsTileSize => 'Tile size';

  @override
  String settingsTileSizeValue(Object value) {
    return '$value px';
  }

  @override
  String get settingsQuilt => 'Quilt';

  @override
  String get settingsGrid => 'Grid';

  @override
  String get settingsQuiltQuadratic => 'tiles are quadratic';

  @override
  String get settingsQuiltExpand => 'tiles expand vertically';

  @override
  String get settingsPostInfo => 'Post info';

  @override
  String get settingsPostInfoOnTiles => 'Info on post tiles';

  @override
  String get settingsPostInfoImageOnly => 'Image tiles only';

  @override
  String get settingsPostActionBar => 'Post action bar';

  @override
  String settingsActionsPinned(Object count) {
    return '$count actions pinned';
  }

  @override
  String get settingsActionBarPlacement => 'Action bar placement';

  @override
  String get settingsPlacementFloating => 'Mobile: floating above navbar';

  @override
  String get settingsPlacementInline => 'Mobile: inline on post page';

  @override
  String get settingsDownloadLocation => 'Download location';

  @override
  String get settingsChooseDirectory => 'Choose directory';

  @override
  String get settingsUpvoteFavorites => 'Upvote favorites';

  @override
  String get settingsUpvoteAndFav => 'Upvote and favorite';

  @override
  String get settingsFavOnly => 'Favorite only';

  @override
  String get settingsVideoVolume => 'Video volume';

  @override
  String get settingsMuted => 'Muted';

  @override
  String get settingsWithSound => 'With sound';

  @override
  String get settingsAutoplayVideos => 'Autoplay videos';

  @override
  String get settingsPlayAutomatically => 'Play automatically';

  @override
  String get settingsPlayOnTap => 'Play on tap';

  @override
  String get settingsVideoResolution => 'Video resolution';

  @override
  String get settingsIFinished => 'I Finished';

  @override
  String get settingsIFinishedDesc => 'Button on post detail to mark finished';

  @override
  String get settingsIFinishedOff => 'Off';

  @override
  String get settingsRequestPhoto => 'Request image on completion';

  @override
  String get settingsRequestPhotoDesc =>
      'Ask for a photo when marking I Finished';

  @override
  String get settingsRequestPhotoOff => 'No photo';

  @override
  String get settingsSecureDisplay => 'Secure display';

  @override
  String get settingsScreenProtected => 'Screen protected';

  @override
  String get settingsScreenVisible => 'Screen visible';

  @override
  String get settingsIncognitoKeyboard => 'Incognito keyboard';

  @override
  String get settingsAllowHttpHosts => 'Allow HTTP hosts';

  @override
  String get settingsAllowHttpDesc =>
      'http:// for local or self-hosted (unencrypted)';

  @override
  String get settingsHttpsOnly => 'https:// only';

  @override
  String get settingsPinLock => 'PIN lock';

  @override
  String get settingsPinEnabled => 'PIN enabled';

  @override
  String get settingsPinDisabled => 'PIN disabled';

  @override
  String get settingsBiometricLock => 'Biometric lock';

  @override
  String get settingsBiometricsEnabled => 'Biometrics enabled';

  @override
  String get settingsBiometricsDisabled => 'Biometrics disabled';

  @override
  String get settingsDeveloperMode => 'Developer mode';

  @override
  String get settingsOptionsShown => 'Options shown';

  @override
  String get settingsLogs => 'Logs';

  @override
  String settingsErrorsLogged(Object count) {
    return '$count errors logged';
  }

  @override
  String get settingsDatabase => 'Database';

  @override
  String get settingsPinnedActions =>
      'Pinned actions are shown first on post detail. Drag to reorder.';

  @override
  String get settingsAvailable => 'Available';

  @override
  String get settingsNotOnList => 'Not on the list? contact us!';

  @override
  String get identityEditAccount => 'Edit account';

  @override
  String get identityAddAccount => 'Add account';

  @override
  String get identityNoAccountSignUp => 'Don\'t have an account? Sign up here';

  @override
  String get identityWhereApiKey => 'Where do I find my API key?';

  @override
  String identityConnectingTo(Object host, Object user) {
    return 'Connecting to $host as $user...';
  }

  @override
  String get identityHostRequired => 'You must provide a host URL.';

  @override
  String get identityHostInvalid => 'Invalid host URL';

  @override
  String get identityUsernameRequired => 'You must provide a username.';

  @override
  String identityApiKeyRequired(Object example) {
    return 'You must provide an API key.\ne.g. $example';
  }

  @override
  String identityApiKeyInvalid(Object example) {
    return 'API key is 16–80 characters (letters, digits, optional underscore)\ne.g. $example';
  }

  @override
  String get identityCheckNetwork =>
      'Check your network connection and login details';

  @override
  String identityFailedLogin(Object value) {
    return 'Failed to login.\n$value';
  }

  @override
  String get identityDuplicate =>
      'You already have an identity under this host and username.';

  @override
  String get identityHostUnavailable => 'Host unavailable';

  @override
  String identityHostUnavailableBody(Object host) {
    return 'It appears that $host is not available!';
  }

  @override
  String get identityResolveBody =>
      'Please resolve the issue in the following browser window. \n\nCloudflare captcha cookies will be saved. ';

  @override
  String identityWaitForHost(Object host) {
    return '\nPlease wait for $host to resolve the situation on their end.';
  }

  @override
  String get identityDesktopLogin =>
      'On desktop, log in using your browser and add an API key in Settings.';

  @override
  String get identityOpenLoginBrowser => 'Open login in browser';

  @override
  String get identityMustBeLoggedIn =>
      'You must be logged in to perform this action.';

  @override
  String get identityChooseIdentity => 'Choose identity';

  @override
  String identityApiKeyExample(Object example) {
    return 'e.g. $example';
  }

  @override
  String get appEnterPin => 'Enter PIN';

  @override
  String get appEnterNewPin => 'Enter new PIN';

  @override
  String get appConfirmNewPin => 'Confirm new PIN';

  @override
  String get appFailedAuthenticate => 'Failed to authenticate';

  @override
  String get appPleaseAuthenticate => 'Please authenticate';

  @override
  String get appAuthenticateToUnlock => 'Authenticate to unlock.';

  @override
  String get appBiometricFailure =>
      'Severe failure in biometric authentication';

  @override
  String get appFailedInitialize => 'Failed to initialize';

  @override
  String get commentSent => 'Comment sent!';

  @override
  String get commentLogInToAdd => 'Log in to add a comment';

  @override
  String get commentAddComment => 'Add comment';

  @override
  String get commentNoComments => 'No comments';

  @override
  String get commentFailedLoad => 'Failed to load comments';

  @override
  String commentPostComments(Object id) {
    return '#$id comments';
  }

  @override
  String commentFailedUpvote(Object id) {
    return 'Failed to upvote comment #$id';
  }

  @override
  String commentFailedDownvote(Object id) {
    return 'Failed to downvote comment #$id';
  }

  @override
  String get commentHidden => 'This comment is hidden';

  @override
  String get commentMustLoginEdit => 'You must be logged in to edit comments!';

  @override
  String get commentMustLoginReply =>
      'You must be logged in to reply to comments!';

  @override
  String get commentMustLoginReport =>
      'You must be logged in to report comments!';

  @override
  String commentCopiedId(Object id) {
    return 'Copied comment id #$id';
  }

  @override
  String get commentReply => 'Reply';

  @override
  String get commentCopyId => 'Copy ID';

  @override
  String get commentCommentOrder => 'Comment order';

  @override
  String get commentOldestFirst => 'oldest first';

  @override
  String get commentNewestFirst => 'newest first';

  @override
  String commentCommentTitle(Object id) {
    return 'Comment #$id';
  }

  @override
  String get commentFailedLoadOne => 'Failed to load comment';

  @override
  String get commentNotFound => 'Comment not found';

  @override
  String commentDialogTitle(Object id) {
    return '#$id comment';
  }

  @override
  String get commentRefresh => 'Refresh';

  @override
  String get topicHideTagsEdits => 'hide tags edits';

  @override
  String get topicHideTagsAliasShow => 'show tag alias and implications';

  @override
  String get topicHideTagsAliasHide => 'hide tag alias and implications';

  @override
  String get topicNoTopics => 'No topics';

  @override
  String get topicFailedLoad => 'Failed to load topics';

  @override
  String get topicReplies => 'replies';

  @override
  String get topicLocked => 'locked';

  @override
  String get topicCreated => 'created';

  @override
  String get topicUpdated => 'updated';

  @override
  String topicCopiedId(Object id) {
    return 'Copied topic id #$id';
  }

  @override
  String topicTitle(Object id) {
    return 'Topic #$id';
  }

  @override
  String get topicFailedLoadOne => 'Failed to load topic';

  @override
  String get topicNotFound => 'Topic not found';

  @override
  String get topicTopics => 'Topics';

  @override
  String get replyReplies => 'Replies';

  @override
  String get replyOrder => 'Reply order';

  @override
  String get replyNoReplies => 'No replies';

  @override
  String get replyFailedLoad => 'Failed to load replies';

  @override
  String get replyHidden => 'This reply is hidden';

  @override
  String replyTitle(Object id) {
    return 'Reply #$id';
  }

  @override
  String get replyFailedLoadOne => 'Failed to load reply';

  @override
  String get replyNotFound => 'Reply not found';

  @override
  String followFollowsCount(Object count) {
    return '$count follows';
  }

  @override
  String get followDisableNotifications => 'Disable notifications';

  @override
  String get followEnableNotifications => 'Enable notifications';

  @override
  String get followSubscribe => 'Subscribe';

  @override
  String get followBookmark => 'Bookmark';

  @override
  String followMarkSeen(Object count) {
    return 'mark $count posts as seen';
  }

  @override
  String get followNoUnseen => 'no unseen posts';

  @override
  String get followBookmarks => 'Bookmarks';

  @override
  String get followAddToBookmarks => 'Add to bookmarks';

  @override
  String get followNoBookmarks => 'No bookmarks';

  @override
  String get followFailedLoadBookmarks => 'Failed to load bookmarks';

  @override
  String get followUnseenPosts => 'unseen posts';

  @override
  String get followShowUnseenFirst => 'show unseen first';

  @override
  String get followFilteringUnseen => 'filtering for unseen';

  @override
  String get followAllPostsShown => 'all posts shown';

  @override
  String get followEditFollows => 'Edit follows';

  @override
  String get followForceSync => 'Force sync';

  @override
  String get followSyncAll => 'sync all follows';

  @override
  String get followSyncing => 'syncing follows...';

  @override
  String get followEditFollow => 'Edit follow';

  @override
  String get followMarkAsRead => 'Mark as read';

  @override
  String get followRename => 'Rename';

  @override
  String get followFollowTitle => 'Follow title';

  @override
  String get followNewPost => 'new post';

  @override
  String get followNewPosts => 'new posts';

  @override
  String followAlias(Object name) {
    return 'alias $name';
  }

  @override
  String get followNewPostsNotif => 'New posts!';

  @override
  String get poolPosts => 'posts';

  @override
  String poolCopiedId(Object id) {
    return 'Copied pool id #$id';
  }

  @override
  String get poolActivity => 'activity';

  @override
  String get poolPoolOrder => 'Pool order';

  @override
  String get poolReaderMode => 'Pool reader mode';

  @override
  String get poolLargeImages => 'large images';

  @override
  String get poolNormalGrid => 'normal grid';

  @override
  String get poolNoPools => 'No pools';

  @override
  String get poolFailedLoad => 'Failed to load pools';

  @override
  String poolPoolTitle(Object id) {
    return 'Pool #$id';
  }

  @override
  String get poolFailedLoadOne => 'Failed to load pool';

  @override
  String get poolNotFound => 'Pool not found';

  @override
  String get poolPools => 'Pools';

  @override
  String get poolCreator => 'Creator';

  @override
  String get poolIsActive => 'Is active';

  @override
  String get poolCategory => 'Category';

  @override
  String get poolCategorySeries => 'Series';

  @override
  String get poolCategoryCollection => 'Collection';

  @override
  String get poolPoolTitleField => 'Pool title';

  @override
  String wikiCopiedId(Object id) {
    return 'Copied wiki id #$id';
  }

  @override
  String get wikiAlias => 'alias';

  @override
  String wikiWikiTitle(Object id) {
    return 'Wiki #$id';
  }

  @override
  String get wikiFailedLoadOne => 'Failed to load wiki';

  @override
  String get wikiNotFound => 'Wiki not found';

  @override
  String get wikiUnableRetrieve => 'unable to retrieve wiki entry';

  @override
  String get wikiNoWikiEntry => 'no wiki entry';

  @override
  String get wikiFailedLoadTags => 'failed to load tags';

  @override
  String get userProfileUnavailable =>
      'Profile is not available for anonymous users';

  @override
  String get userFailedLoadProfile => 'Failed to load profile';

  @override
  String get userNotFound => 'User not found';

  @override
  String get userMustLoginReport => 'You must be logged in to report users!';

  @override
  String userCopiedId(Object id) {
    return 'Copied user id #$id';
  }

  @override
  String get userCommission => 'Commission';

  @override
  String get userJoined => 'joined';

  @override
  String get userRank => 'rank';

  @override
  String get userEdits => 'edits';

  @override
  String get userComments => 'comments';

  @override
  String get userForum => 'forum';

  @override
  String get historyHistory => 'History';

  @override
  String historyEntriesCount(Object count) {
    return '$count entries';
  }

  @override
  String get historyEnabled => 'Enabled';

  @override
  String historyPagesVisited(Object count) {
    return '$count pages visited';
  }

  @override
  String get historyClearHistory => 'Clear history';

  @override
  String get historyDeleteAllEntries => 'Delete all entries';

  @override
  String get historyClearHistoryTitle => 'Clear history?';

  @override
  String get historyClearHistoryBody =>
      'All history entries will be permanently deleted. This action cannot be undone.';

  @override
  String get historyHistoryLimit => 'History limit';

  @override
  String historyHistoryLimitBody(Object count, Object months) {
    return 'Enabling history limit means all history entries beyond $count and all entries older than $months months are automatically deleted.';
  }

  @override
  String get historyLimitHistory => 'Limit history';

  @override
  String historyLimitedTo(Object months, Object count) {
    return 'Limited to newer than $months months or less than $count entries.';
  }

  @override
  String get historyInfinite => 'history is infinite';

  @override
  String get historyEntries => 'Entries';

  @override
  String get historyYourHistoryEmpty => 'Your history is empty';

  @override
  String get historyFailedLoad => 'Failed to load history';

  @override
  String logsLogsCount(Object count) {
    return '$count logs';
  }

  @override
  String logsLogFilesCount(Object count) {
    return '$count log files';
  }

  @override
  String logsLogsDate(Object date) {
    return 'Logs - $date';
  }

  @override
  String logsDeleteFilesTitle(Object count) {
    return 'Delete $count log files?';
  }

  @override
  String get logsCannotUndone => 'This action cannot be undone.';

  @override
  String get logsLogs => 'Logs';

  @override
  String get logsLevels => 'Levels';

  @override
  String get logsCriticalError => 'A critical error has occurred!';

  @override
  String get logsLogFiles => 'Log Files';

  @override
  String get logsFailedLoadFiles => 'Failed to load log files!';

  @override
  String get logsNoLogFiles => 'No log files available!';

  @override
  String get logsLive => 'Live';

  @override
  String get logsNoLogItems => 'No log items!';

  @override
  String get markupSection => 'Section';

  @override
  String get markupQuote => 'Quote';

  @override
  String get markupCode => 'Code';

  @override
  String get markupSpoiler => 'Spoiler';

  @override
  String get markupBold => 'Bold';

  @override
  String get markupItalic => 'Italic';

  @override
  String get markupUnderlined => 'Underlined';

  @override
  String get markupStrikethrough => 'Strikethrough';

  @override
  String get traitsBlacklist => 'Blacklist';

  @override
  String traitsBlockedPosts(Object count) {
    return 'blocked $count posts';
  }

  @override
  String get traitsFailedUpdate => 'Failed to update blacklist!';

  @override
  String get traitsOneTagPerLine => 'One tag per line';

  @override
  String get traitsAddTag => 'Add tag';

  @override
  String get traitsBlacklistEmpty => 'Your blacklist is empty';

  @override
  String get traitsEditTag => 'Edit tag';

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

  @override
  String tagPreviewLoadFailed(Object error) {
    return 'Error loading tag preview: $error';
  }
}
