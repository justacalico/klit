part of '../settings.dart';

Widget buildDevelopmentSectionWrapper({
  required Settings settings,
  required bool hasLogs,
}) {
  return ValueListenableBuilder<bool>(
    valueListenable: settings.showDev,
    builder: (context, showDev, _) {
      if (!showDev) return const SizedBox.shrink();
      return buildDevelopmentSection(context, settings: settings, hasLogs: hasLogs);
    },
  );
}

Widget buildDevelopmentSection(BuildContext context, {required Settings settings, required bool hasLogs}) {
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
