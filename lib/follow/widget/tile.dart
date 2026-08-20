// SPDX-License-Identifier: AGPL-3.0

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:kilt/app/app.dart';
import 'package:kilt/client/client.dart';
import 'package:kilt/follow/follow.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/post/post.dart';
import 'package:kilt/shared/shared.dart';
import 'package:kilt/tag/tag.dart';

class FollowTile extends StatelessWidget {
  const FollowTile({super.key, required this.follow});

  final Follow follow;

  @override
  Widget build(BuildContext context) {
    final client = context.watch<Client>();
    final l10n = AppLocalizations.of(context);
    final promptController = PromptActions.maybeOf(context);
    final active = follow.latest != null && follow.thumbnail != null;

    void editTitle() {
      promptController!.show(
        context,
        ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: Theme.of(context).isDesktop ? 600 : 0,
          ),
          child: ControlledTextField(
            labelText: l10n.followFollowTitle,
            actionController: promptController,
            textController: TextEditingController(text: follow.name),
            submit: (value) {
              final title = value.trim();
              if (follow.title != value) {
                client.follows.update(id: follow.id, title: title);
              }
            },
          ),
        ),
      );
    }

    void edit() {
      promptController!.show(
        context,
        EditTagPrompt(
          onSubmit: (value) {
            value = value.trim();
            if (value.isNotEmpty) {
              client.follows.update(id: follow.id, tags: value);
            } else {
              client.follows.delete(follow.id);
            }
          },
          actionController: promptController,
          tag: follow.tags,
          title: l10n.followEditFollow,
        ),
      );
    }

    Widget contextMenu() {
      final notified = follow.type == FollowType.notify;
      final bookmarked = follow.type == FollowType.bookmark;

      return PopupMenuButton<VoidCallback>(
        icon: const Dimmed(child: Icon(Icons.more_vert)),
        onSelected: (value) => value(),
        itemBuilder: (context) => [
          if ((follow.unseen ?? 0) > 0)
            PopupMenuTile(
              value: () => client.follows.markSeen(follow.id),
              title: l10n.followMarkAsRead,
              icon: Icons.mark_email_read,
            ),
          if (PlatformCapabilities.hasNotifications && !bookmarked)
            PopupMenuTile(
              value: () => client.follows.update(
                id: follow.id,
                type: !notified ? FollowType.notify : FollowType.update,
              ),
              title: notified
                  ? l10n.followDisableNotifications
                  : l10n.followEnableNotifications,
              icon: notified
                  ? Icons.notifications_off
                  : Icons.notifications_active,
            ),
          if (!PlatformCapabilities.hasNotifications || !notified)
            PopupMenuTile(
              value: () => client.follows.update(
                id: follow.id,
                type: !bookmarked ? FollowType.bookmark : FollowType.update,
              ),
              title: bookmarked ? l10n.followSubscribe : l10n.followBookmark,
              icon: bookmarked ? Icons.person_add : Icons.bookmark,
            ),
          if (promptController != null && follow.tags.split(' ').length > 1)
            PopupMenuTile(value: editTitle, title: l10n.followRename, icon: Icons.label),
          if (promptController != null)
            PopupMenuTile(value: edit, title: l10n.commonEdit, icon: Icons.edit),
          PopupMenuTile(
            value: () => client.follows.delete(follow.id),
            title: l10n.commonUnfollow,
            icon: Icons.person_remove,
          ),
        ],
      );
    }

    String getStatusText() {
      final unseen = follow.unseen ?? 0;
      if (unseen == 1) {
        return l10n.followNewPost;
      }
      return l10n.followNewPosts;
    }

    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(4)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            fit: StackFit.passthrough,
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: 1 / 1.2,
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: CrossFade.builder(
                    showChild: active,
                    secondChild: const Icon(Icons.image_not_supported_outlined),
                    builder: (context) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Hero(
                            tag: PostLinking.getPostLink(follow.latest!),
                            child: CachedNetworkImage(
                              imageUrl: follow.thumbnail!,
                              errorWidget: defaultErrorBuilder,
                              fit: BoxFit.cover,
                              cacheManager: context.read<BaseCacheManager>(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Material(
                  type: MaterialType.transparency,
                  child: SelectionItemOverlay<Follow>(
                    item: follow,
                    child: InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PostsSearchPage(
                            query: {'tags': follow.tags},
                            orderPoolsByOldest: (follow.unseen ?? 0) == 0,
                            readerMode: poolRegex().hasMatch(follow.tags),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
            ).copyWith(bottom: 4, right: 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        follow.name,
                        style: Theme.of(context).textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        softWrap: true,
                      ),
                      CrossFade(
                        showChild: follow.alias != null,
                        child: Dimmed(
                          child: Text(
                            l10n.followAlias(follow.alias ?? ''),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                      CrossFade(
                        showChild:
                            follow.title != null &&
                            follow.tags.split(' ').length > 1,
                        child: Dimmed(
                          child: Text(
                            tagToTitle(follow.tags),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                      Dimmed(
                        opacity: 0.7,
                        child: Row(
                          children: [
                            CrossFade(
                              showChild: follow.type == FollowType.notify,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: follow.type.icon,
                              ),
                            ),
                            Expanded(
                              child: CrossFade(
                                style: FadeAnimationStyle.stacked,
                                showChild: (follow.unseen ?? 0) > 0,
                                child: Text(
                                  getStatusText(),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                contextMenu(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
