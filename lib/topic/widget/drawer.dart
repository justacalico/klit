// SPDX-License-Identifier: AGPL-3.0

import 'package:flutter/material.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/topic/topic.dart';

class TopicTagEditingTile extends StatelessWidget {
  const TopicTagEditingTile({super.key, required this.controller});

  final TopicController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => SwitchListTile(
        secondary: const Icon(Icons.inventory_outlined),
        title: Text(l10n.topicHideTagsEdits),
        subtitle: Text(
          controller.hideTagEditing
              ? l10n.topicHideTagsAliasHide
              : l10n.topicHideTagsAliasShow,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        value: controller.hideTagEditing,
        onChanged: (value) => controller.hideTagEditing = value,
      ),
    );
  }
}
