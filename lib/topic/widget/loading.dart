import 'package:kilt/client/client.dart';
import 'package:kilt/reply/reply.dart';
import 'package:kilt/shared/shared.dart';
import 'package:kilt/topic/topic.dart';
import 'package:flutter/material.dart';

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
    return FutureLoadingPage<Topic>(
      future: topic,
      builder: (context, value) =>
          TopicRepliesPage(topic: value, orderByOldest: widget.orderByOldest),
      title: Text('Topic #${widget.id}'),
      onError: const Text('Failed to load topic'),
      onEmpty: const Text('Topic not found'),
    );
  }
}
