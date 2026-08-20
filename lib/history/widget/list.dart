// SPDX-License-Identifier: AGPL-3.0

import 'package:kilt/history/history.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:grouped_list/grouped_list.dart';

class HistoryList extends StatelessWidget {
  const HistoryList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryController>(
      builder: (context, controller, child) => LimitedWidthLayout(
        child: PullToRefresh(
          onRefresh: () => controller.refresh(force: true, background: true),
          child: CustomScrollView(
            primary: true,
            scrollCacheExtent: ScrollCacheExtent.pixels(400),
            slivers: [
              SliverPadding(
                padding: defaultActionListPadding,
                sliver: const SliverHistoryList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SliverHistoryList extends StatelessWidget {
  const SliverHistoryList({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Consumer<HistoryController>(
      builder: (context, controller, child) => SliverPadding(
        padding:
            LimitedWidthLayout.maybeOf(context)?.padding ?? EdgeInsets.zero,
        sliver: ListenableBuilder(
          listenable: controller,
          builder: (context, _) =>
              PagedSliverGroupedListView<int, History, DateTime>(
                state: controller.state,
                fetchNextPage: controller.getNextPage,
                order: GroupedListOrder.DESC,
                groupBy: (element) => DateUtils.dateOnly(element.visitedAt),
                groupHeaderBuilder: (element) => ListTileHeader(
                  title: DateFormatting.named(element.visitedAt, context),
                ),
                itemComparator: (a, b) => a.visitedAt.compareTo(b.visitedAt),
                builderDelegate: defaultPagedChildBuilderDelegate<History>(
                  onRetry: controller.getNextPage,
                  onEmpty: Text(l10n.historyYourHistoryEmpty),
                  onError: Text(l10n.historyFailedLoad),
                  itemBuilder: (context, item, index) => RepaintBoundary(
                    key: ValueKey(item.id),
                    child: HistoryTile(entry: item),
                  ),
                ),
              ),
        ),
      ),
    );
  }
}
