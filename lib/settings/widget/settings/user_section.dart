part of '../settings.dart';

Widget buildUserSection(BuildContext context) {
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
