// SPDX-License-Identifier: AGPL-3.0

import 'package:kilt/comment/comment.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/shared/shared.dart';
import 'package:flutter/material.dart';

class CommentListDropdown extends StatelessWidget {
  const CommentListDropdown({super.key, this.postId});

  final int? postId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Consumer<CommentController>(
      builder: (context, controller, child) => PopupMenuButton<VoidCallback>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) => value(),
        itemBuilder: (context) => [
          PopupMenuTile(
            title: l10n.commentRefresh,
            icon: Icons.refresh,
            value: () => controller.refresh(force: true),
          ),
          PopupMenuTile(
            icon: Icons.sort,
            title: controller.orderByOldest ? l10n.commonSortNewestFirst : l10n.commonSortOldestFirst,
            value: () => controller.orderByOldest = !controller.orderByOldest,
          ),
        ],
      ),
    );
  }
}
