import 'dart:async';

import 'package:klit/app/app.dart';
import 'package:klit/settings/settings.dart';
import 'package:klit/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
        final messenger = ScaffoldMessenger.of(context);
        reset?.cancel();
        setState(() => taps++);
        if (taps == 7) {
          messenger.clearSnackBars();
          messenger.showSnackBar(
            const SnackBar(
              duration: Duration(seconds: 2),
              content: Text('You are now a developer!'),
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
                  'A newer version is available: ',
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
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => openDownload(),
            child: const Text('DOWNLOAD'),
          ),
        ],
      );
    }

    return FutureBuilder<List<AppVersion>?>(
      future: newVersions,
      builder: (context, snapshot) {
        String message;
        Widget icon;
        VoidCallback? onTap;
        if (snapshot.connectionState != ConnectionState.done) {
          message = 'Fetching updates...';
          icon = const FaIcon(FontAwesomeIcons.clockRotateLeft);
        } else if (snapshot.data == null) {
          message = 'Failed to check for updates';
          onTap = () {
            HapticFeedback.selectionClick();
            openDownload();
          };
          icon = const FaIcon(FontAwesomeIcons.circleExclamation);
        } else if (snapshot.data!.isEmpty) {
          message = 'You have the newest version';
          icon = const FaIcon(FontAwesomeIcons.clockRotateLeft);
        } else {
          message =
              'A newer version is available: ${snapshot.data!.first.version}';
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
                  title: const Text('Version'),
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
            title: const Text('Website'),
            link: 'https://',
            extra: appInfo.website,
          ),
      ],
    );
  }
}
