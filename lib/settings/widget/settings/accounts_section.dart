part of '../settings.dart';

Widget buildAccountsSection(BuildContext context, GlobalKey accountsSectionKey) {
  final l10n = AppLocalizations.of(context);
  return SettingsSection(
    key: accountsSectionKey,
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
