// SPDX-License-Identifier: AGPL-3.0

import 'package:flutter/material.dart';
import 'package:kilt/app/app.dart';
import 'package:kilt/client/client.dart';
import 'package:kilt/follow/follow.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/shared/shared.dart';

class FollowSelectionAppBar extends StatelessWidget with AppBarBuilderWidget {
  const FollowSelectionAppBar({super.key, required this.child});

  @override
  final PreferredSizeWidget child;

  @override
  Widget build(BuildContext context) {
    final client = context.watch<Client>();
    final l10n = AppLocalizations.of(context);
    return SelectionAppBar<Follow>(
      child: child,
      titleBuilder: (context, data) => data.selections.length == 1
          ? Text(data.selections.first.name)
          : Text(l10n.followFollowsCount(data.selections.length)),
      actionBuilder: (context, data) {
        final unseen = data.selections.fold(0, (a, b) => a + (b.unseen ?? 0));
        final bookmarked = data.selections.every(
          (e) => e.type == FollowType.bookmark,
        );
        final notified = data.selections.every(
          (e) => e.type == FollowType.notify,
        );
        return [
          if (PlatformCapabilities.hasNotifications)
            IconButton(
              icon: Icon(
                notified ? Icons.notifications_off : Icons.notifications_active,
              ),
              tooltip: notified
                  ? l10n.followDisableNotifications
                  : l10n.followEnableNotifications,
              onPressed: () async {
                data.clear();
                if (notified) {
                  for (final follow in data.selections) {
                    await client.follows.update(
                      id: follow.id,
                      type: FollowType.update,
                    );
                  }
                } else {
                  for (final follow in data.selections) {
                    await client.follows.update(
                      id: follow.id,
                      type: FollowType.notify,
                    );
                  }
                }
              },
            ),
          IconButton(
            icon: Icon(bookmarked ? Icons.person_add : Icons.bookmark),
            tooltip: bookmarked ? l10n.followSubscribe : l10n.followBookmark,
            onPressed: () async {
              data.clear();
              if (bookmarked) {
                for (final follow in data.selections) {
                  await client.follows.update(
                    id: follow.id,
                    type: FollowType.update,
                  );
                }
              } else {
                for (final follow in data.selections) {
                  await client.follows.update(
                    id: follow.id,
                    type: FollowType.bookmark,
                  );
                }
              }
            },
          ),
          IconButton(
            icon: Icon(unseen > 0 ? Icons.mark_email_read : Icons.drafts),
            tooltip: unseen > 0
                ? l10n.followMarkSeen(unseen)
                : l10n.followNoUnseen,
            onPressed: unseen > 0
                ? () async {
                    data.clear();
                    client.follows.markAllSeen(
                      data.selections.map((e) => e.id).toList(),
                    );
                  }
                : null,
          ),
        ];
      },
    );
  }
}
