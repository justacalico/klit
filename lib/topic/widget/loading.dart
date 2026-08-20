// SPDX-License-Identifier: AGPL-3.0

import 'package:flutter/material.dart';
import 'package:kilt/client/client.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/reply/reply.dart';
import 'package:kilt/shared/shared.dart';
import 'package:kilt/topic/topic.dart';

class TopicLoadingPage extends StatefulWidget {
  const TopicLoadingPage(this.id, {super.key, this.orderByOldest});

  final int id;
  final bool? orderByOldest;

  @override
  State<TopicLoadingPage> createState() => _TopicLoadingPageState();
}

class _TopicLoadingPageState extends State<TopicLoadingPage> {
  late Future<Topic> topic = context.read<Client>().topics.get(id: widget.id);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureLoadingPage<Topic>(
      future: topic,
      builder: (context, value) =>
          TopicRepliesPage(topic: value, orderByOldest: widget.orderByOldest),
      title: Text(l10n.topicTitle(widget.id)),
      onError: Text(l10n.topicFailedLoadOne),
      onEmpty: Text(l10n.topicNotFound),
    );
  }
}
