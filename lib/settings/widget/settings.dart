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
import 'package:klit/traits/traits.dart';
import 'package:klit/user/user.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sub/flutter_sub.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';

const String settingsSectionArgumentKey = 'settingsSection';
const String settingsAccountsSectionValue = 'accounts';

void openSettingsAccounts() {
  Get.offAllNamed(
    AppRoutes.home,
    arguments: {
      'path': AppRoutes.settings,
      settingsSectionArgumentKey: settingsAccountsSectionValue,
    },
  );
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  static const double _desktopBreakpoint = 980;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _accountsSectionKey = GlobalKey();
  bool _focusedRequestedSection = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _focusAccountsSectionIfRequested() {
    if (_focusedRequestedSection) return;
    final args = Get.arguments;
    if (args is! Map) return;
    if (args[settingsSectionArgumentKey] != settingsAccountsSectionValue)
      return;
    _focusedRequestedSection = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final context = _accountsSectionKey.currentContext;
      if (!mounted || context == null) return;
      await Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        alignment: 0.05,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    _focusAccountsSectionIfRequested();
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
                _SettingsSectionEntry(weight: 7, child: _accountsSection()),
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
                  final isDesktop =
                      constraints.maxWidth >= SettingsPage._desktopBreakpoint;

                  return Container(
                    color: CupertinoColors.systemGroupedBackground.resolveFrom(
                      context,
                    ),
                    child: SingleChildScrollView(
                      controller: _scrollController,
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

  Widget _accountsSection() {
    return _SettingsSection(
      key: _accountsSectionKey,
      title: 'Accounts',
      child: SubStream<List<Identity>>(
        create: () => context.watch<IdentityClient>().all().stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _SettingsGroupCard(
              children: const [
                CupertinoListTile(
                  leading: Icon(Icons.warning_amber),
                  title: Text('Failed to load accounts'),
                  subtitle: Text('Try reopening Settings.'),
                ),
              ],
            );
          }
          final identities = snapshot.data;
          if (identities == null) {
            return _SettingsGroupCard(
              children: const [
                CupertinoListTile(
                  leading: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  title: Text('Loading accounts...'),
                ),
              ],
            );
          }

          final identityClient = context.watch<IdentityClient>();
          final activeIdentity = identityClient.identity;

          Future<void> addIdentity() async {
            HapticFeedback.selectionClick();
            await showIdentityEditorDialog(context: context);
          }

          Future<void> editIdentity(Identity identity) async {
            HapticFeedback.selectionClick();
            await showIdentityEditorDialog(
              context: context,
              identity: identity,
            );
          }

          Future<void> activateIdentity(Identity identity) async {
            HapticFeedback.selectionClick();
            await identityClient.activate(identity.id);
          }

          Future<void> deleteIdentity(Identity identity) async {
            HapticFeedback.selectionClick();
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete account?'),
                content: const Text(
                  'All local data will be removed, including follows and history.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('CANCEL'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('DELETE'),
                  ),
                ],
              ),
            );
            if (confirmed != true) return;
            await identityClient.remove(identity);
          }

          return _SettingsGroupCard(
            children: [
              CupertinoListTile(
                leading: IdentityAvatar(activeIdentity.id),
                title: Text(activeIdentity.usernameOrAnon),
                subtitle: Text(
                  'Active account • ${linkToDisplay(activeIdentity.host)}',
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Active',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: addIdentity,
                    icon: const Icon(Icons.add),
                    label: const Text('Add account'),
                  ),
                ),
              ),
              if (identities.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: identities.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final identity = identities[index];
                        final selected = identity.id == activeIdentity.id;
                        return ListTile(
                          dense: true,
                          leading: IdentityAvatar(identity.id),
                          title: Text(identity.usernameOrAnon),
                          subtitle: Text(linkToDisplay(identity.host)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (selected)
                                Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Active',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              PopupMenuButton<VoidCallback>(
                                onSelected: (value) => value(),
                                itemBuilder: (context) => [
                                  if (!selected)
                                    PopupMenuTile(
                                      title: 'Activate',
                                      icon: Icons.check,
                                      value: () => activateIdentity(identity),
                                    ),
                                  PopupMenuTile(
                                    title: 'Edit',
                                    icon: Icons.edit,
                                    value: () => editIdentity(identity),
                                  ),
                                  PopupMenuTile(
                                    title: 'Delete',
                                    icon: Icons.delete,
                                    value: () => deleteIdentity(identity),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () => activateIdentity(identity),
                        );
                      },
                    ),
                  ),
                ),
            ],
          );
        },
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
                  showDenyListEditorDialog(context);
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
          ValueListenableBuilder<String>(
            valueListenable: settings.postActionBarActions,
            builder: (context, rawActions, _) {
              final actions = PostActionPreferences.decode(rawActions);
              return CupertinoListTile(
                leading: const _SettingsLeadingIcon(
                  icon: CupertinoIcons.square_stack_3d_down_right,
                  color: Color(0xFF1ABC9C),
                ),
                title: const Text('Post action bar'),
                subtitle: Text('${actions.length} actions pinned'),
                trailing: const Icon(CupertinoIcons.chevron_forward, size: 18),
                onTap: () {
                  HapticFeedback.selectionClick();
                  _showPostActionBarEditor(context, settings);
                },
              );
            },
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
            final appInfo = AppInfo.instance;
            final surface = theme.brightness == Brightness.dark
                ? Color.lerp(theme.canvasColor, Colors.white, 0.04)!
                : theme.colorScheme.surface;
            final onTop = theme.colorScheme.onSurface;
            final buildNumber = appInfo.buildNumber.trim();
            final versionLabel = buildNumber.isEmpty
                ? 'v${appInfo.version}'
                : 'v${appInfo.version} ($buildNumber)';
            final sourceName = switch (appInfo.source) {
              Source.IS_INSTALLED_FROM_LOCAL_SOURCE => 'Local build',
              Source.IS_INSTALLED_FROM_OTHER_SOURCE => 'Other source',
              Source.UNKNOWN => null,
              _ => 'Store install',
            };

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const AppIcon(radius: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    appInfo.appName,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: onTop,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    versionLabel,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: onTop.withValues(alpha: 0.82),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _AboutMetaPill(
                              icon: CupertinoIcons.person,
                              text: appInfo.developer,
                              color: onTop.withValues(alpha: 0.14),
                              textColor: onTop,
                            ),
                            _AboutMetaPill(
                              icon: CupertinoIcons.info,
                              text: 'v${appInfo.version}',
                              color: onTop.withValues(alpha: 0.14),
                              textColor: onTop,
                            ),
                            if (sourceName != null)
                              _AboutMetaPill(
                                icon: CupertinoIcons.cube_box,
                                text: sourceName,
                                color: onTop.withValues(alpha: 0.14),
                                textColor: onTop,
                              ),
                            _AboutMetaPill(
                              icon: CupertinoIcons.number,
                              text: appInfo.packageName,
                              color: onTop.withValues(alpha: 0.14),
                              textColor: onTop,
                            ),
                            if (appInfo.website != null)
                              _AboutMetaPill(
                                icon: CupertinoIcons.globe,
                                text: appInfo.website!,
                                color: onTop.withValues(alpha: 0.14),
                                textColor: onTop,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  launch('https://${appInfo.website!}');
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showPostActionBarEditor(BuildContext context, Settings settings) {
    final initial = PostActionPreferences.decode(
      settings.postActionBarActions.value,
    );
    final selected = <PostActionId>[...initial];

    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final available = PostActionId.values
                .where((action) => !selected.contains(action))
                .toList();

            return SafeArea(
              top: false,
              child: GlassSurface(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                padding: const EdgeInsets.all(12),
                child: Material(
                  color: Colors.transparent,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 560),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(8, 4, 8, 8),
                            child: Text(
                              'Post action bar',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                            child: Text(
                              'Pinned actions are shown first on post detail. Drag to reorder.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          ReorderableListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            buildDefaultDragHandles: false,
                            itemCount: selected.length,
                            onReorder: (oldIndex, newIndex) {
                              setSheetState(() {
                                if (newIndex > oldIndex) {
                                  newIndex -= 1;
                                }
                                final action = selected.removeAt(oldIndex);
                                selected.insert(newIndex, action);
                              });
                            },
                            itemBuilder: (context, index) {
                              final action = selected[index];
                              return ListTile(
                                key: ValueKey(action.key),
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                leading: Icon(action.icon, size: 20),
                                title: Text(action.label),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        setSheetState(() {
                                          selected.removeAt(index);
                                        });
                                        HapticFeedback.selectionClick();
                                      },
                                      icon: const Icon(
                                        CupertinoIcons.minus_circle,
                                      ),
                                    ),
                                    ReorderableDragStartListener(
                                      index: index,
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        child: Icon(
                                          CupertinoIcons.line_horizontal_3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          if (available.isNotEmpty) const Divider(height: 20),
                          if (available.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                              child: Text(
                                'Available',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ...available.map(
                            (action) => CupertinoListTile(
                              leading: Icon(action.icon, size: 20),
                              title: Text(action.label),
                              trailing: const Icon(
                                CupertinoIcons.plus_circle,
                                size: 20,
                              ),
                              onTap: () {
                                setSheetState(() {
                                  selected.add(action);
                                });
                                HapticFeedback.selectionClick();
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: () {
                                  settings.postActionBarActions.value =
                                      PostActionPreferences.encode(selected);
                                  HapticFeedback.selectionClick();
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Save'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
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
  const _SettingsSection({super.key, required this.title, required this.child});

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

class _AboutMetaPill extends StatelessWidget {
  const _AboutMetaPill({
    required this.icon,
    required this.text,
    required this.color,
    required this.textColor,
    this.onTap,
  });

  final IconData icon;
  final String text;
  final Color color;
  final Color textColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: textColor),
              const SizedBox(width: 6),
              Text(
                text,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
