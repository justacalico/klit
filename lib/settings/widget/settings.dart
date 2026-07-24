import 'dart:async';
import 'dart:io';

import 'package:kilt/app/app.dart';
import 'package:kilt/app/routing/app_routes.dart';
import 'package:kilt/client/client.dart';
import 'package:kilt/follow/follow.dart';
import 'package:kilt/identity/identity.dart';
import 'package:kilt/logs/logs.dart';
import 'package:kilt/settings/settings.dart';
import 'package:kilt/shared/shared.dart';
import 'package:kilt/traits/traits.dart';
import 'package:kilt/user/user.dart';
import 'package:kilt/settings/widget/settings_shared.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart' show ColorPicker;
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:flutter_sub/flutter_sub.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Consumer;
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

const String settingsSectionArgumentKey = 'settingsSection';
const String settingsAccountsSectionValue = 'accounts';

enum _AppLocaleChoice { system, en, zh }

void openSettingsAccounts(BuildContext context) {
  context.go('/settings?$settingsSectionArgumentKey=$settingsAccountsSectionValue');
}

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  static const double _desktopBreakpoint = 980;

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  static final List<Color> _accentPresets = [
    colorFromHex(defaultAccentColorHex),
    const Color(0xFFF48FB1),
    const Color(0xFFE57373),
    const Color(0xFFBA68C8),
    const Color(0xFF7986CB),
    const Color(0xFF4FC3F7),
    const Color(0xFF4DB6AC),
    const Color(0xFFAED581),
  ];

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _accountsSectionKey = GlobalKey();
  bool _focusedRequestedSection = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _focusAccountsSectionIfRequested(BuildContext context) {
    if (_focusedRequestedSection) return;
    final params = GoRouterState.of(context).uri.queryParameters;
    if (params[settingsSectionArgumentKey] != settingsAccountsSectionValue) {
      return;
    }
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
    _focusAccountsSectionIfRequested(context);
    final settings = context.read<Settings>();
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: DefaultAppBar(title: Text(l10n.settingsTitle)),
      body: LimitedWidthLayout.builder(
        maxWidth: 1200,
        tolerance: 20,
        builder: (context) {
          final contentPadding = EdgeInsets.fromLTRB(
            16,
            12,
            16,
            defaultActionListBottomHeight,
          ).add(LimitedWidthLayout.of(context).padding);

          final hasLogs = context.read<Logs?>() != null;
          final sections = <SettingsSectionEntry>[
            SettingsSectionEntry(weight: 7, child: _accountsSection()),
            SettingsSectionEntry(weight: 4, child: _userSection()),
            SettingsSectionEntry(
              weight: 7,
              child: _appearanceSection(settings),
            ),
            SettingsSectionEntry(
              weight: 5,
              child: _interactionsSection(settings),
            ),
            SettingsSectionEntry(
              weight: 5,
              child: _securitySection(settings),
            ),
            SettingsSectionEntry(
              weight: 4,
              child: _developmentSectionWrapper(
                settings: settings,
                hasLogs: hasLogs,
              ),
            ),
            SettingsSectionEntry(weight: 3, child: const SettingsAboutSection()),
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
      ),
    );
  }

  Widget _buildDesktopColumns(List<SettingsSectionEntry> sections) {
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

  (List<SettingsSectionEntry>, List<SettingsSectionEntry>) _balanceSections(
    List<SettingsSectionEntry> sections,
  ) {
    final left = <SettingsSectionEntry>[];
    final right = <SettingsSectionEntry>[];
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
    final l10n = AppLocalizations.of(context);
    return SettingsSection(
      key: _accountsSectionKey,
      title: l10n.settingsSectionAccounts,
      child: SubStream<List<Identity>>(
        create: () => context.watch<IdentityClient>().all().stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return SettingsGroupCard(
              children: [
                CupertinoListTile(
                  leading: const Icon(Icons.warning_amber),
                  title: Text(l10n.settingsFailedLoadAccounts),
                  subtitle: Text(l10n.settingsTryReopen),
                ),
              ],
            );
          }
          final identities = snapshot.data;
          if (identities == null) {
            return SettingsGroupCard(
              children: [
                CupertinoListTile(
                  leading: const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  title: Text(l10n.settingsLoadingAccounts),
                ),
              ],
            );
          }

          final identityClient = context.watch<IdentityClient>();
          final activeIdentity = identityClient.identity;

          Future<void> addIdentity() async {
            HapticFeedback.selectionClick();
            final allowHttp =
                context.read<Settings>().allowHttpHosts.value;
            await showIdentityEditorDialog(
              context: context,
              allowHttpHosts: allowHttp,
            );
          }

          Future<void> editIdentity(Identity identity) async {
            HapticFeedback.selectionClick();
            final allowHttp =
                context.read<Settings>().allowHttpHosts.value;
            await showIdentityEditorDialog(
              context: context,
              identity: identity,
              allowHttpHosts: allowHttp,
            );
          }

          Future<void> activateIdentity(Identity identity) async {
            HapticFeedback.selectionClick();
            if (identity.id == activeIdentity.id) return;
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (context) => PopScope(
                canPop: false,
                child: Dialog(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text(l10n.settingsSwitchingAccount),
                      ],
                    ),
                  ),
                ),
              ),
            );
            try {
              await Future.wait<void>([
                identityClient.activate(identity.id),
                Future<void>.delayed(const Duration(seconds: 1)),
              ]);
            } finally {
              if (context.mounted) {
                Navigator.of(context, rootNavigator: true).pop();
              }
            }
          }

          Future<void> testIdentity(Identity identity) async {
            HapticFeedback.selectionClick();
            final theme = Theme.of(context);
            OverlayEntry? testResultOverlay;

            void showTestResult({
              required bool success,
              required String message,
            }) {
              final bgColor = theme.brightness == Brightness.dark
                  ? Color.lerp(theme.canvasColor, Colors.white, 0.08)!
                  : theme.colorScheme.surfaceContainerHighest;
              final fgColor = theme.colorScheme.onSurface;
              testResultOverlay?.remove();
              testResultOverlay = OverlayEntry(
                builder: (context) => SafeArea(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Material(
                        color: Colors.transparent,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  success
                                      ? CupertinoIcons.check_mark_circled_solid
                                      : CupertinoIcons
                                            .exclamationmark_triangle_fill,
                                  size: 18,
                                  color: success
                                      ? theme.colorScheme.secondary
                                      : theme.colorScheme.error,
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    message,
                                    style: TextStyle(color: fgColor),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
              Overlay.of(context, rootOverlay: true).insert(testResultOverlay!);
              Future<void>.delayed(Duration(seconds: success ? 1 : 2), () {
                testResultOverlay?.remove();
                testResultOverlay = null;
              });
            }

            final apikey = parseBasicAuth(
              identity.headers?[HttpHeaders.authorizationHeader],
            )?.$2;
            await showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (dialogContext) => LoginLoadingDialog(
                identity: identity,
                host: identity.host,
                username: identity.username,
                apikey: apikey,
                onError: (value) {
                  showTestResult(
                    success: false,
                    message: value ?? l10n.settingsFailedConnect(identity.host),
                  );
                },
                onDone: () {
                  showTestResult(
                    success: true,
                    message: l10n.settingsConnectedTo(linkToDisplay(identity.host)),
                  );
                },
              ),
            );
          }

          Future<void> deleteIdentity(Identity identity) async {
            HapticFeedback.selectionClick();
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(l10n.settingsDeleteAccountTitle),
                content: Text(
                  l10n.settingsDeleteAccountBody,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(l10n.commonCancelUpper),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(l10n.settingsDeleteUpper),
                  ),
                ],
              ),
            );
            if (confirmed != true) return;
            await identityClient.remove(identity);
          }

          return SettingsGroupCard(
            children: [
              CupertinoListTile(
                leading: IdentityAvatar(activeIdentity.id),
                title: Text(activeIdentity.usernameOrAnon),
                subtitle: Text(
                  l10n.settingsActiveAccount(linkToDisplay(activeIdentity.host)),
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
                    l10n.settingsActive,
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
                    label: Text(l10n.settingsAddAccount),
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
                                    l10n.settingsActive,
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
                                      title: l10n.settingsActivate,
                                      icon: Icons.check,
                                      value: () => activateIdentity(identity),
                                    ),
                                  PopupMenuTile(
                                    title: l10n.settingsTest,
                                    icon: Icons.wifi_tethering,
                                    value: () => testIdentity(identity),
                                  ),
                                  PopupMenuTile(
                                    title: l10n.commonEdit,
                                    icon: Icons.edit,
                                    value: () => editIdentity(identity),
                                  ),
                                  PopupMenuTile(
                                    title: l10n.commonDelete,
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

  Widget _userSection() {
    final l10n = AppLocalizations.of(context);
    return SettingsSection(
      title: l10n.settingsSectionUser,
      child: SettingsGroupCard(
        children: [
          Consumer<Client>(
            builder: (context, client, _) => ValueListenableBuilder(
              valueListenable: client.traits,
              builder: (context, traits, _) => CupertinoListTile(
                leading: const SettingsLeadingIcon(
                  icon: CupertinoIcons.nosign,
                  color: Color(0xFFE74C3C),
                ),
                title: Text(l10n.settingsBlacklist),
                subtitle: traits.denylist.isNotEmpty
                    ? Text(
                        l10n.settingsTagsBlocked(traits.denylist.join(' ').split(' ').trim().where((e) => e.isNotEmpty && e[0] != '-').length),
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
                leading: const SettingsLeadingIcon(
                  icon: CupertinoIcons.person_add,
                  color: Color(0xFF2E86DE),
                ),
                title: Text(l10n.settingsFollows),
                subtitle: snapshot.data != null && snapshot.data != 0
                    ? Text(l10n.settingsSearchesFollowed(snapshot.data!))
                    : null,
                trailing: const Icon(CupertinoIcons.chevron_forward, size: 18),
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (_) => const FollowEditor(),
                    ),
                  );
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
                    leading: const SettingsLeadingIcon(
                      icon: CupertinoIcons.clock,
                      color: Color(0xFF16A085),
                    ),
                    title: Text(l10n.settingsHistory),
                    subtitle: enabled && countSnapshot.data != null
                        ? Text(l10n.settingsPagesVisited(countSnapshot.data!))
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
                      context.go(AppRoutes.history);
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
    final l10n = AppLocalizations.of(context);
    return SettingsSection(
      title: l10n.settingsSectionAppearance,
      child: SettingsGroupCard(
        children: [
          ValueListenableBuilder<AppTheme>(
            valueListenable: settings.theme,
            builder: (context, value, _) => CupertinoListTile(
              leading: const SettingsLeadingIcon(
                icon: CupertinoIcons.sun_max,
                color: Color(0xFFF39C12),
              ),
              title: Text(l10n.settingsTheme),
              subtitle: Text(value.displayName),
              trailing: const Icon(CupertinoIcons.chevron_forward, size: 18),
              onTap: () {
                HapticFeedback.selectionClick();
                _showPickerSheet<AppTheme>(
                  context,
                  title: l10n.settingsTheme,
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
          ValueListenableBuilder<String?>(
            valueListenable: settings.localeTag,
            builder: (context, tag, _) {
              final l10n = AppLocalizations.of(context);
              final current = switch (tag) {
                null || '' => _AppLocaleChoice.system,
                'en' => _AppLocaleChoice.en,
                'zh' => _AppLocaleChoice.zh,
                _ => _AppLocaleChoice.system,
              };

              String subtitleOf(_AppLocaleChoice choice) => switch (choice) {
                _AppLocaleChoice.system => l10n.settingsLanguageSystem,
                _AppLocaleChoice.en => l10n.settingsLanguageEnglish,
                _AppLocaleChoice.zh => l10n.settingsLanguageSimplifiedChinese,
              };

              return CupertinoListTile(
                leading: const SettingsLeadingIcon(
                  icon: CupertinoIcons.globe,
                  color: Color(0xFF95A5A6),
                ),
                title: Text(l10n.settingsLanguageTitle),
                subtitle: Text(subtitleOf(current)),
                trailing: const Icon(CupertinoIcons.chevron_forward, size: 18),
                onTap: () {
                  HapticFeedback.selectionClick();
                  _showPickerSheet<_AppLocaleChoice>(
                    context,
                    title: l10n.settingsLanguageTitle,
                    values: _AppLocaleChoice.values,
                    current: current,
                    labelOf: subtitleOf,
                    onSelected: (choice) {
                      settings.localeTag.value = switch (choice) {
                        _AppLocaleChoice.system => null,
                        _AppLocaleChoice.en => 'en',
                        _AppLocaleChoice.zh => 'zh',
                      };
                    },
                  );
                },
              );
            },
          ),
          ValueListenableBuilder<String>(
            valueListenable: settings.accentColorHex,
            builder: (context, value, _) {
              final accent = colorFromHex(value);
              final hex = hexFromColor(accent);
              return CupertinoListTile(
                leading: const SettingsLeadingIcon(
                  icon: CupertinoIcons.paintbrush,
                  color: Color(0xFFEC6F91),
                ),
                title: Text(l10n.settingsAccentColor),
                subtitle: Text(hex),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent,
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(CupertinoIcons.chevron_forward, size: 18),
                  ],
                ),
                onTap: () {
                  HapticFeedback.selectionClick();
                  _showAccentColorSheet(context, settings);
                },
              );
            },
          ),
          ValueListenableBuilder<int>(
            valueListenable: settings.tileSize,
            builder: (context, value, _) => CupertinoListTile(
              leading: const SettingsLeadingIcon(
                icon: CupertinoIcons.square_grid_2x2,
                color: Color(0xFF8E44AD),
              ),
              title: Text(l10n.settingsTileSize),
              subtitle: Text(l10n.settingsTileSizeValue(value)),
              trailing: const Icon(CupertinoIcons.chevron_forward, size: 18),
              onTap: () {
                HapticFeedback.selectionClick();
                showCupertinoDialog<void>(
                  context: context,
                  builder: (context) => RangeDialog(
                    title: Text(l10n.settingsTileSize),
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
              leading: SettingsLeadingIcon(
                icon: value.icon,
                color: const Color(0xFF34495E),
              ),
              title: Text(l10n.settingsQuilt),
              subtitle: Text(value.description(context)),
              trailing: const Icon(CupertinoIcons.chevron_forward, size: 18),
              onTap: () {
                HapticFeedback.selectionClick();
                _showPickerSheet<GridQuilt>(
                  context,
                  title: l10n.settingsGrid,
                  values: GridQuilt.values,
                  current: value,
                  labelOf: (state) => state.description(context),
                  trailingBuilder: (state) => Icon(state.icon),
                  onSelected: (state) => settings.quilt.value = state,
                );
              },
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: settings.showPostInfo,
            builder: (context, value, _) => SettingsSwitchTile(
              leading: const SettingsLeadingIcon(
                icon: CupertinoIcons.doc_text,
                color: Color(0xFF2980B9),
              ),
              title: l10n.settingsPostInfo,
              subtitle: value ? l10n.settingsPostInfoOnTiles : l10n.settingsPostInfoImageOnly,
              value: value,
              onChanged: (v) => settings.showPostInfo.value = v,
            ),
          ),
          ValueListenableBuilder<String>(
            valueListenable: settings.postActionBarActions,
            builder: (context, rawActions, _) {
              final actions = PostActionPreferences.decode(rawActions);
              return CupertinoListTile(
                leading: const SettingsLeadingIcon(
                  icon: CupertinoIcons.square_stack_3d_down_right,
                  color: Color(0xFF1ABC9C),
                ),
                title: Text(l10n.settingsPostActionBar),
                subtitle: Text(l10n.settingsActionsPinned(actions.length)),
                trailing: const Icon(CupertinoIcons.chevron_forward, size: 18),
                onTap: () {
                  HapticFeedback.selectionClick();
                  _showPostActionBarEditor(context, settings);
                },
              );
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: settings.postActionBarFloatingMobile,
            builder: (context, value, _) => SettingsSwitchTile(
              leading: const SettingsLeadingIcon(
                icon: CupertinoIcons.rectangle_stack,
                color: Color(0xFF16A085),
              ),
              title: l10n.settingsActionBarPlacement,
              subtitle: value
                  ? l10n.settingsPlacementFloating
                  : l10n.settingsPlacementInline,
              value: value,
              onChanged: (enabled) =>
                  settings.postActionBarFloatingMobile.value = enabled,
            ),
          ),
        ],
      ),
    );
  }

  Widget _interactionsSection(Settings settings) {
    final l10n = AppLocalizations.of(context);
    return SettingsSection(
      title: l10n.settingsSectionInteractions,
      child: SettingsGroupCard(
        children: [
          if (!Platform.isIOS)
            ValueListenableBuilder<String?>(
              valueListenable: settings.downloadPath,
              builder: (context, value, _) => CupertinoListTile(
                leading: const SettingsLeadingIcon(
                  icon: CupertinoIcons.folder,
                  color: Color(0xFFF1C40F),
                ),
                title: Text(l10n.settingsDownloadLocation),
                subtitle: value != null
                    ? Text(Uri.decodeComponent(Uri.parse(value).path))
                    : Text(l10n.settingsChooseDirectory),
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
            builder: (context, value, _) => SettingsSwitchTile(
              leading: const SettingsLeadingIcon(
                icon: CupertinoIcons.arrow_up,
                color: Color(0xFF27AE60),
              ),
              title: l10n.settingsUpvoteFavorites,
              subtitle: value ? l10n.settingsUpvoteAndFav : l10n.settingsFavOnly,
              value: value,
              onChanged: (v) => settings.upvoteFavs.value = v,
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: settings.muteVideos,
            builder: (context, value, _) => SettingsSwitchTile(
              leading: SettingsLeadingIcon(
                icon: value
                    ? CupertinoIcons.speaker_slash
                    : CupertinoIcons.speaker_2,
                color: const Color(0xFF3498DB),
              ),
              title: l10n.settingsVideoVolume,
              subtitle: value ? l10n.settingsMuted : l10n.settingsWithSound,
              value: value,
              onChanged: (v) => settings.muteVideos.value = v,
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: settings.autoplayVideos,
            builder: (context, value, _) => SettingsSwitchTile(
              leading: const SettingsLeadingIcon(
                icon: CupertinoIcons.play_circle,
                color: Color(0xFF9B59B6),
              ),
              title: l10n.settingsAutoplayVideos,
              subtitle: value ? l10n.settingsPlayAutomatically : l10n.settingsPlayOnTap,
              value: value,
              onChanged: (v) => settings.autoplayVideos.value = v,
            ),
          ),
          ValueListenableBuilder<VideoResolution>(
            valueListenable: settings.videoResolution,
            builder: (context, value, _) => CupertinoListTile(
              leading: const SettingsLeadingIcon(
                icon: CupertinoIcons.videocam,
                color: Color(0xFF2ECC71),
              ),
              title: Text(l10n.settingsVideoResolution),
              subtitle: Text(value.title),
              trailing: const Icon(CupertinoIcons.chevron_forward, size: 18),
              onTap: () {
                HapticFeedback.selectionClick();
                _showPickerSheet<VideoResolution>(
                  context,
                  title: l10n.settingsVideoResolution,
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
          ValueListenableBuilder<bool>(
            valueListenable: settings.iFinishedEnabled,
            builder: (context, value, _) => SettingsSwitchTile(
              leading: const SettingsLeadingIcon(
                icon: CupertinoIcons.checkmark_circle,
                color: Color(0xFF1ABC9C),
              ),
              title: l10n.settingsIFinished,
              subtitle: value
                  ? l10n.settingsIFinishedDesc
                  : l10n.settingsIFinishedOff,
              value: value,
              onChanged: (v) => settings.iFinishedEnabled.value = v,
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: settings.iFinishedEnabled,
            builder: (context, enabled, _) {
              if (!enabled) return const SizedBox.shrink();
              final isMobile = Platform.isIOS || Platform.isAndroid;
              if (!isMobile) return const SizedBox.shrink();
              return ValueListenableBuilder<bool>(
                valueListenable: settings.iFinishedRequestPhoto,
                builder: (context, value, _) => SettingsSwitchTile(
                  leading: const SettingsLeadingIcon(
                    icon: CupertinoIcons.camera,
                    color: Color(0xFF9B59B6),
                  ),
                  title: l10n.settingsRequestPhoto,
                  subtitle: value
                      ? l10n.settingsRequestPhotoDesc
                      : l10n.settingsRequestPhotoOff,
                  value: value,
                  onChanged: (v) => settings.iFinishedRequestPhoto.value = v,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _securitySection(Settings settings) {
    final l10n = AppLocalizations.of(context);
    return SettingsSection(
      title: l10n.settingsSectionSecurity,
      child: SettingsGroupCard(
        children: [
          if (PlatformCapabilities.hasSecureDisplay)
            ValueListenableBuilder<bool>(
              valueListenable: settings.secureDisplay,
              builder: (context, value, _) => SettingsSwitchTile(
                leading: const SettingsLeadingIcon(
                  icon: CupertinoIcons.rectangle_on_rectangle_angled,
                  color: Color(0xFFE67E22),
                ),
                title: l10n.settingsSecureDisplay,
                subtitle: value ? l10n.settingsScreenProtected : l10n.settingsScreenVisible,
                value: value,
                onChanged: (v) => settings.secureDisplay.value = v,
              ),
            ),
          if (Platform.isAndroid)
            ValueListenableBuilder<bool>(
              valueListenable: settings.incognitoKeyboard,
              builder: (context, value, _) => SettingsSwitchTile(
                leading: const SettingsLeadingIcon(
                  icon: CupertinoIcons.keyboard,
                  color: Color(0xFF7F8C8D),
                ),
                title: l10n.settingsIncognitoKeyboard,
                subtitle: value ? l10n.commonEnabled : l10n.commonDisabled,
                value: value,
                onChanged: (v) => settings.incognitoKeyboard.value = v,
              ),
            ),
          ValueListenableBuilder<bool>(
            valueListenable: settings.allowHttpHosts,
            builder: (context, value, _) => SettingsSwitchTile(
              leading: const SettingsLeadingIcon(
                icon: CupertinoIcons.globe,
                color: Color(0xFF95A5A6),
              ),
              title: l10n.settingsAllowHttpHosts,
              subtitle: value
                  ? l10n.settingsAllowHttpDesc
                  : l10n.settingsHttpsOnly,
              value: value,
              onChanged: (v) => settings.allowHttpHosts.value = v,
            ),
          ),
          ValueListenableBuilder<String?>(
            valueListenable: settings.appPin,
            builder: (context, value, _) => SettingsSwitchTile(
              leading: const SettingsLeadingIcon(
                icon: CupertinoIcons.lock,
                color: Color(0xFF34495E),
              ),
              title: l10n.settingsPinLock,
              subtitle: value != null ? l10n.settingsPinEnabled : l10n.settingsPinDisabled,
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
                builder: (context, value, _) => SettingsSwitchTile(
                  leading: const SettingsLeadingIcon(
                    icon: CupertinoIcons.hand_raised,
                    color: Color(0xFF16A085),
                  ),
                  title: l10n.settingsBiometricLock,
                  subtitle: value
                      ? l10n.settingsBiometricsEnabled
                      : l10n.settingsBiometricsDisabled,
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

  Widget _developmentSectionWrapper({
    required Settings settings,
    required bool hasLogs,
  }) {
    return ValueListenableBuilder<bool>(
      valueListenable: settings.showDev,
      builder: (context, showDev, _) {
        if (!showDev) return const SizedBox.shrink();
        return _developmentSection(settings, hasLogs: hasLogs);
      },
    );
  }

  Widget _developmentSection(Settings settings, {required bool hasLogs}) {
              final l10n = AppLocalizations.of(context);
    return SettingsSection(
      title: l10n.settingsSectionDevelopment,
      child: SettingsGroupCard(
        children: [
          SettingsSwitchTile(
            leading: const SettingsLeadingIcon(
              icon: CupertinoIcons.ant,
              color: Color(0xFF8E44AD),
            ),
            title: l10n.settingsDeveloperMode,
            subtitle: l10n.settingsOptionsShown,
            value: true,
            onChanged: (v) => settings.showDev.value = v,
          ),
          if (hasLogs) ...[
            Consumer<Logs>(
              builder: (context, logs, _) => SubStream<List<LogRecord>>(
                create: () =>
                    logs.stream(filter: (level, type) => level >= Level.SEVERE),
                builder: (context, snapshot) => CupertinoListTile(
                  leading: const SettingsLeadingIcon(
                    icon: CupertinoIcons.list_number,
                    color: Color(0xFFD35400),
                  ),
                  title: Text(l10n.settingsLogs),
                  subtitle: (snapshot.data?.isNotEmpty ?? false)
                      ? Text(l10n.settingsErrorsLogged(snapshot.data!.length))
                      : null,
                  trailing: const Icon(
                    CupertinoIcons.chevron_forward,
                    size: 18,
                  ),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).push(
                      CupertinoPageRoute(builder: (_) => const LogsPage()),
                    );
                  },
                ),
              ),
            ),
            CupertinoListTile(
              leading: const SettingsLeadingIcon(
                icon: CupertinoIcons.square_stack_3d_up,
                color: Color(0xFF2C3E50),
              ),
              title: Text(l10n.settingsDatabase),
              trailing: const Icon(CupertinoIcons.chevron_forward, size: 18),
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (_) => const DatabaseManagementPage(),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  void _showPostActionBarEditor(BuildContext context, Settings settings) {
    final l10n = AppLocalizations.of(context);
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
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                            child: Text(
                              l10n.settingsPostActionBar,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                            child: Text(
                              l10n.settingsPinnedActions,
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
                                l10n.settingsAvailable,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ...available.map((action) {
                            final iFinishedDisabled =
                                action == PostActionId.iFinished &&
                                !settings.iFinishedEnabled.value;
                            return CupertinoListTile(
                              leading: Icon(
                                action.icon,
                                size: 20,
                                color: iFinishedDisabled
                                    ? CupertinoColors.systemGrey
                                    : null,
                              ),
                              title: Text(
                                action.label,
                                style: iFinishedDisabled
                                    ? TextStyle(
                                        color: CupertinoColors.systemGrey,
                                      )
                                    : null,
                              ),
                              trailing: Icon(
                                CupertinoIcons.plus_circle,
                                size: 20,
                                color: iFinishedDisabled
                                    ? CupertinoColors.systemGrey
                                    : null,
                              ),
                              onTap: iFinishedDisabled
                                  ? null
                                  : () {
                                      setSheetState(() {
                                        selected.add(action);
                                      });
                                      HapticFeedback.selectionClick();
                                    },
                            );
                          }),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(l10n.commonCancel),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: () {
                                  settings.postActionBarActions.value =
                                      PostActionPreferences.encode(selected);
                                  HapticFeedback.selectionClick();
                                  Navigator.of(context).pop();
                                },
                                child: Text(l10n.commonSave),
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

  void _showAccentColorSheet(BuildContext context, Settings settings) {
    final l10n = AppLocalizations.of(context);
    var selected = colorFromHex(settings.accentColorHex.value);

    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => SafeArea(
        top: false,
        child: StatefulBuilder(
          builder: (context, setSheetState) => GlassSurface(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            padding: const EdgeInsets.all(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 560),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                      child: Text(
                        l10n.settingsAccentColor,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _accentPresets.map((color) {
                        final isSelected =
                            hexFromColor(color) == hexFromColor(selected);
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setSheetState(() => selected = color);
                          },
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(context).dividerColor,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    ColorPicker(
                      pickerColor: selected,
                      onColorChanged: (value) {
                        setSheetState(() => selected = value.withAlpha(255));
                      },
                      colorPickerWidth: 300,
                      pickerAreaHeightPercent: 0.6,
                      enableAlpha: false,
                      displayThumbColor: true,
                      portraitOnly: true,
                      hexInputBar: false,
                      labelTypes: const [],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hexFromColor(selected),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(l10n.commonCancel),
                        ),
                        const SizedBox(width: 6),
                        TextButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            settings.accentColorHex.value =
                                defaultAccentColorHex;
                            Navigator.of(context).pop();
                          },
                          child: Text(l10n.commonReset),
                        ),
                        const SizedBox(width: 6),
                        FilledButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            settings.accentColorHex.value = hexFromColor(
                              selected,
                            );
                            Navigator.of(context).pop();
                          },
                          child: Text(l10n.commonSave),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
