// SPDX-License-Identifier: AGPL-3.0

import 'package:kilt/client/client.dart';
import 'package:kilt/history/history.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/shared/shared.dart';
import 'package:flutter/material.dart';

class HistoryAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HistoryAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Consumer<HistoryController>(
      builder: (context, controller, child) => HistorySelectionAppBar(
        child: DefaultAppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.historyHistory),
              CrossFade.builder(
                showChild: HistoryQuery.from(controller.search).date != null,
                builder: (context) => Text(
                  DateFormatting.named(
                    HistoryQuery.from(controller.search).date!,
                    context,
                  ),
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).textTheme.bodySmall!.color,
                  ),
                ),
              ),
            ],
          ),
          actions: const [ContextDrawerButton()],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class HistorySelectionAppBar extends StatelessWidget with AppBarBuilderWidget {
  const HistorySelectionAppBar({super.key, required this.child});

  @override
  final PreferredSizeWidget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SelectionAppBar<History>(
      child: child,
      titleBuilder: (context, data) => data.selections.length == 1
          ? Text(data.selections.first.getName(context))
          : Text(l10n.historyEntriesCount(data.selections.length)),
      actionBuilder: (context, data) => [
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            data.onChanged({});
            await context.read<Client>().histories.removeAll(
              data.selections.map((e) => e.id).toList(),
            );
          },
        ),
      ],
    );
  }
}
