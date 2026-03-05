import 'package:klit/client/client.dart';
import 'package:klit/comment/comment.dart';
import 'package:klit/shared/shared.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PostCommentsPage extends StatelessWidget {
  const PostCommentsPage({super.key, required this.postId});

  final int postId;

  @override
  Widget build(BuildContext context) {
    final client = context.watch<Client>();
    return CommentProvider(
      postId: postId,
      child: AdaptiveScaffold(
        appBar: DefaultAppBar(
          title: Text('#$postId comments'),
          actions: const [ContextDrawerButton()],
        ),
        floatingActionButton: client.hasLogin
            ? CommentCreateFab(postId: postId)
            : null,
        endDrawer: const CommentListDrawer(),
        body: const CommentList(),
      ),
    );
  }
}

Future<void> showPostCommentsDrawer(
  BuildContext context, {
  required int postId,
}) {
  final theme = Theme.of(context);
  final surface = theme.brightness == Brightness.dark
      ? Color.lerp(theme.canvasColor, Colors.white, 0.06)!
      : theme.colorScheme.surface;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return CommentProvider(
        postId: postId,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          minChildSize: 0.65,
          maxChildSize: 0.97,
          builder: (context, scrollController) {
            return DecoratedBox(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 4, 4),
                      child: Row(
                        children: [
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '#$postId comments',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Consumer<CommentController>(
                            builder: (context, controller, _) => IconButton(
                              tooltip: controller.orderByOldest
                                  ? 'Oldest first'
                                  : 'Newest first',
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                controller.orderByOldest =
                                    !controller.orderByOldest;
                              },
                              icon: Icon(
                                controller.orderByOldest
                                    ? CupertinoIcons.sort_down
                                    : CupertinoIcons.sort_up,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(CupertinoIcons.xmark),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: PullToRefresh(
                        onRefresh: () => context
                            .read<CommentController>()
                            .refresh(force: true, background: true),
                        child: CustomScrollView(
                          controller: scrollController,
                          slivers: [
                            SliverPadding(
                              padding: defaultActionListPadding,
                              sliver: const SliverCommentList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Consumer<Client>(
                      builder: (context, client, _) {
                        if (!client.hasLogin) return const SizedBox(height: 6);
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                writeComment(
                                  context: context,
                                  postId: postId,
                                ).then((sent) {
                                  if (sent) {
                                    context.read<CommentController>().refresh(
                                      force: true,
                                    );
                                  }
                                });
                              },
                              icon: const Icon(CupertinoIcons.chat_bubble_text),
                              label: const Text('Add comment'),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
  );
}
