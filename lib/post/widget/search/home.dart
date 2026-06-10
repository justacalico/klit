import 'package:kilt/client/client.dart';
import 'package:kilt/post/post.dart';
import 'package:kilt/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sub/flutter_sub.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final client = context.watch<Client>();
    return PostProvider(
      query: {'tags': client.traits.value.homeTags},
      child: Consumer<PostController>(
        builder: (context, controller, child) =>
            PostsControllerHistoryConnector(
              controller: controller,
              child: SubListener(
                initialize: true,
                listenable: controller,
                listener: () => client.accounts.push(
                  traits: client.traits.value.copyWith(
                    homeTags: controller.query['tags'].toString(),
                  ),
                ),
                builder: (context) => PostsPage(
                  controller: controller,
                  appBar: const DefaultAppBar(title: Text('Home')),
                ),
              ),
            ),
      ),
    );
  }
}
