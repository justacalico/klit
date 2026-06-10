import 'package:kilt/history/history.dart';
import 'package:kilt/shared/shared.dart';
import 'package:flutter/material.dart';
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
            cacheExtent: 400,
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
                  title: DateFormatting.named(element.visitedAt),
                ),
                itemComparator: (a, b) => a.visitedAt.compareTo(b.visitedAt),
                builderDelegate: defaultPagedChildBuilderDelegate<History>(
                  onRetry: controller.getNextPage,
                  onEmpty: const Text('Your history is empty'),
                  onError: const Text('Failed to load history'),
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
