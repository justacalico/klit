import 'package:kilt/history/history.dart';
import 'package:kilt/reply/reply.dart';
import 'package:kilt/shared/shared.dart';
import 'package:kilt/topic/topic.dart';
import 'package:flutter/material.dart';

class TopicRepliesPage extends StatelessWidget {
  const TopicRepliesPage({super.key, required this.topic, this.orderByOldest});

  final Topic topic;
  final bool? orderByOldest;

  @override
  Widget build(BuildContext context) {
    return ReplyProvider(
      topicId: topic.id,
      orderByOldest: orderByOldest,
      child: Consumer<ReplyController>(
        builder: (context, controller, child) => ControllerHistoryConnector(
          controller: controller,
          addToHistory: (context, client, controller) => client.histories.add(
            TopicHistoryRequest.item(topic: topic, replies: controller.items!),
          ),
          child: AdaptiveScaffold(
            appBar: DefaultAppBar(
              title: Text(topic.title),
              actions: [
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  tooltip: 'Info',
                  onPressed: () =>
                      showTopicPrompt(context: context, topic: topic),
                ),
                const ContextDrawerButton(),
              ],
            ),
            endDrawer: const ReplyListDrawer(),
            body: const ReplyList(),
          ),
        ),
      ),
    );
  }
}
