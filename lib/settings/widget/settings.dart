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

  static const double _desktopBreakpoint = 980;

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>().settings;
    final nav = Get.find<NavigationController>();

    return Scaffold(
      appBar: const DefaultAppBar(title: Text('Settings')),
      body: LimitedWidthLayout.builder(
        maxWidth: 1200,
        tolerance: 20,
        builder: (context) {
          return ValueListenableBuilder<bool>(
            valueListenable: settings.showDev,
            builder: (context, showDev, _) {
              final contentPadding = EdgeInsets.fromLTRB(
                16,
                12,
                16,
                defaultActionListBottomHeight,
              ).add(LimitedWidthLayout.of(context).padding);

              final hasLogs = context.read<Logs?>() != null;
              final sections = <_SettingsSectionEntry>[
                _SettingsSectionEntry(weight: 2, child: _identitySection()),
                _SettingsSectionEntry(weight: 4, child: _userSection(nav)),
                _SettingsSectionEntry(
                  weight: 7,
                  child: _appearanceSection(settings),
                ),
                _SettingsSectionEntry(
                  weight: 5,
                  child: _interactionsSection(settings),
                ),
                _SettingsSectionEntry(
                  weight: 5,
                  child: _securitySection(settings),
                ),
                if (showDev)
                  _SettingsSectionEntry(
                    weight: hasLogs ? 4 : 2,
                    child: _developmentSection(settings, hasLogs: hasLogs),
                  ),
                _SettingsSectionEntry(weight: 3, child: _aboutSection()),
              ];

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= _desktopBreakpoint;

                  return Container(
                    color: CupertinoColors.systemGroupedBackground.resolveFrom(
                      context,
                    ),
                    child: SingleChildScrollView(
                      padding: contentPadding,
                      child: isDesktop
                          ? _buildDesktopColumns(sections)
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: sections.map((e) => e.child).toList(),
                            ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDesktopColumns(List<_SettingsSectionEntry> sections) {
    final (left, right) = _balanceSections(sections);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: left.map((e) => e.child).toList(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: right.map((e) => e.child).toList(),
          ),
        ),
      ],
    );
  }

  (List<_SettingsSectionEntry>, List<_SettingsSectionEntry>) _balanceSections(
    List<_SettingsSectionEntry> sections,
  ) {
    final left = <_SettingsSectionEntry>[];
    final right = <_SettingsSectionEntry>[];
    var leftWeight = 0;
    var rightWeight = 0;

    for (final section in sections) {
      if (leftWeight <= rightWeight) {
        left.add(section);
        leftWeight += section.weight;
      } else {
        right.add(section);
        rightWeight += section.weight;
      }
    }

    return (left, right);
  }

  Widget _identitySection() {
    return _SettingsSection(
      title: 'Identity',
      child: _SettingsGroupCard(
        children: [
          Consumer<IdentityClient>(
            builder: (context, client, _) => IdentityTile(
              identity: client.identity,
              trailing: const Icon(CupertinoIcons.arrow_2_squarepath),
              onTap: () {
                HapticFeedback.selectionClick();
                Get.to(() => const IdentitiesPage());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _userSection(NavigationController nav) {
    return _SettingsSection(
      title: 'User',
      child: _SettingsGroupCard(
        children: [
          Consumer<Client>(
            builder: (context, client, _) => ValueListenableBuilder(
              valueListenable: client.traits,
              builder: (context, traits, _) => CupertinoListTile(
                leading: const _SettingsLeadingIcon(
                  icon: CupertinoIcons.nosign,
                  color: Color(0xFFE74C3C),
                ),
                title: const Text('Blacklist'),
                subtitle: traits.denylist.isNotEmpty
                    ? Text(
                        '${traits.denylist.join(' ').split(' ').trim().where((e) => e[0] != '-').length} tags blocked',
                      )
                    : null,
                trailing: const Icon(CupertinoIcons.chevron_forward, size: 18),
                onTap: () {
                  HapticFeedback.selectionClick();
                  nav.currentPath.value = AppRoutes.blacklist;
                },
              ),
            ),
          ),
          Consumer<Client>(
            builder: (context, client, _) => SubStream<int>(
              create: () => client.follows.count().streamed,
              keys: [client],
              builder: (context, snapshot) => CupertinoListTile(
                leading: const _SettingsLeadingIcon(
                  icon: CupertinoIcons.person_add,
                  color: Color(0xFF2E86DE),
                ),
                title: const Text('Follows'),
                subtitle: snapshot.data != null && snapshot.data != 0
                    ? Text('${snapshot.data} searches followed')
                    : null,
                trailing: const Icon(CupertinoIcons.chevron_forward, size: 18),
                onTap: () {
                  HapticFeedback.selectionClick();
                  Get.to(() => const FollowEditor());
                },
              ),
            ),
          ),
          Consumer<Client>(
            builder: (context, client, _) => SubStream<int>(
              create: () => client.histories.count().streamed,
              keys: [client],
              builder: (context, countSnapshot) => ValueListenableBuilder(
                valueListenable: client.traits,
                builder: (context, traits, _) {
                  final enabled = traits.writeHistory ?? false;
                  return CupertinoListTile(
                    leading: const _SettingsLeadingIcon(
                      icon: CupertinoIcons.clock,
                      color: Color(0xFF16A085),
                    ),
                    title: const Text('History'),
                    subtitle: enabled && countSnapshot.data != null
                        ? Text('${countSnapshot.data} pages visited')
                        : null,
                    trailing: CupertinoSwitch(
                      value: enabled,
                      onChanged: (value) {
                        HapticFeedback.selectionClick();
                        client.traits.value = client.traits.value.copyWith(
                          writeHistory: value,
                        );
                      },
                    ),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      nav.currentPath.value = AppRoutes.history;
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _appearanceSection(Settings settings) {
    return _SettingsSection(
      title: 'Appearance',
      child: _SettingsGroupCard(
        children: [
          ValueListenableBuilder<AppTheme>(
            valueListenable: settings.theme,
            builder: (context, value, _) => CupertinoListTile(
              leading: const _SettingsLeadingIcon(
                icon: CupertinoIcons.sun_max,
                color: Color(0xFFF39C12),
              ),
              title: const Text('Theme'),
              subtitle: Text(value.displayName),
              trailing: const Icon(CupertinoIcons.chevron_forward, size: 18),
              onTap: () {
                HapticFeedback.selectionClick();
                _showPickerSheet<AppTheme>(
                  context,
                  title: 'Theme',
                  values: AppTheme.values,
                  current: value,
                  labelOf: (theme) => theme.displayName,
                  trailingBuilder: (theme) => Container(
                    height: 20,
                    width: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.data.cardColor,
                      border: Border.all(
                        color: Theme.of(context).iconTheme.color!,
                      ),
                    ),
                  ),
                  onSelected: (theme) => settings.theme.value = theme,
                );
              },
            ),
          ),
          ValueListenableBuilder<int>(
            valueListenable: settings.tileSize,
            builder: (context, value, _) => CupertinoListTile(
              leading: const _SettingsLeadingIcon(
                icon: CupertinoIcons.square_grid_2x2,
                color: Color(0xFF8E44AD),
              ),
              title: const Text('Tile size'),
              subtitle: Text('$value px'),
              trailing: const Icon(CupertinoIcons.chevron_forward, size: 18),
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
                    onSubmit: (range) {
                      if (range == null || range.value <= 0) return;
                      settings.tileSize.value = range.value;
                    },
                  ),
                );
              },
            ),
          ),
          ValueListenableBuilder<GridQuilt>(
            valueListenable: settings.quilt,
            builder: (context, value, _) => CupertinoListTile(
              leading: _SettingsLeadingIcon(
                icon: value.icon,
                color: const Color(0xFF34495E),
              ),
              title: const Text('Quilt'),
              subtitle: Text(value.description),
              trailing: const Icon(CupertinoIcons.chevron_forward, size: 18),
              onTap: () {
                HapticFeedback.selectionClick();
                _showPickerSheet<GridQuilt>(
                  context,
                  title: 'Grid',
                  values: GridQuilt.values,
                  current: value,
                  labelOf: (state) => state.description,
                  trailingBuilder: (state) => Icon(state.icon),
                  onSelected: (state) => settings.quilt.value = state,
                );
              },
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: settings.showPostAura,
            builder: (context, value, _) => _SettingsSwitchTile(
              leading: const _SettingsLeadingIcon(
                icon: CupertinoIcons.sparkles,
                color: Color(0xFFE67E22),
              ),
              title: 'Post aura',
              subtitle: value ? 'Glow around post media' : 'No glow',
              value: value,
              onChanged: (v) => settings.showPostAura.value = v,
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: settings.showShareButton,
            builder: (context, value, _) => _SettingsSwitchTile(
              leading: const _SettingsLeadingIcon(
                icon: CupertinoIcons.share,
                color: Color(0xFF1ABC9C),
              ),
              title: 'Share button',
              subtitle: value
                  ? 'Show share action on posts'
                  : 'Hide share action on posts',
              value: value,
              onChanged: (v) => settings.showShareButton.value = v,
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: settings.showPostInfo,
            builder: (context, value, _) => _SettingsSwitchTile(
              leading: const _SettingsLeadingIcon(
                icon: CupertinoIcons.doc_text,
                color: Color(0xFF2980B9),
              ),
              title: 'Post info',
              subtitle: value ? 'Info on post tiles' : 'Image tiles only',
              value: value,
              onChanged: (v) => settings.showPostInfo.value = v,
            ),
          ),
        ],
      ),
    );
  }

  Widget _interactionsSection(Settings settings) {
    return _SettingsSection(
      title: 'Interactions',
      child: _SettingsGroupCard(
        children: [
          if (!Platform.isIOS)
            ValueListenableBuilder<String?>(
              valueListenable: settings.downloadPath,
              builder: (context, value, _) => CupertinoListTile(
                leading: const _SettingsLeadingIcon(
                  icon: CupertinoIcons.folder,
                  color: Color(0xFFF1C40F),
                ),
                title: const Text('Download location'),
                subtitle: value != null
                    ? Text(Uri.decodeComponent(Uri.parse(value).path))
                    : const Text('Choose directory'),
                trailing: const Icon(CupertinoIcons.chevron_forward, size: 18),
                onTap: () async {
                  HapticFeedback.selectionClick();
                  final result = await FileDownloader.pickDirectory(
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
            builder: (context, value, _) => _SettingsSwitchTile(
              leading: const _SettingsLeadingIcon(
                icon: CupertinoIcons.arrow_up,
                color: Color(0xFF27AE60),
              ),
              title: 'Upvote favorites',
              subtitle: value ? 'Upvote and favorite' : 'Favorite only',
              value: value,
              onChanged: (v) => settings.upvoteFavs.value = v,
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: settings.muteVideos,
            builder: (context, value, _) => _SettingsSwitchTile(
              leading: _SettingsLeadingIcon(
                icon: value
                    ? CupertinoIcons.speaker_slash
                    : CupertinoIcons.speaker_2,
                color: const Color(0xFF3498DB),
              ),
              title: 'Video volume',
              subtitle: value ? 'Muted' : 'With sound',
              value: value,
              onChanged: (v) => settings.muteVideos.value = v,
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: settings.autoplayVideos,
            builder: (context, value, _) => _SettingsSwitchTile(
              leading: const _SettingsLeadingIcon(
                icon: CupertinoIcons.play_circle,
                color: Color(0xFF9B59B6),
              ),
              title: 'Autoplay videos',
              subtitle: value ? 'Play automatically' : 'Play on tap',
              value: value,
              onChanged: (v) => settings.autoplayVideos.value = v,
            ),
          ),
          ValueListenableBuilder<VideoResolution>(
            valueListenable: settings.videoResolution,
            builder: (context, value, _) => CupertinoListTile(
              leading: const _SettingsLeadingIcon(
                icon: CupertinoIcons.videocam,
                color: Color(0xFF2ECC71),
              ),
              title: const Text('Video resolution'),
              subtitle: Text(value.title),
              trailing: const Icon(CupertinoIcons.chevron_forward, size: 18),
              onTap: () {
                HapticFeedback.selectionClick();
                _showPickerSheet<VideoResolution>(
                  context,
                  title: 'Video resolution',
                  values: VideoResolution.values,
                  current: value,
                  labelOf: (resolution) => resolution.title,
                  onSelected: (resolution) {
                    settings.videoResolution.value = resolution;
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _securitySection(Settings settings) {
    return _SettingsSection(
      title: 'Security',
      child: _SettingsGroupCard(
        children: [
          if (PlatformCapabilities.hasSecureDisplay)
            ValueListenableBuilder<bool>(
              valueListenable: settings.secureDisplay,
              builder: (context, value, _) => _SettingsSwitchTile(
                leading: const _SettingsLeadingIcon(
                  icon: CupertinoIcons.rectangle_on_rectangle_angled,
                  color: Color(0xFFE67E22),
                ),
                title: 'Secure display',
                subtitle: value ? 'Screen protected' : 'Screen visible',
                value: value,
                onChanged: (v) => settings.secureDisplay.value = v,
              ),
            ),
          if (Platform.isAndroid)
            ValueListenableBuilder<bool>(
              valueListenable: settings.incognitoKeyboard,
              builder: (context, value, _) => _SettingsSwitchTile(
                leading: const _SettingsLeadingIcon(
                  icon: CupertinoIcons.keyboard,
                  color: Color(0xFF7F8C8D),
                ),
                title: 'Incognito keyboard',
                subtitle: value ? 'Enabled' : 'Disabled',
                value: value,
                onChanged: (v) => settings.incognitoKeyboard.value = v,
              ),
            ),
          ValueListenableBuilder<String?>(
            valueListenable: settings.appPin,
            builder: (context, value, _) => _SettingsSwitchTile(
              leading: const _SettingsLeadingIcon(
                icon: CupertinoIcons.lock,
                color: Color(0xFF34495E),
              ),
              title: 'PIN lock',
              subtitle: value != null ? 'PIN enabled' : 'PIN disabled',
              value: value != null,
              onChanged: (enabled) async {
                if (enabled) {
                  final pin = await registerPin(context);
                  if (pin != null) settings.appPin.value = pin;
                } else {
                  settings.appPin.value = null;
                }
              },
            ),
          ),
          if (PlatformCapabilities.supportsBiometrics)
            SubFuture<bool>(
              create: () => LocalAuthentication().getAvailableBiometrics().then(
                (e) => e.isNotEmpty,
              ),
              builder: (context, snapshot) => ValueListenableBuilder<bool>(
                valueListenable: settings.biometricAuth,
                builder: (context, value, _) => _SettingsSwitchTile(
                  leading: const _SettingsLeadingIcon(
                    icon: CupertinoIcons.hand_raised,
                    color: Color(0xFF16A085),
                  ),
                  title: 'Biometric lock',
                  subtitle: value
                      ? 'Biometrics enabled'
                      : 'Biometrics disabled',
                  value: value,
                  onChanged: (snapshot.data ?? false)
                      ? (v) => settings.biometricAuth.value = v
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _developmentSection(Settings settings, {required bool hasLogs}) {
    return _SettingsSection(
      title: 'Development',
      child: _SettingsGroupCard(
        children: [
          _SettingsSwitchTile(
            leading: const _SettingsLeadingIcon(
              icon: CupertinoIcons.ant,
              color: Color(0xFF8E44AD),
            ),
            title: 'Developer mode',
            subtitle: 'Options shown',
            value: true,
            onChanged: (v) => settings.showDev.value = v,
          ),
          if (hasLogs) ...[
            Consumer<Logs>(
              builder: (context, logs, _) => SubStream<List<LogRecord>>(
                create: () =>
                    logs.stream(filter: (level, type) => level >= Level.SEVERE),
                builder: (context, snapshot) => CupertinoListTile(
                  leading: const _SettingsLeadingIcon(
                    icon: CupertinoIcons.list_number,
                    color: Color(0xFFD35400),
                  ),
                  title: const Text('Logs'),
                  subtitle: (snapshot.data?.isNotEmpty ?? false)
                      ? Text('${snapshot.data!.length} errors logged')
                      : null,
                  trailing: const Icon(
                    CupertinoIcons.chevron_forward,
                    size: 18,
                  ),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Get.to(() => const LogsPage());
                  },
                ),
              ),
            ),
            CupertinoListTile(
              leading: const _SettingsLeadingIcon(
                icon: CupertinoIcons.square_stack_3d_up,
                color: Color(0xFF2C3E50),
              ),
              title: const Text('Database'),
              trailing: const Icon(CupertinoIcons.chevron_forward, size: 18),
              onTap: () {
                HapticFeedback.selectionClick();
                Get.to(() => const DatabaseManagementPage());
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _aboutSection() {
    return _SettingsSection(
      title: 'About',
      child: DevOptionEnabler(
        child: Builder(
          builder: (context) {
            final theme = Theme.of(context);
            final client = context.read<AppInfoClient?>();
            final versions = client?.getNewVersions();
            final appInfo = AppInfo.instance;
            final surface = theme.brightness == Brightness.dark
                ? Color.lerp(theme.canvasColor, Colors.white, 0.04)!
                : theme.colorScheme.surface;

            return DecoratedBox(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(14),
              ),
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
    );
  }

  void _showPickerSheet<T>(
    BuildContext context, {
    required String title,
    required List<T> values,
    required T current,
    required String Function(T value) labelOf,
    required ValueChanged<T> onSelected,
    Widget Function(T value)? trailingBuilder,
  }) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => SafeArea(
        top: false,
        child: GlassSurface(
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          padding: const EdgeInsets.all(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 420),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ...values.map(
                    (value) => CupertinoListTile(
                      title: Text(labelOf(value)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (trailingBuilder != null) trailingBuilder(value),
                          if (current == value) ...[
                            const SizedBox(width: 8),
                            const Icon(CupertinoIcons.check_mark, size: 18),
                          ],
                        ],
                      ),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onSelected(value);
                        Navigator.of(context).maybePop();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(
      context,
    ).colorScheme.secondary.withValues(alpha: 0.9);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _SettingsGroupCard extends StatelessWidget {
  const _SettingsGroupCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.brightness == Brightness.dark
        ? Color.lerp(theme.canvasColor, Colors.white, 0.04)!
        : theme.colorScheme.surface;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return CupertinoListTile(
      leading: leading,
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: CupertinoSwitch(
        value: value,
        onChanged: onChanged == null
            ? null
            : (v) {
                HapticFeedback.selectionClick();
                onChanged!(v);
              },
      ),
    );
  }
}

class _SettingsSectionEntry {
  const _SettingsSectionEntry({required this.weight, required this.child});

  final int weight;
  final Widget child;
}

class _SettingsLeadingIcon extends StatelessWidget {
  const _SettingsLeadingIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(7),
      ),
      child: SizedBox(
        width: 28,
        height: 28,
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}
