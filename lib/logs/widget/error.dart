// SPDX-License-Identifier: AGPL-3.0

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sub/flutter_sub.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/logs/logs.dart';

class LoggerErrorNotifier extends StatelessWidget {
  const LoggerErrorNotifier({
    super.key,
    required this.child,
    required this.logs,
    this.onOpenLogs,
  });

  final Widget child;
  final Logs logs;
  final VoidCallback? onOpenLogs;

  void onMessage(BuildContext context, List<LogRecord> event) {
    if (kReleaseMode) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    if (event.isEmpty) return;
    final item = event.last;
    if (item.level == Level.SHOUT) {
      final background = item.level.color;
      try {
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 3),
            content: Builder(
              builder: (context) {
                final style = Theme.of(context).textTheme.bodyMedium!;
                var textColor =
                    style.color ?? Theme.of(context).colorScheme.onSurface;
                final textLuminance = textColor.computeLuminance();
                final colorDifference =
                    background.computeLuminance() - textLuminance;
                if (colorDifference.abs() < 0.2) {
                  if (textLuminance > 0.5) {
                    textColor = ThemeData(
                      brightness: Brightness.light,
                    ).textTheme.titleMedium!.color!;
                  } else {
                    textColor = ThemeData(
                      brightness: Brightness.dark,
                    ).textTheme.titleMedium!.color!;
                  }
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.logsCriticalError,
                      style: style.copyWith(color: textColor),
                    ),
                    Text(
                      item.message,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: style.copyWith(color: textColor),
                    ),
                  ],
                );
              },
            ),
            backgroundColor: background,
            behavior: SnackBarBehavior.floating,
            action: onOpenLogs != null
                ? SnackBarAction(label: l10n.logsLogs, onPressed: onOpenLogs!)
                : null,
          ),
        );
      }
      // this is necessary, as there is no way to check whether a [Scaffold] is attached to a [ScaffoldMessenger].
      // If we do not check and the application has an error on boot, it will get stuck in an endless error loop.
      // ignore: avoid_catching_errors
      on Error catch (e) {
        if (!e.toString().contains(
          'ScaffoldMessenger.showSnackBar was called, but there are currently no descendant Scaffolds to present to',
        )) {
          rethrow;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) => SubStream<List<LogRecord>>(
    create: () => logs.stream(),
    listener: (e) => onMessage(context, e),
    keys: [logs],
    builder: (context, value) => child,
  );
}
