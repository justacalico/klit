import 'package:kilt/app/routing/app_routes.dart';
import 'package:kilt/comment/comment.dart';
import 'package:kilt/markup/markup.dart';
import 'package:kilt/reply/reply.dart';
import 'package:kilt/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ReplyTile extends StatelessWidget {
  const ReplyTile({super.key, required this.reply});

  final Reply reply;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Hero(
            tag: reply.hero,
            child: Material(
              type: MaterialType.transparency,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8, top: 4),
                    child: CommenterAvatar(userId: reply.creatorId, radius: 16),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ReplyHeader(reply: reply),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [Expanded(child: DText(reply.body))],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          ReplyWarning(reply: reply),
          const SizedBox(height: 8),
          const Divider(),
        ],
      ),
    );
  }
}

class ReplyHeader extends StatelessWidget {
  const ReplyHeader({super.key, required this.reply});

  final Reply reply;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Dimmed(
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            child: TimedText(
              created: reply.createdAt,
              updated: reply.updatedAt,
              child: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        reply.creator,
                        style: TextStyle(color: dimTextColor(context)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            onTap: () => context.go(
                '${AppRoutes.profile}?userId=${reply.creatorId}',
              ),
          ),
        ),
        const SizedBox(width: 4),
        ReplyVisibilityIndicator(reply: reply),
      ],
    );
  }
}

class ReplyVisibilityIndicator extends StatelessWidget {
  const ReplyVisibilityIndicator({super.key, required this.reply});

  final Reply reply;

  @override
  Widget build(BuildContext context) {
    if (!reply.hidden) return const SizedBox();
    return Tooltip(
      message: 'This reply is hidden',
      child: Icon(
        Icons.visibility_off,
        size: smallIconSize(context),
        color: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

class ReplyWarning extends StatelessWidget {
  const ReplyWarning({super.key, required this.reply});

  final Reply reply;

  @override
  Widget build(BuildContext context) {
    WarningType? warning = reply.warning;
    if (warning == null) return const SizedBox();
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            Icons.warning_amber,
            size: smallIconSize(context),
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        Text(
          warning.message,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    );
  }
}
