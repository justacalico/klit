import 'package:klit/comment/comment.dart';
import 'package:klit/post/post.dart';
import 'package:klit/shared/shared.dart';
import 'package:flutter/material.dart';

class CommentDisplay extends StatelessWidget {
  const CommentDisplay({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    if (post.commentCount <= 0) return const SizedBox();
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PostCommentsPage(postId: post.id),
                  ),
                ),
                style: ButtonStyle(
                  foregroundColor: WidgetStateProperty.all(
                    Theme.of(context).textTheme.bodyMedium!.color,
                  ),
                  overlayColor: WidgetStateProperty.all(
                    Theme.of(context).splashColor,
                  ),
                ),
                child: Text(
                  'COMMENTS'
                  ' (${post.commentCount})',
                ),
              ),
            ),
          ],
        ),
        const Divider(),
      ],
    );
  }
}

class SliverPostCommentSection extends StatelessWidget {
  const SliverPostCommentSection({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return CommentProvider(
      postId: post.id,
      child: Consumer<CommentController>(
        builder: (context, controller, child) => SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Comments',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          CommentListDropdown(postId: post.id),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
              ).add(const EdgeInsets.only(bottom: 30)),
              sliver: const SliverCommentList(),
            ),
          ],
        ),
      ),
    );
  }
}
