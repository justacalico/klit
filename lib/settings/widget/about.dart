import 'dart:async';

import 'package:kilt/app/app.dart';
import 'package:kilt/settings/settings.dart';
import 'package:kilt/settings/widget/settings_shared.dart';
import 'package:kilt/shared/shared.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';

class DevOptionEnabler extends StatefulWidget {
  const DevOptionEnabler({super.key, required this.child});

  final Widget child;

  @override
  State<DevOptionEnabler> createState() => _DevOptionEnablerState();
}

class _DevOptionEnablerState extends State<DevOptionEnabler> {
  int taps = 0;
  Timer? reset;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        final l10n = AppLocalizations.of(context);
        final messenger = ScaffoldMessenger.of(context);
        reset?.cancel();
        setState(() => taps++);
        if (taps == 7) {
          messenger.clearSnackBars();
          messenger.showSnackBar(
            SnackBar(
              duration: Duration(seconds: 2),
              content: Text(l10n.aboutDevEnabled),
            ),
          );
          context.read<Settings>().showDev.value = true;
          taps = 0;
        }
        reset = Timer(const Duration(seconds: 2), () {
          if (!mounted) return;
          setState(() => taps = 0);
        });
      },
      child: widget.child,
    );
  }
}

class AboutVersion extends StatelessWidget {
  // ignore: unused_element
  const AboutVersion({super.key, required this.newVersions});

  final Future<List<AppVersion>>? newVersions;

  @override
  Widget build(BuildContext context) {
    Future<void> openDownload() async {
      AppInfoClient? updater = context.read<AppInfoClient?>();
      if (updater == null) return;
      final url = await updater.getDownloadUrl();
      if (url != null && context.mounted) launch(url);
    }

    Widget changesDialog(List<AppVersion> versions) {
      final l10n = AppLocalizations.of(context);
      return AlertDialog(
        title: Text(AppInfo.instance.appName),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 400),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.aboutNewerVersionAvailablePrefix,
                  style: TextStyle(color: dimTextColor(context, 0.5)),
                ),
                ...versions
                    .map(
                      (release) => [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            '${release.name} (${release.version})',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        Text(release.description!),
                      ],
                    )
                    .reduce((a, b) => [...a, ...b]),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).maybePop,
            child: Text(l10n.commonCancelUpper),
          ),
          TextButton(
            onPressed: () => openDownload(),
            child: Text(l10n.commonDownloadUpper),
          ),
        ],
      );
    }

    return FutureBuilder<List<AppVersion>?>(
      future: newVersions,
      builder: (context, snapshot) {
        final l10n = AppLocalizations.of(context);
        String message;
        Widget icon;
        VoidCallback? onTap;
        if (snapshot.connectionState != ConnectionState.done) {
          message = l10n.aboutFetchingUpdates;
          icon = const FaIcon(FontAwesomeIcons.clockRotateLeft);
        } else if (snapshot.data == null) {
          message = l10n.aboutFailedCheckUpdates;
          onTap = () {
            HapticFeedback.selectionClick();
            openDownload();
          };
          icon = const FaIcon(FontAwesomeIcons.circleExclamation);
        } else if (snapshot.data!.isEmpty) {
          message = l10n.aboutNewestVersion;
          icon = const FaIcon(FontAwesomeIcons.clockRotateLeft);
        } else {
          message = l10n.aboutNewerVersionAvailable(
            snapshot.data!.first.version,
          );
          onTap = () {
            HapticFeedback.selectionClick();
            showDialog(
              context: context,
              builder: (context) => changesDialog(snapshot.data!),
            );
          };
          icon = const FaIcon(FontAwesomeIcons.download);
        }

        return Column(
          children: [
            Stack(
              fit: StackFit.passthrough,
              children: [
                ListTile(
                  leading: icon,
                  title: Text(l10n.aboutVersionTitle),
                  subtitle: Text(message),
                  onTap: onTap,
                ),
                if (snapshot.data?.isNotEmpty ?? false)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      height: 10,
                      width: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(),
          ],
        );
      },
    );
  }
}

class AboutLinks extends StatelessWidget {
  const AboutLinks({super.key});

  @override
  Widget build(BuildContext context) {
    AppInfo appInfo = AppInfo.instance;
    final l10n = AppLocalizations.of(context);

    Widget linkListTile({
      Widget? leading,
      required Widget title,
      required String link,
      String? extra,
    }) {
      return ListTile(
        leading: leading,
        title: title,
        subtitle: Text(extra ?? link),
        onTap: () {
          HapticFeedback.selectionClick();
          launch(link + (extra ?? ''));
        },
      );
    }

    return Column(
      children: [
        if (appInfo.website != null)
          linkListTile(
            leading: const FaIcon(FontAwesomeIcons.house),
            title: Text(l10n.aboutWebsiteTitle),
            link: 'https://',
            extra: appInfo.website,
          ),
      ],
    );
  }
}

class SettingsAboutSection extends StatelessWidget {
  const SettingsAboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsSection(
      title: l10n.aboutSectionTitle,
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
                        const SizedBox(height: 12),
                        const _CheckForUpdateButton(),
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

class _CheckForUpdateButton extends StatefulWidget {
  const _CheckForUpdateButton();

  @override
  State<_CheckForUpdateButton> createState() => _CheckForUpdateButtonState();
}

class _CheckForUpdateButtonState extends State<_CheckForUpdateButton> {
  bool _loading = false;

  Future<void> _checkForUpdate(BuildContext context) async {
    final updater = context.read<AppInfoClient?>();
    if (updater == null) return;
    if (_loading) return;
    setState(() => _loading = true);
      final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final newVersions = await updater.getNewVersions(force: true);
      if (!context.mounted) return;
      setState(() => _loading = false);
      if (newVersions.isEmpty) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.aboutNewestVersion)),
        );
      } else {
        final latest = newVersions.first;
        final showDownload = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppInfo.instance.appName),
            content: Text(
              '${l10n.aboutNewerVersionAvailable(latest.version)}\n\n'
              '${latest.date != null ? "Released ${latest.date!.toString().split(' ').first}" : ""}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.commonLaterUpper),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.commonDownloadUpper),
              ),
            ],
          ),
        );
        if (showDownload == true && context.mounted) {
          final url = await updater.getDownloadUrl();
          if (url != null) launch(url);
        }
      }
    } catch (_) {
      if (context.mounted) {
        setState(() => _loading = false);
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.aboutFailedCheckUpdates)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final updater = context.read<AppInfoClient?>();
    if (updater == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final onTop = theme.colorScheme.onSurface;
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _loading ? null : () => _checkForUpdate(context),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(
                _loading ? CupertinoIcons.arrow_2_circlepath : CupertinoIcons.arrow_down_circle,
                size: 22,
                color: _loading ? onTop.withValues(alpha: 0.5) : onTop,
              ),
              const SizedBox(width: 12),
              Text(
                _loading ? l10n.aboutCheckingForUpdates : l10n.aboutCheckForUpdate,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: _loading ? onTop.withValues(alpha: 0.7) : onTop,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
