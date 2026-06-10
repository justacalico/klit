import 'package:kilt/app/app.dart';
import 'package:kilt/settings/data/post_actions.dart';
import 'package:kilt/shared/shared.dart';
import 'package:flutter/foundation.dart';
import 'package:notified_preferences/notified_preferences.dart';

class Settings extends NotifiedSettings {
  Settings(super.preferences);

  static Future<Settings> getInstance() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('theme');
    if (theme == 'blue' || theme == 'dynamic') {
      await prefs.setString('theme', 'dark');
    }
    final existingPostActions = prefs.getString(
      PostActionPreferences.settingKey,
    );
    if (existingPostActions == null) {
      final showShare =
          prefs.getBool(PostActionPreferences.legacyShareButtonKey) ?? true;
      final defaults = <PostActionId>[
        ...PostActionPreferences.defaultActions,
        if (showShare) PostActionId.share,
      ];
      await prefs.setString(
        PostActionPreferences.settingKey,
        PostActionPreferences.encode(defaults),
      );
    }
    await prefs.remove(PostActionPreferences.legacyShareButtonKey);
    return Settings(prefs);
  }

  late final ValueNotifier<int> identity = createSetting(
    key: 'identity',
    initialValue: 1,
  );

  late final ValueNotifier<AppTheme> theme = createEnumSetting(
    key: 'theme',
    initialValue: AppTheme.values.first,
    values: AppTheme.values,
  );

  /// `null` means "system default". Otherwise a BCP-47-ish tag like `en` or `en-AU`.
  late final ValueNotifier<String?> localeTag = createSetting<String?>(
    key: 'localeTag',
    initialValue: null,
  );
  late final ValueNotifier<String> accentColorHex = createSetting<String>(
    key: 'accentColorHex',
    initialValue: defaultAccentColorHex,
  );

  late final ValueNotifier<int> tileSize = createSetting(
    key: 'tileSize',
    initialValue: 200,
  );
  late final ValueNotifier<GridQuilt> quilt = createEnumSetting(
    key: 'quilt',
    initialValue: GridQuilt.square,
    values: GridQuilt.values,
  );

  late final ValueNotifier<bool> filterUnseenFollows = createSetting(
    key: 'filterUnseenFollows',
    initialValue: false,
  );
  late final ValueNotifier<bool> showPostInfo = createSetting<bool>(
    key: 'showPostInfo',
    initialValue: true,
  );
  late final ValueNotifier<String> postActionBarActions = createSetting<String>(
    key: PostActionPreferences.settingKey,
    initialValue: PostActionPreferences.encode(
      PostActionPreferences.defaultActions,
    ),
  );
  late final ValueNotifier<bool> postActionBarFloatingMobile = createSetting(
    key: 'postActionBarFloatingMobile',
    initialValue: false,
  );
  late final ValueNotifier<bool> upvoteFavs = createSetting<bool>(
    key: 'upvoteFavs',
    initialValue: true,
  );
  late final ValueNotifier<String?> downloadPath = createSetting<String?>(
    key: 'downloadPath',
    initialValue: null,
  );
  late final ValueNotifier<bool> muteVideos = createSetting<bool>(
    key: 'muteVideos',
    initialValue: true,
  );
  late final ValueNotifier<bool> autoplayVideos = createSetting<bool>(
    key: 'autoplayVideos',
    initialValue: true,
  );
  late final ValueNotifier<VideoResolution> videoResolution = createEnumSetting(
    key: 'videoResolution',
    initialValue: VideoResolution.source,
    values: VideoResolution.values,
  );

  late final ValueNotifier<bool> secureDisplay = createSetting<bool>(
    key: 'secureDisplay',
    initialValue: false,
  );
  late final ValueNotifier<bool> incognitoKeyboard = createSetting<bool>(
    key: 'incognitoKeyboard',
    initialValue: false,
  );
  late final ValueNotifier<bool> allowHttpHosts = createSetting<bool>(
    key: 'allowHttpHosts',
    initialValue: false,
  );
  late final ValueNotifier<bool> iFinishedEnabled = createSetting<bool>(
    key: 'iFinishedEnabled',
    initialValue: false,
  );
  late final ValueNotifier<bool> iFinishedRequestPhoto = createSetting<bool>(
    key: 'iFinishedRequestPhoto',
    initialValue: false,
  );
  late final ValueNotifier<String?> appPin = createSetting(
    key: 'appPin',
    initialValue: null,
  );
  late final ValueNotifier<bool> biometricAuth = createSetting<bool>(
    key: 'biometricAuth',
    initialValue: false,
  );

  late final ValueNotifier<bool> showBeta = createSetting<bool>(
    key: 'showBeta',
    initialValue: false,
  );
  late final ValueNotifier<bool> showDev = createSetting<bool>(
    key: 'showDev',
    initialValue: false,
  );
}
