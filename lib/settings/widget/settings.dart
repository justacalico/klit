// SPDX-License-Identifier: AGPL-3.0

import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart'
    show ColorPicker, PaletteType;
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Consumer;
import 'package:flutter_sub/flutter_sub.dart';
import 'package:go_router/go_router.dart';
import 'package:kilt/app/app.dart';
import 'package:kilt/app/routing/app_routes.dart';
import 'package:kilt/client/client.dart';
import 'package:kilt/follow/follow.dart';
import 'package:kilt/identity/identity.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/logs/logs.dart';
import 'package:kilt/settings/settings.dart';
import 'package:kilt/settings/widget/settings_shared.dart';
import 'package:kilt/shared/shared.dart';
import 'package:kilt/traits/traits.dart';
import 'package:kilt/user/user.dart';
import 'package:local_auth/local_auth.dart';
part 'settings/accounts_section.dart';
part 'settings/user_section.dart';
part 'settings/appearance_section.dart';
part 'settings/interactions_section.dart';
part 'settings/security_section.dart';
part 'settings/development_section.dart';
part 'settings/post_action_bar_editor.dart';
part 'settings/picker_sheet.dart';
part 'settings/accent_color_sheet.dart';


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
          final contentPadding = const EdgeInsets.fromLTRB(
            16,
            12,
            16,
            defaultActionListBottomHeight,
          ).add(LimitedWidthLayout.of(context).padding);

          final hasLogs = context.read<Logs?>() != null;
          final sections = <SettingsSectionEntry>[
            SettingsSectionEntry(weight: 7, child: buildAccountsSection(context, _accountsSectionKey)),
            SettingsSectionEntry(weight: 4, child: buildUserSection(context)),
            SettingsSectionEntry(
              weight: 7,
              child: buildAppearanceSection(context, settings, _accentPresets),
            ),
            SettingsSectionEntry(
              weight: 5,
              child: buildInteractionsSection(context, settings),
            ),
            SettingsSectionEntry(
              weight: 5,
              child: buildSecuritySection(context, settings),
            ),
            SettingsSectionEntry(
              weight: 4,
              child: buildDevelopmentSectionWrapper(
                settings: settings,
                hasLogs: hasLogs,
              ),
            ),
            const SettingsSectionEntry(weight: 3, child: SettingsAboutSection()),
          ];

          return LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop =
                  constraints.maxWidth >= SettingsPage._desktopBreakpoint;

              return ColoredBox(
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

}
