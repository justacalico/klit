// SPDX-License-Identifier: AGPL-3.0

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sub/flutter_sub.dart';
import 'package:kilt/client/client.dart';
import 'package:kilt/follow/follow.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/post/post.dart';
import 'package:kilt/shared/shared.dart';
import 'package:kilt/tag/tag.dart';

class TagListActions extends StatelessWidget {
  const TagListActions({super.key, required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (wikiMetaTags.any((prefix) => tag.startsWith(prefix))) {
      return const SizedBox.shrink();
    }
    return Consumer<Client>(
      builder: (context, client, child) => SubStream<Follow?>(
        create: () => client.follows.getByTags(tags: tag).streamed,
        keys: [client, tag],
        builder: (context, snapshot) => ValueListenableBuilder(
          valueListenable: client.traits,
          builder: (context, traits, child) {
            if ([
              ConnectionState.none,
              ConnectionState.waiting,
            ].contains(snapshot.connectionState)) {
              return const AnimatedSwitcher(
                duration: defaultAnimationDuration,
                child: SizedBox.shrink(),
              );
            }

            final follow = snapshot.data;
            final hasFollow = follow != null;

            final following = [
              FollowType.update,
              FollowType.notify,
            ].contains(follow?.type);

            final notifying = follow?.type == FollowType.notify;
            final bookmarked = follow?.type == FollowType.bookmark;
            final denied = traits.denylist.contains(tag);

            VoidCallback followBookmarkToggle(FollowType type) {
              return () {
                if (hasFollow) {
                  if (follow.type == type) {
                    client.follows.delete(follow.id);
                  }
                  if (follow.type == FollowType.notify &&
                      type == FollowType.update) {
                    client.follows.delete(follow.id);
                  } else {
                    client.follows.update(id: follow.id, type: type);
                  }
                } else {
                  client.follows.create(tags: tag, type: type);
                  if (denied) {
                    client.traits.value = traits.copyWith(
                      denylist: traits.denylist..remove(tag),
                    );
                  }
                }
              };
            }

            return AnimatedSwitcher(
              duration: defaultAnimationDuration,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CrossFade(
                    showChild: !denied,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ActionButton(
                          icon: following
                              ? const Icon(Icons.person_remove_alt_1)
                              : const Icon(Icons.person_add_alt_1),
                          label: following
                              ? Text(l10n.commonUnfollow)
                              : Text(l10n.commonFollow),
                          onTap: followBookmarkToggle(FollowType.update),
                        ),
                        CrossFade(
                          showChild: following,
                          child: ActionButton(
                            icon: notifying
                                ? const Icon(Icons.notifications_active)
                                : const Icon(Icons.notifications_none),
                            label: notifying
                                ? Text(l10n.commonMute)
                                : Text(l10n.commonNotify),
                            onTap: () {
                              if (notifying) {
                                client.follows.update(
                                  id: follow!.id,
                                  type: FollowType.update,
                                );
                              } else {
                                client.follows.update(
                                  id: follow!.id,
                                  type: FollowType.notify,
                                );
                              }
                            },
                          ),
                        ),
                        ActionButton(
                          icon: bookmarked
                              ? const Icon(Icons.turned_in)
                              : const Icon(Icons.turned_in_not),
                          label: bookmarked
                              ? Text(l10n.commonUnbookmark)
                              : Text(l10n.commonBookmark),
                          onTap: followBookmarkToggle(FollowType.bookmark),
                        ),
                      ],
                    ),
                  ),
                  CrossFade(
                    showChild: !hasFollow,
                    child: ActionButton(
                      icon: CrossFade(
                        showChild: denied,
                        secondChild: const Icon(Icons.block),
                        child: const Icon(Icons.check),
                      ),
                      label: denied
                          ? Text(l10n.commonUnblock)
                          : Text(l10n.commonBlock),
                      onTap: () {
                        if (denied) {
                          client.accounts.push(
                            traits: traits.copyWith(
                              denylist: traits.denylist
                                  .whereNot((element) => element == tag)
                                  .toList(),
                            ),
                          );
                        } else {
                          if (hasFollow) {
                            client.follows.delete(follow.id);
                          }
                          client.accounts.push(
                            traits: traits.copyWith(
                              denylist: [...traits.denylist, tag],
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class RemoveTagAction extends StatelessWidget {
  const RemoveTagAction({
    super.key,
    required this.controller,
    required this.tag,
  });

  final PostController controller;
  final String tag;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ActionButton(
      icon: const Icon(Icons.search_off),
      label: Text(l10n.commonRemove),
      onTap: () {
        Navigator.of(context).maybePop();
        final result = controller.query.toQuery();
        result['tags'] = (TagMap(result['tags'])..remove(tag)).toString();
        controller.query = result;
      },
    );
  }
}

class AddTagAction extends StatelessWidget {
  const AddTagAction({super.key, required this.controller, required this.tag});

  final PostController controller;
  final String tag;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ActionButton(
      icon: const Icon(Icons.zoom_in),
      label: Text(l10n.commonAdd),
      onTap: () {
        Navigator.of(context).maybePop();
        final result = controller.query.toQuery();
        result['tags'] = (TagMap(result['tags'])..add(tag)).toString();
        controller.query = result;
      },
    );
  }
}

class SubtractTagAction extends StatelessWidget {
  const SubtractTagAction({
    super.key,
    required this.controller,
    required this.tag,
  });

  final PostController controller;
  final String tag;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ActionButton(
      icon: const Icon(Icons.zoom_out),
      label: Text(l10n.commonSubtract),
      onTap: () {
        Navigator.of(context).maybePop();
        final result = controller.query.toQuery();
        result['tags'] = (TagMap(result['tags'])..add('-$tag')).toString();
        controller.query = result;
      },
    );
  }
}

class TagSearchActions extends StatelessWidget {
  const TagSearchActions({
    super.key,
    required this.tag,
    required this.controller,
  });

  final String tag;
  final PostController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        if (!controller.canSearch || tag.contains(' ')) {
          return const SizedBox.shrink();
        }

        final isSearched = TagMap(controller.query['tags']).containsKey(tag);

        if (isSearched) {
          return RemoveTagAction(controller: controller, tag: tag);
        } else {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AddTagAction(controller: controller, tag: tag),
              SubtractTagAction(controller: controller, tag: tag),
            ],
          );
        }
      },
    );
  }
}
