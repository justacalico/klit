// SPDX-License-Identifier: AGPL-3.0

import 'package:kilt/logs/logs.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LogSelectionAppBar extends StatelessWidget with AppBarBuilderWidget {
  const LogSelectionAppBar({super.key, required this.child});

  @override
  final PreferredSizeWidget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SelectionAppBar<LogString>(
      child: child,
      titleBuilder: (context, data) => data.selections.length == 1
          ? Text(data.selections.first.body, maxLines: 1)
          : Text(l10n.logsLogsCount(data.selections.length)),
      actionBuilder: (context, data) => [
        IconButton(
          tooltip: l10n.commonCopy,
          icon: const Icon(Icons.copy),
          onPressed: () {
            Clipboard.setData(
              ClipboardData(
                text: data.selections.map((e) => e.toString()).join('\n'),
              ),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                duration: const Duration(seconds: 1),
                content: Text(l10n.commonCopiedToClipboard),
              ),
            );
            data.onChanged({});
          },
        ),
      ],
    );
  }
}

class LogFileSelectionAppBar extends StatelessWidget with AppBarBuilderWidget {
  const LogFileSelectionAppBar({super.key, required this.child, this.onDelete});

  @override
  final PreferredSizeWidget child;
  final ValueSetter<List<LogFileInfo>>? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SelectionAppBar<LogFileInfo>(
      child: child,
      titleBuilder: (context, data) => data.selections.length == 1
          ? Text(l10n.logsLogsDate(data.selections.first.date))
          : Text(l10n.logsLogFilesCount(data.selections.length)),
      actionBuilder: (context, data) => [
        if (onDelete != null)
          IconButton(
            tooltip: l10n.commonDelete,
            icon: const Icon(Icons.delete),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => LogFileDeleteConfirmation(
                files: data.selections.toList(),
                onConfirm: () {
                  onDelete?.call(data.selections.toList());
                  data.onChanged({});
                },
              ),
            ),
          ),
      ],
    );
  }
}

class LogFileDeleteConfirmation extends StatelessWidget {
  const LogFileDeleteConfirmation({
    super.key,
    required this.files,
    required this.onConfirm,
  });

  final List<LogFileInfo> files;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.logsDeleteFilesTitle(files.length)),
      content: Text(l10n.logsCannotUndone),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () {
            onConfirm?.call();
            Navigator.of(context).pop();
          },
          child: Text(l10n.commonDelete),
        ),
      ],
    );
  }
}
