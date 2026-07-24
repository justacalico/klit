import 'package:kilt/comment/comment.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/shared/shared.dart';
import 'package:flutter/material.dart';

class CommentListDrawer extends StatelessWidget {
  const CommentListDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Consumer<CommentController>(
      builder: (context, controller, child) => ContextDrawer(
        title: Text(l10n.postComments),
        children: [
          AnimatedBuilder(
            animation: controller,
            builder: (context, child) => SwitchListTile(
              secondary: const Icon(Icons.sort),
              title: Text(l10n.commentCommentOrder),
              subtitle: Text(
                controller.orderByOldest ? l10n.commentOldestFirst : l10n.commentNewestFirst,
              ),
              value: controller.orderByOldest,
              onChanged: (value) {
                controller.orderByOldest = value;
                Scaffold.of(context).closeEndDrawer();
              },
            ),
          ),
        ],
      ),
    );
  }
}
