import 'package:kilt/comment/comment.dart';
import 'package:kilt/shared/shared.dart';
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
        ],
      ),
    );
  }
}
