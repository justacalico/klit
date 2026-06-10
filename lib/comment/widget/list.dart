import 'package:kilt/comment/comment.dart';
import 'package:kilt/shared/shared.dart';
import 'package:flutter/material.dart';

class CommentList extends StatelessWidget {
  const CommentList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CommentController>(
      builder: (context, controller, child) => PullToRefresh(
        onRefresh: () => controller.refresh(force: true, background: true),
        child: CustomScrollView(
          primary: true,
          cacheExtent: 400,
          slivers: [
            SliverPadding(
              padding: defaultActionListPadding,
              sliver: const SliverCommentList(),
            ),
          ],
        ),
      ),
    );
  }
}

class SliverCommentList extends StatelessWidget {
  const SliverCommentList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CommentController>(
      builder: (context, controller, child) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) => PagedSliverList<int, Comment>(
          state: controller.state,
          fetchNextPage: controller.getNextPage,
          builderDelegate: defaultPagedChildBuilderDelegate(
            onRetry: controller.getNextPage,
            itemBuilder: (context, item, index) => RepaintBoundary(
            key: ValueKey(item.id),
            child: CommentTile(comment: item),
          ),
            onEmpty: const Text('No comments'),
            onError: const Text('Failed to load comments'),
          ),
        ),
      ),
    );
  }
}
