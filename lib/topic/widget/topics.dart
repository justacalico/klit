// SPDX-License-Identifier: AGPL-3.0

import 'package:kilt/history/history.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/shared/shared.dart';
import 'package:kilt/topic/topic.dart';
import 'package:flutter/material.dart';

class TopicsPage extends StatelessWidget {
  const TopicsPage({super.key, this.query});

  final QueryMap? query;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TopicProvider(
        query: query,
        child: Consumer<TopicController>(
          builder: (context, controller, child) => ControllerHistoryConnector(
            controller: controller,
            addToHistory: (context, client, controller) => client.histories.add(
              TopicHistoryRequest.search(
                query: controller.query,
                topics: controller.items!,
              ),
            ),
            child: AdaptiveScaffold(
              appBar: DefaultAppBar(
                title: Text(l10n.topicTopics),
                actions: const [ContextDrawerButton()],
              ),
              floatingActionButton: null,
              endDrawer: ContextDrawer(
                title: Text(l10n.topicTopics),
                children: [TopicTagEditingTile(controller: controller)],
              ),
              body: const TopicList(),
            ),
          ),
        ),
    );
  }
}
