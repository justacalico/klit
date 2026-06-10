import 'package:kilt/app/app.dart';
import 'package:kilt/client/client.dart';
import 'package:kilt/comment/comment.dart';
import 'package:kilt/flag/flag.dart';
import 'package:kilt/post/post.dart';
import 'package:kilt/settings/settings.dart';
import 'package:kilt/shared/shared.dart';
import 'package:kilt/ticket/ticket.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef _PostMenuAction = ({IconData icon, String title, VoidCallback onTap});

_PostMenuAction _postActionToMenuAction(
  BuildContext context,
  Post post,
  PostActionId action,
) {
  switch (action) {
    case PostActionId.share:
      return (
        icon: Icons.share,
        title: 'Share',
        onTap: () async =>
            Share.text(context, context.read<Client>().withHost(post.link)),
      );
    case PostActionId.download:
      return (
        icon: Icons.file_download,
        title: 'Download',
        onTap: () => postDownloadingNotification(context, {post}),
      );
    case PostActionId.browse:
      return (
        icon: Icons.open_in_browser,
        title: 'Browse',
        onTap: () async => launch(context.read<Client>().withHost(post.link)),
      );
    case PostActionId.upvote:
    case PostActionId.downvote:
    case PostActionId.favorite:
    case PostActionId.iFinished:
      throw StateError('Unsupported menu action: ${action.key}');
  }
}

bool _isPostActionAvailable(
  BuildContext context,
  Post post,
  PostActionId action,
) {
  return switch (action) {
    PostActionId.download => post.file != null,
    PostActionId.iFinished => context.read<Settings>().iFinishedEnabled.value,
    _ => true,
  };
}

List<_PostMenuAction> _postMenuPostActionsConfig(
  BuildContext context,
  Post post, {
  Set<PostActionId> excluded = const <PostActionId>{},
}) {
  final actions = <_PostMenuAction>[];
  for (final action in PostActionPreferences.menuActions) {
    if (excluded.contains(action)) continue;
    if (!_isPostActionAvailable(context, post, action)) continue;
    actions.add(_postActionToMenuAction(context, post, action));
  }
  return actions;
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
        callback: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PostCommentsPage(postId: post.id),
          ),
        ),
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
      .map((a) => PopupMenuTile(value: a.onTap, title: a.title, icon: a.icon))
      .toList();
}

List<PopupMenuItem<VoidCallback>> postMenuUserActions(
  BuildContext context,
  Post post,
) {
  final actions = _postMenuUserActionsConfig(context, post);
  return actions
      .map((a) => PopupMenuTile(value: a.onTap, title: a.title, icon: a.icon))
      .toList();
}

Future<void> showPostMenuSheet(
  BuildContext context,
  Post post, {
  BuildContext? anchorContext,
}) async {
  final theme = Theme.of(context);
  final cupertinoTheme = CupertinoTheme.of(context);
  final settings = context.read<Settings>();
  final hasLogin = context.read<Client>().hasLogin;
  final pinnedActions = hasLogin
      ? PostActionPreferences.decode(
          settings.postActionBarActions.value,
        ).toSet()
      : <PostActionId>{};

  final postActions = _postMenuPostActionsConfig(
    context,
    post,
    excluded: pinnedActions,
  );
  final userActions = _postMenuUserActionsConfig(context, post);

  Future<void> showAsPopup() async {
    final anchor = anchorContext ?? context;
    final overlay =
        Overlay.of(context, rootOverlay: true).context.findRenderObject()
            as RenderBox;
    final anchorBox = anchor.findRenderObject() as RenderBox;
    final anchorRect = RelativeRect.fromRect(
      Rect.fromPoints(
        anchorBox.localToGlobal(Offset.zero, ancestor: overlay),
        anchorBox.localToGlobal(anchorBox.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    final menuItems = <PopupMenuEntry<VoidCallback>>[
      ...postActions.map(
        (a) => PopupMenuTile(value: a.onTap, title: a.title, icon: a.icon),
      ),
      if (userActions.isNotEmpty && postActions.isNotEmpty)
        const PopupMenuDivider(),
      ...userActions.map(
        (a) => PopupMenuTile(value: a.onTap, title: a.title, icon: a.icon),
      ),
    ];
    final selected = await showMenu<VoidCallback>(
      context: context,
      position: anchorRect,
      items: menuItems,
    );
    if (selected != null) {
      HapticFeedback.selectionClick();
      selected();
    }
  }

  if (theme.isDesktop) {
    await showAsPopup();
    return;
  }

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
                (a) => _PostMenuTile(action: a, cupertinoTheme: cupertinoTheme),
              ),
              if (userActions.isNotEmpty) const Divider(height: 1),
              ...userActions.map(
                (a) => _PostMenuTile(action: a, cupertinoTheme: cupertinoTheme),
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
  const _PostMenuTile({required this.action, required this.cupertinoTheme});

  final _PostMenuAction action;
  final CupertinoThemeData cupertinoTheme;

  @override
  Widget build(BuildContext context) {
    final iconColor = CupertinoColors.label.resolveFrom(context);
    return CupertinoListTile(
      leading: Icon(action.icon, color: iconColor),
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
