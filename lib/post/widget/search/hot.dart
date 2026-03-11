import 'package:klit/post/post.dart';
import 'package:klit/post/widget/search/popular_date_control.dart';
import 'package:klit/shared/shared.dart';
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
                    appBar: DefaultAppBar(
                      title: const Text('Popular'),
                      actions: [
                        if (hot != null) PopularDateButton(controller: hot),
                      ],
                      secondary: hot != null
                          ? Padding(
                              padding: const EdgeInsets.only(
                                left: 12,
                                right: 12,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  popularDateLabel(hot),
                                  style: TextStyle(
                                    color: dimTextColor(context),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                );
              },
        ),
      );
  }
}
