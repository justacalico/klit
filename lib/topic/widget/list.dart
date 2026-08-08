import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/reply/reply.dart';
import 'package:kilt/shared/shared.dart';
import 'package:kilt/topic/topic.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class TopicList extends StatelessWidget {
  const TopicList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TopicController>(
      builder: (context, controller, child) => PullToRefresh(
        onRefresh: () => controller.refresh(force: true, background: true),
        child: CustomScrollView(
          primary: true,
          scrollCacheExtent: ScrollCacheExtent.pixels(400),
          slivers: [
            SliverPadding(
              padding: defaultActionListPadding,
              sliver: const SliverTopicList(),
            ),
          ],
        ),
      ),
    );
  }
}

class SliverTopicList extends StatelessWidget {
  const SliverTopicList({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    void pushReplies(Topic topic, {bool orderByOldest = true}) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TopicRepliesPage(
            topic: topic,
            orderByOldest: orderByOldest,
          ),
        ),
      );
    }

    return Consumer<TopicController>(
      builder: (context, controller, child) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) => PagedSliverList<int, Topic>(
          state: controller.state,
          fetchNextPage: controller.getNextPage,
          builderDelegate: defaultPagedChildBuilderDelegate(
            onRetry: controller.getNextPage,
            itemBuilder: (context, topic, index) => RepaintBoundary(
              key: ValueKey(topic.id),
              child: TopicTile(
                topic: topic,
                onPressed: () => pushReplies(topic),
                onCountPressed: () => pushReplies(topic, orderByOldest: false),
              ),
            ),
            onEmpty: Text(l10n.topicNoTopics),
            onError: Text(l10n.topicFailedLoad),
          ),
        ),
      ),
    );
  }
}
