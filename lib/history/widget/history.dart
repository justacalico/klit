import 'package:kilt/client/client.dart';
import 'package:kilt/history/history.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/shared/shared.dart';
import 'package:flutter/material.dart';

class HistoriesPage extends StatelessWidget {
  const HistoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SubChangeNotifierProvider<Client, HistoryController>(
      create: (context, client) => HistoryController(client: client),
      child: Consumer<HistoryController>(
        builder: (context, controller, child) => SelectionLayout<History>(
          items: controller.items,
          child: AdaptiveScaffold(
            appBar: HistoryAppBar(),
            floatingActionButton: HistorySearchFab(),
            endDrawer: ContextDrawer(
              title: Text(l10n.historyHistory),
              children: [
                HistoryEnableTile(),
                HistoryLimitTile(),
                HistoryClearTile(),
                Divider(),
                HistoryCategoryFilterTile(),
                HistoryTypeFilterTile(),
              ],
            ),
            body: HistoryList(),
          ),
        ),
      ),
    );
  }
}
