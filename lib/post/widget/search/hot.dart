import 'package:kilt/post/post.dart';
import 'package:kilt/post/widget/search/popular_date_control.dart';
import 'package:kilt/shared/shared.dart';
import 'package:flutter/material.dart';

class HotPage extends StatelessWidget {
  const HotPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PostProvider.builder(
        create: (context, client) => HotPostController(client: client),
        child: Consumer<PostController>(
              builder: (context, controller, child) {
                final hot = controller is HotPostController ? controller : null;
                return PostsControllerHistoryConnector(
                  controller: controller,
                  child: PostsPage(
                    controller: controller,
                    appBar: const DefaultAppBar(title: Text('Popular')),
                    bodyTop: hot != null
                        ? SafeArea(
                            bottom: false,
                            child: LimitedWidthLayout(
                              child: PopularDateInlineBar(controller: hot),
                            ),
                          )
                        : null,
                  ),
                );
              },
        ),
      );
  }
}
