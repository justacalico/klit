// SPDX-License-Identifier: AGPL-3.0

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:kilt/client/client.dart';
import 'package:kilt/follow/follow.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/shared/shared.dart';

class FollowEditor extends StatefulWidget {
  const FollowEditor({super.key});

  @override
  State<FollowEditor> createState() => _FollowEditorState();
}

class _FollowEditorState extends State<FollowEditor> {
  final String notify = FollowType.notify.name;
  final String subscribe = FollowType.update.name;
  final String bookmark = FollowType.bookmark.name;

  late final Client client = context.read<Client>();
  late Future<List<Follow>> all = client.follows.all();
  late Future<Map<String, String>> follows = all.then(
    (all) => {
      notify: followString(all.where((e) => e.type == FollowType.notify)),
      subscribe: followString(all.where((e) => e.type == FollowType.update)),
      bookmark: followString(all.where((e) => e.type == FollowType.bookmark)),
    },
  );

  String followString(Iterable<Follow> follows) =>
      follows.map((e) => e.tags).join('\n');

  Future<void> edit({
    List<String>? notifications,
    List<String>? subscriptions,
    List<String>? bookmarks,
  }) async {
    final allRemoved = <Follow>[];
    final allAdded = <FollowRequest>[];

    Future<void> process(List<String> updateList, FollowType type) async {
      final follows = await all.then(
        (value) => value.where((e) => e.type == type).toList(),
      );
      final removed = follows
          .whereNot((e) => updateList.contains(e.tags))
          .toList();
      final tags = follows.map((e) => e.tags).toList();
      final added = updateList
          .whereNot((e) => tags.contains(e))
          .map((e) => FollowRequest(tags: e, type: type))
          .toList();

      allRemoved.addAll(removed);
      allAdded.addAll(added);
    }

    if (notifications != null) {
      await process(notifications, FollowType.notify);
    }
    if (subscriptions != null) {
      await process(subscriptions, FollowType.update);
    }
    if (bookmarks != null) {
      await process(bookmarks, FollowType.bookmark);
    }

    for (final follow in allRemoved) {
      await client.follows.delete(follow.id);
    }
    for (final follow in allAdded) {
      await client.follows.create(tags: follow.tags, type: follow.type);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final Widget title = Text(l10n.followEditFollows);
    return FutureLoadingPage<Map<String, String>>(
      title: title,
      future: follows,
      builder: (context, value) => MultiTextEditor(
        title: title,
        content: [
          TextEditorContent(key: notify, title: l10n.commonNotify, value: value[notify]),
          TextEditorContent(
            key: subscribe,
            title: l10n.followSubscribe,
            value: value[subscribe],
          ),
          TextEditorContent(
            key: bookmark,
            title: l10n.followBookmark,
            value: value[bookmark],
          ),
        ],
        onSubmitted: (value) async {
          final contents = Map<String, List<String>>.fromEntries(
            value
                .whereNot((e) => e.value == null)
                .map(
                  (e) => MapEntry(
                    e.key,
                    e.value!.split('\n').whereNot((e) => e.isEmpty).toList(),
                  ),
                ),
          );
          await edit(
            notifications: contents[notify],
            subscriptions: contents[subscribe],
            bookmarks: contents[bookmark],
          );
          return null;
        },
        onClosed: Navigator.of(context).maybePop,
      ),
    );
  }
}
