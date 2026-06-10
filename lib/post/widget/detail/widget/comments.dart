import 'package:kilt/comment/comment.dart';
import 'package:kilt/post/post.dart';
import 'package:kilt/shared/shared.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CommentDisplay extends StatelessWidget {
  const CommentDisplay({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;
    return Column(
      children: [
        GlassCard(
          margin: const EdgeInsets.only(top: 10),
          padding: EdgeInsets.zero,
          borderRadius: 12,
          child: SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                final width = MediaQuery.sizeOf(context).width;
                if (width < 900) {
                  showPostCommentsDrawer(context, postId: post.id);
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PostCommentsPage(postId: post.id),
                    ),
                  );
                }
              },
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.comment_outlined, size: 18, color: textColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Comments (${post.commentCount})',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_forward,
                    size: 16,
                    color: textColor?.withValues(alpha: 0.8),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
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
