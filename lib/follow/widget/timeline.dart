import 'package:klit/follow/follow.dart';
import 'package:klit/post/post.dart';
import 'package:klit/shared/shared.dart';
import 'package:flutter/material.dart';

class FollowsTimelinePage extends StatefulWidget {
  const FollowsTimelinePage({super.key});

  @override
  State<FollowsTimelinePage> createState() => _FollowsTimelinePageState();
}

class _FollowsTimelinePageState extends State<FollowsTimelinePage> {
  @override
  Widget build(BuildContext context) {
    return PostProvider.builder(
      create: (context, client) => FollowTimelineController(client: client),
      child: Consumer<PostController>(
        builder: (context, controller, child) => PostsPage(
          controller: controller,
          drawerActions: const [FollowEditingTile()],
          displayType: PostDisplayType.timeline,
          canSelect: false,
        ),
      ),
    );
  }
}
