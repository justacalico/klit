import 'package:klit/app/app.dart';
import 'package:klit/client/client.dart';
import 'package:klit/comment/comment.dart';
import 'package:klit/flag/flag.dart';
import 'package:klit/post/post.dart';
import 'package:klit/shared/shared.dart';
import 'package:klit/ticket/ticket.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef _PostMenuAction = ({IconData icon, String title, VoidCallback onTap});

List<_PostMenuAction> _postMenuPostActionsConfig(
  BuildContext context,
  Post post,
) {
  return [
    (
      icon: Icons.share,
      title: 'Share',
      onTap: () async =>
          Share.text(context, context.read<Client>().withHost(post.link)),
    ),
    if (post.file != null)
      (
        icon: Icons.file_download,
        title: 'Download',
        onTap: () => postDownloadingNotification(context, {post}),
      ),
    (
      icon: Icons.open_in_browser,
      title: 'Browse',
      onTap: () async => launch(context.read<Client>().withHost(post.link)),
    ),
  ];
}

List<_PostMenuAction> _postMenuUserActionsConfig(
  BuildContext context,
  Post post,
) {
  return [
    (
      icon: Icons.edit,
      title: 'Edit',
      onTap: () => guardWithLogin(
        context: context,
        callback: () {
          final controller = context.read<PostController?>();
          final cacheSize = context.read<ImageCacheSize?>()?.size;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ImageCacheSizeProvider(
                size: cacheSize,
                child: controller != null
                    ? PostsRouteConnector(
                        controller: controller,
                        child: PostEditPage(post: post),
                      )
                    : PostEditPage(post: post),
              ),
            ),
          );
        },
        error: 'You must be logged in to edit posts!',
      ),
    ),
    (
      icon: Icons.comment,
      title: 'Comment',
      onTap: () => guardWithLogin(
        context: context,
        callback: () async {
          final controller = context.read<PostController>();
          final success = await writeComment(
            context: context,
            postId: post.id,
          );
          if (success) {
            controller.replacePost(
              post.copyWith(commentCount: post.commentCount + 1),
            );
          }
        },
        error: 'You must be logged in to comment!',
      ),
    ),
    (
      icon: Icons.report,
      title: 'Report',
      onTap: () => guardWithLogin(
        context: context,
        callback: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => PostReportScreen(post: post)),
        ),
        error: 'You must be logged in to report posts!',
      ),
    ),
    (
      icon: Icons.flag,
      title: 'Flag',
      onTap: () => guardWithLogin(
        context: context,
        callback: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => PostFlagScreen(post: post)),
        ),
        error: 'You must be logged in to flag posts!',
      ),
    ),
  ];
}

List<PopupMenuItem<VoidCallback>> postMenuPostActions(
  BuildContext context,
  Post post,
) {
  final actions = _postMenuPostActionsConfig(context, post);
  return actions
      .map(
        (a) => PopupMenuTile(
          value: a.onTap,
          title: a.title,
          icon: a.icon,
        ),
      )
      .toList();
}

List<PopupMenuItem<VoidCallback>> postMenuUserActions(
  BuildContext context,
  Post post,
) {
  final actions = _postMenuUserActionsConfig(context, post);
  return actions
      .map(
        (a) => PopupMenuTile(
          value: a.onTap,
          title: a.title,
          icon: a.icon,
        ),
      )
      .toList();
}

Future<void> showPostMenuSheet(BuildContext context, Post post) async {
  final theme = Theme.of(context);
  final cupertinoTheme = CupertinoTheme.of(context);

  final postActions = _postMenuPostActionsConfig(context, post);
  final userActions = _postMenuUserActionsConfig(context, post);

  await showCupertinoModalPopup<void>(
    context: context,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: SafeArea(
        top: false,
        child: GlassSurface(
          borderRadius: 20,
          blurSigma: 20,
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              ...postActions.map(
                (a) => _PostMenuTile(
                  action: a,
                  cupertinoTheme: cupertinoTheme,
                ),
              ),
              if (userActions.isNotEmpty) const Divider(height: 1),
              ...userActions.map(
                (a) => _PostMenuTile(
                  action: a,
                  cupertinoTheme: cupertinoTheme,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PostMenuTile extends StatelessWidget {
  const _PostMenuTile({
    required this.action,
    required this.cupertinoTheme,
  });

  final _PostMenuAction action;
  final CupertinoThemeData cupertinoTheme;

  @override
  Widget build(BuildContext context) {
    final iconColor = CupertinoColors.label.resolveFrom(context);
    return CupertinoListTile(
      leading: Icon(
        action.icon,
        color: iconColor,
      ),
      title: Text(
        action.title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).maybePop();
        action.onTap();
      },
    );
  }
}
