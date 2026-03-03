import 'dart:async';
import 'dart:io';

import 'package:klit/app/app.dart';
import 'package:klit/app/routes/app_routes.dart';
import 'package:klit/client/client.dart';
import 'package:klit/follow/follow.dart';
import 'package:klit/identity/identity.dart';
import 'package:klit/logs/logs.dart';
import 'package:klit/settings/settings.dart';
import 'package:klit/shared/shared.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sub/flutter_sub.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>().settings;
    return Scaffold(
        appBar: const DefaultAppBar(title: Text('Settings')),
        body: LimitedWidthLayout.builder(
          builder: (context) => ListView(
            primary: true,
            padding: defaultActionListPadding.add(
              LimitedWidthLayout.of(context).padding,
            ),
            children: [
              const ListTileHeader(title: 'Identity'),
              Consumer<IdentityClient>(
                builder: (context, client, child) => IdentityTile(
                  identity: client.identity,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Get.to(() => const IdentitiesPage());
                  },
                  trailing: const Icon(CupertinoIcons.arrow_2_squarepath),
                ),
              ),
              const Divider(),
              const ListTileHeader(title: 'User'),
              Consumer<Client>(
                builder: (context, client, child) => ValueListenableBuilder(
                  valueListenable: client.traits,
                  builder: (context, traits, child) => CupertinoListTile(
                    title: const Text('Blacklist'),
                    leading: const Icon(CupertinoIcons.nosign),
                    subtitle: traits.denylist.isNotEmpty
                        ? Text(
                            '${traits.denylist.join(' ').split(' ').trim().where((e) => e[0] != '-').length} tags blocked',
                          )
                        : null,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Get.find<NavigationController>().currentPath.value =
                          AppRoutes.blacklist;
                    },
                  ),
                ),
              ),
              Consumer<Client>(
                builder: (context, client, child) => SubStream<int>(
                  create: () => client.follows.count().streamed,
                  keys: [client],
                  builder: (context, snapshot) => CupertinoListTile(
                    title: const Text('Follows'),
                    subtitle: snapshot.data != null && snapshot.data != 0
                        ? Text('${snapshot.data} searches followed')
                        : null,
                    leading: const Icon(CupertinoIcons.person_add),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Get.to(() => const FollowEditor());
                    },
                  ),
                ),
              ),
              Consumer<Client>(
                builder: (context, client, child) => SubStream<int>(
                  create: () => client.histories.count().streamed,
                  keys: [client],
                  builder: (context, countSnapshot) {
                    int? count = countSnapshot.data;
                    return ValueListenableBuilder(
                      valueListenable: client.traits,
                      builder: (context, traits, child) {
                        bool enabled = traits.writeHistory ?? false;
                        return DividerListTile(
                          title: const Text('History'),
                          subtitle: enabled && count != null
                              ? Text('$count pages visited')
                              : null,
                          leading: const Icon(CupertinoIcons.clock),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Get.find<NavigationController>().currentPath.value =
                                AppRoutes.history;
                          },
                          onTapSeparated: () {
                            HapticFeedback.selectionClick();
                            client.traits.value = client
                                .traits
                                .value
                                .copyWith(writeHistory: !enabled);
                          },
                          separated: CupertinoSwitch(
                            value: enabled,
                            onChanged: (value) {
                              HapticFeedback.selectionClick();
                              client.traits.value = client.traits.value
                                  .copyWith(writeHistory: value);
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(),
              const ListTileHeader(title: 'Appearance'),
              ValueListenableBuilder<AppTheme>(
                valueListenable: settings.theme,
                builder: (context, value, child) => CupertinoListTile(
                  title: const Text('Theme'),
                  subtitle: Text(value.displayName),
                  leading: const Icon(CupertinoIcons.sun_max),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    showCupertinoModalPopup<void>(
                      context: context,
                      builder: (context) => GlassSurface(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('Theme', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 12),
                            ...([AppTheme.light, AppTheme.dark, AppTheme.amoled]
                                .map(
                                  (theme) => CupertinoListTile(
                                    title: Text(theme.displayName),
                                    trailing: Container(
                                      height: 28,
                                      width: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: theme.data.cardColor,
                                        border: Border.all(
                                          color: Theme.of(context).iconTheme.color!,
                                        ),
                                      ),
                                    ),
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      settings.theme.value = theme;
                                      Navigator.of(context).maybePop();
                                    },
                                  ),
                                )),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Column(
                children: [
                  ValueListenableBuilder<int>(
                    valueListenable: settings.tileSize,
                    builder: (context, value, child) => CupertinoListTile(
                      title: const Text('Tile size'),
                      subtitle: Text(value.toString()),
                      leading: const Icon(CupertinoIcons.square_grid_2x2),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    showCupertinoDialog<void>(
                      context: context,
                      builder: (context) => RangeDialog(
                          title: const Text('Tile size'),
                          value: NumberRange(value),
                          initialMode: RangeDialogMode.exact,
                          enforceMax: false,
                          canChangeMode: false,
                          division: (300 / 50).round(),
                          min: 100,
                          max: 400,
                          onSubmit: (value) {
                            if (value == null || value.value <= 0) {
                              return;
                            }
                            settings.tileSize.value = value.value;
                          },
                        ),
                      );
                    },
                    ),
                  ),
                  ValueListenableBuilder<GridQuilt>(
                    valueListenable: settings.quilt,
                    builder: (context, value, child) => GridSettingsTile(
                      state: value,
                      onChange: (value) {
                        HapticFeedback.selectionClick();
                        settings.quilt.value = value;
                      },
                    ),
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: settings.showPostAura,
                    builder: (context, value, child) => CupertinoListTile(
                      title: const Text('Post aura'),
                      subtitle: Text(
                        value ? 'glow around post media' : 'no glow',
                      ),
                      leading: const Icon(CupertinoIcons.sparkles),
                      trailing: CupertinoSwitch(
                        value: value,
                        onChanged: (v) {
                          HapticFeedback.selectionClick();
                          settings.showPostAura.value = v;
                        },
                      ),
                    ),
                  ),
                ],
              ),
              ValueListenableBuilder<bool>(
                valueListenable: settings.showShareButton,
                builder: (context, value, child) => CupertinoListTile(
                  title: const Text('Share button'),
                  subtitle: Text(
                    value ? 'show share action on posts' : 'hide share action',
                  ),
                  leading: const Icon(CupertinoIcons.share),
                  trailing: CupertinoSwitch(
                    value: value,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      settings.showShareButton.value = v;
                    },
                  ),
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: settings.showPostInfo,
                builder: (context, value, child) => CupertinoListTile(
                  title: const Text('Post info'),
                  subtitle: Text(
                    value ? 'info on post tiles' : 'image tiles only',
                  ),
                  leading: const Icon(CupertinoIcons.doc_text),
                  trailing: CupertinoSwitch(
                    value: value,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      settings.showPostInfo.value = v;
                    },
                  ),
                ),
              ),
              const Divider(),
              const ListTileHeader(title: 'Interactions'),
              if (!Platform.isIOS)
                ValueListenableBuilder<String?>(
                  valueListenable: settings.downloadPath,
                  builder: (context, value, child) => CupertinoListTile(
                    title: const Text('Download location'),
                    subtitle: value != null
                        ? Text(Uri.decodeComponent(Uri.parse(value).path))
                        : null,
                    leading: const Icon(CupertinoIcons.folder),
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      String? result = await FileDownloader.pickDirectory(
                        initial: value,
                      );
                      if (result != null) {
                        unawaited(FileDownloader.forgetDirectory(value));
                        settings.downloadPath.value = result;
                      }
                    },
                  ),
                ),
              ValueListenableBuilder<bool>(
                valueListenable: settings.upvoteFavs,
                builder: (context, value, child) => CupertinoListTile(
                  title: const Text('Upvote favorites'),
                  subtitle: Text(
                    value ? 'upvote and favorite' : 'favorite only',
                  ),
                  leading: const Icon(CupertinoIcons.arrow_up),
                  trailing: CupertinoSwitch(
                    value: value,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      settings.upvoteFavs.value = v;
                    },
                  ),
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: settings.muteVideos,
                builder: (context, value, child) => CupertinoListTile(
                  title: const Text('Video volume'),
                  subtitle: Text(value ? 'muted' : 'with sound'),
                  leading: Icon(value ? CupertinoIcons.volume_mute : CupertinoIcons.volume_up),
                  trailing: CupertinoSwitch(
                    value: value,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      settings.muteVideos.value = v;
                    },
                  ),
                ),
              ),
              ValueListenableBuilder<VideoResolution>(
                valueListenable: settings.videoResolution,
                builder: (context, value, child) => CupertinoListTile(
                  title: const Text('Video resolution'),
                  subtitle: Text(value.title),
                  leading: const Icon(CupertinoIcons.videocam),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    showCupertinoModalPopup<void>(
                      context: context,
                      builder: (context) => GlassSurface(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('Video resolution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 12),
                            ...VideoResolution.values.map(
                              (resolution) => CupertinoListTile(
                                title: Text(resolution.title),
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  settings.videoResolution.value = resolution;
                                  Navigator.of(context).maybePop();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              const ListTileHeader(title: 'Security'),
              if (PlatformCapabilities.hasSecureDisplay)
                ValueListenableBuilder<bool>(
                  valueListenable: settings.secureDisplay,
                  builder: (context, value, child) => CupertinoListTile(
                    title: const Text('Secure display'),
                    subtitle: Text(
                      value ? 'screen protected' : 'screen visible',
                    ),
                    leading: const Icon(CupertinoIcons.rectangle_on_rectangle_angled),
                    trailing: CupertinoSwitch(
                      value: value,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        settings.secureDisplay.value = v;
                      },
                    ),
                  ),
                ),
              if (Platform.isAndroid)
                ValueListenableBuilder<bool>(
                  valueListenable: settings.incognitoKeyboard,
                  builder: (context, value, child) => CupertinoListTile(
                    title: const Text('Incognito keyboard'),
                    subtitle: Text(value ? 'enabled' : 'disabled'),
                    leading: const Icon(CupertinoIcons.keyboard),
                    trailing: CupertinoSwitch(
                      value: value,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        settings.incognitoKeyboard.value = v;
                      },
                    ),
                  ),
                ),
              ValueListenableBuilder<String?>(
                valueListenable: settings.appPin,
                builder: (context, value, child) => CupertinoListTile(
                  title: const Text('PIN lock'),
                  subtitle: Text(
                    value != null ? 'PIN enabled' : 'PIN disabled',
                  ),
                  leading: const Icon(CupertinoIcons.lock),
                  trailing: CupertinoSwitch(
                    value: value != null,
                    onChanged: (v) async {
                      HapticFeedback.selectionClick();
                      if (v) {
                        String? pin = await registerPin(context);
                        if (pin != null) {
                          settings.appPin.value = pin;
                        }
                      } else {
                        settings.appPin.value = null;
                      }
                    },
                  ),
                ),
              ),
              if (PlatformCapabilities.supportsBiometrics)
                SubFuture<bool>(
                  create: () => LocalAuthentication()
                      .getAvailableBiometrics()
                      .then((e) => e.isNotEmpty),
                  builder: (context, snapshot) => ValueListenableBuilder<bool>(
                    valueListenable: settings.biometricAuth,
                    builder: (context, value, child) => CupertinoListTile(
                      title: const Text('Biometric lock'),
                      subtitle: Text(
                        value ? 'biometrics enabled' : 'biometrics disabled',
                      ),
                      leading: const Icon(CupertinoIcons.hand_raised),
                      trailing: CupertinoSwitch(
                        value: value,
                        onChanged: (snapshot.data ?? false)
                            ? (v) {
                                HapticFeedback.selectionClick();
                                settings.biometricAuth.value = v;
                              }
                            : null,
                      ),
                    ),
                  ),
                ),
              const Divider(),
              const ListTileHeader(title: 'Development'),
              ValueListenableBuilder<bool>(
                valueListenable: settings.showDev,
                builder: (context, value, child) {
                  if (!value) return const SizedBox();
                  return CupertinoListTile(
                    title: const Text('Developer mode'),
                    subtitle: Text(value ? 'options shown' : 'options hidden'),
                    leading: const Icon(CupertinoIcons.ant),
                    trailing: CupertinoSwitch(
                      value: value,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        settings.showDev.value = v;
                      },
                    ),
                  );
                },
              ),
              if (context.watch<Logs?>() != null) ...[
                Consumer<Logs>(
                  builder: (context, logs, child) => SubStream<List<LogRecord>>(
                    create: () => logs.stream(
                      filter: (level, type) => level >= Level.SEVERE,
                    ),
                    builder: (context, snapshot) => CupertinoListTile(
                      leading: const Icon(CupertinoIcons.list_number),
                      title: const Text('Logs'),
                      subtitle: (snapshot.data?.isNotEmpty ?? false)
                          ? Text('${snapshot.data!.length} errors logged')
                          : null,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Get.to(() => const LogsPage());
                      },
                    ),
                  ),
                ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.square_stack_3d_up),
                  title: const Text('Database'),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Get.to(() => const DatabaseManagementPage());
                  },
                ),
              ],
              const Divider(),
              const ListTileHeader(title: 'About'),
              DevOptionEnabler(
                child: Builder(
                  builder: (context) {
                    final theme = Theme.of(context);
                    final client = context.read<AppInfoClient?>();
                    final versions = client?.getNewVersions();
                    final appInfo = AppInfo.instance;
                    final cardColor = theme.brightness == Brightness.dark
                        ? Color.lerp(theme.canvasColor, Colors.white, 0.06)!
                        : theme.cardColor;
                    return GlassCard(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: cardColor,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CupertinoListTile(
                            leading: const AppIcon(radius: 24),
                            title: Text(appInfo.appName),
                            subtitle: Text(appInfo.version),
                          ),
                          const Divider(height: 1),
                          AboutVersion(newVersions: versions),
                          const AboutLinks(),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
    );
  }
}
