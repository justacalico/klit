import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/reply/reply.dart';
import 'package:kilt/shared/shared.dart';
import 'package:flutter/material.dart';

class ReplyListDrawer extends StatelessWidget {
  const ReplyListDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Consumer<ReplyController>(
      builder: (context, controller, child) => ContextDrawer(
        title: Text(l10n.replyReplies),
        children: [
          AnimatedBuilder(
            animation: controller,
            builder: (context, child) => SwitchListTile(
              secondary: const Icon(Icons.sort),
              title: Text(l10n.replyOrder),
              subtitle: Text(
                controller.orderByOldest ? l10n.commentOldestFirst : l10n.commentNewestFirst,
              ),
              value: controller.orderByOldest,
              onChanged: (value) {
                controller.orderByOldest = value;
                Navigator.of(context).maybePop();
              },
            ),
          ),
        ],
      ),
    );
  }
}
