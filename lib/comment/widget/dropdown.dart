import 'package:klit/client/client.dart';
import 'package:klit/comment/comment.dart';
import 'package:klit/shared/shared.dart';
import 'package:flutter/material.dart';

class CommentListDropdown extends StatelessWidget {
  const CommentListDropdown({super.key, this.postId});

  final int? postId;

  @override
  Widget build(BuildContext context) {
    return Consumer<CommentController>(
      builder: (context, controller, child) => PopupMenuButton<VoidCallback>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) => value(),
        itemBuilder: (context) => [
          PopupMenuTile(
            title: 'Refresh',
            icon: Icons.refresh,
            value: () => controller.refresh(force: true),
          ),
          PopupMenuTile(
            icon: Icons.sort,
            title: controller.orderByOldest ? 'Newest first' : 'Oldest first',
            value: () => controller.orderByOldest = !controller.orderByOldest,
          ),
          if (postId case final postId?)
            PopupMenuTile(
              title: 'Comment',
              icon: Icons.comment,
              value: () => guardWithLogin(
                context: context,
                callback: () async {
                  bool success = await writeComment(
                    context: context,
                    postId: postId,
                  );
                  if (success) {
                    controller.refresh(force: true);
                  }
                },
                error: 'You must be logged in to comment!',
              ),
            ),
        ],
      ),
    );
  }
}
