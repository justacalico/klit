import 'package:klit/post/post.dart';
import 'package:klit/shared/shared.dart';
import 'package:flutter/material.dart';

class HotPage extends StatelessWidget {
  const HotPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PostProvider.builder(
        create: (context, client) => HotPostController(client: client),
        child: Consumer<PostController>(
              builder: (context, controller, child) =>
              PostsControllerHistoryConnector(
                controller: controller,
                child: PostsPage(
                  controller: controller,
                  appBar: const DefaultAppBar(title: Text('Popular')),
                ),
              ),
        ),
      );
  }
}
