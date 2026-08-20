// SPDX-License-Identifier: AGPL-3.0

import 'package:kilt/client/client.dart';
import 'package:kilt/history/history.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sub/flutter_sub.dart';
import 'package:intl/intl.dart';

class HistoryEnableTile extends StatelessWidget {
  const HistoryEnableTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final client = context.watch<Client>();
    return SubStream<int>(
      create: () => client.histories.count().streamed,
      keys: [client],
      builder: (context, countSnapshot) => ValueListenableBuilder(
        valueListenable: client.traits,
        builder: (context, traits, child) => SwitchListTile(
          title: Text(l10n.historyEnabled),
          subtitle: Text(l10n.historyPagesVisited(countSnapshot.data ?? 0)),
          secondary: const Icon(Icons.history),
          value: traits.writeHistory ?? true,
          onChanged: (value) => client.traits.value = client.traits.value
              .copyWith(writeHistory: value),
        ),
      ),
    );
  }
}

class HistoryClearTile extends StatelessWidget {
  const HistoryClearTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final client = context.watch<Client>();
    return ListTile(
      title: Text(l10n.historyClearHistory),
      subtitle: Text(l10n.historyDeleteAllEntries),
      leading: const Icon(Icons.clear_all),
      onTap: () => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.historyClearHistoryTitle),
          content: Text(
            l10n.historyClearHistoryBody,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                client.histories.removeAll(null);
              },
              child: Text(l10n.commonClear),
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryLimitTile extends StatelessWidget {
  const HistoryLimitTile({super.key});

  static const int trimAmount = 5000;
  static const Duration trimAge = Duration(days: 30 * 3);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final client = context.watch<Client>();
    return ValueListenableBuilder(
      valueListenable: client.traits,
      builder: (context, traits, child) => SwitchListTile(
        value: traits.trimHistory ?? false,
        onChanged: (value) {
          if (value) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(l10n.historyHistoryLimit),
                content: Text(
                  l10n.historyHistoryLimitBody(
                    NumberFormat.compact().format(trimAmount),
                    trimAge.inDays ~/ 30,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(l10n.commonCancelUpper),
                  ),
                  TextButton(
                    onPressed: () {
                      client.traits.value = client.traits.value.copyWith(
                        trimHistory: value,
                      );
                      Navigator.of(context).maybePop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          } else {
            client.traits.value = client.traits.value.copyWith(
              trimHistory: value,
            );
          }
        },
        secondary: Icon(
          (traits.trimHistory ?? false)
              ? Icons.hourglass_bottom
              : Icons.hourglass_empty,
        ),
        title: Text(l10n.historyLimitHistory),
        subtitle: (traits.trimHistory ?? false)
            ? Text(
                l10n.historyLimitedTo(
                  trimAge.inDays ~/ 30,
                  NumberFormat.compact().format(trimAmount),
                ),
              )
            : Text(l10n.historyInfinite),
      ),
    );
  }
}

class HistoryCategoryFilterTile extends StatelessWidget {
  const HistoryCategoryFilterTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Consumer<HistoryController>(
      builder: (context, controller, child) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: ListTileHeader(title: l10n.historyEntries),
          ),
          for (final filter in HistoryCategory.values)
            AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                HistoryQuery query = HistoryQuery.from(controller.search);
                return Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: CheckboxListTile(
                    secondary: filter.icon,
                    title: Text(filter.title),
                    value: query.categories?.contains(filter) ?? true,
                    onChanged: (value) {
                      if (value == null) return;
                      Set<HistoryCategory> filters =
                          query.categories ?? HistoryCategory.values.toSet();
                      if (value) {
                        filters.add(filter);
                      } else {
                        filters.remove(filter);
                      }
                      controller.search = query.copy()..categories = filters;
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class HistoryTypeFilterTile extends StatelessWidget {
  const HistoryTypeFilterTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Consumer<HistoryController>(
      builder: (context, controller, child) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: ListTileHeader(title: l10n.commonType),
          ),
          for (final filter in HistoryType.values)
            AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                HistoryQuery query = HistoryQuery.from(controller.search);
                return Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: CheckboxListTile(
                    secondary: filter.icon,
                    title: Text(filter.title),
                    value: query.types?.contains(filter) ?? true,
                    onChanged: (value) {
                      if (value == null) return;
                      Set<HistoryType> filters =
                          query.types ?? HistoryType.values.toSet();
                      if (value) {
                        filters.add(filter);
                      } else {
                        filters.remove(filter);
                      }
                      controller.search = query.copy()..types = filters;
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
