import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/shared/shared.dart';
import 'package:kilt/tag/tag.dart';
import 'package:kilt/topic/topic.dart';
import 'package:flutter/material.dart';

class TopicSearchFab extends StatelessWidget {
  const TopicSearchFab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Consumer<TopicController>(
      builder: (context, controller, child) => SearchPromptFloatingActionButton(
        tags: controller.query,
        onSubmit: (value) => controller.query = value,
        filters: [
          WrapperFilterConfig(
            wrapper: (value) => 'search[$value]',
            unwrapper: (value) => value.substring(7, value.length - 1),
            filters: [
              PrimaryFilterConfig(
                filter: TextFilterTag(tag: 'title_matches', name: l10n.commonName),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
