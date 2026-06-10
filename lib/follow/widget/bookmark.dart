import 'package:kilt/client/client.dart';
import 'package:kilt/follow/follow.dart';
import 'package:kilt/post/post.dart';
import 'package:kilt/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sub/flutter_sub.dart';

class FollowsBookmarkPage extends StatelessWidget {
  const FollowsBookmarkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SubChangeNotifierProvider<Client, FollowController>(
        create: (context, client) =>
            FollowController(client: client, types: [FollowType.bookmark]),
        child: Consumer<FollowController>(
          builder: (context, controller, child) => SubEffect(
            effect: () {
              // remove this when the paged grid view is implemented
              controller.getNextPage();
              final client = context.read<Client>();
              client.followServer.sync();
              return null;
            },
            keys: const [],
            child: SelectionLayout<Follow>(
              items: controller.items,
              child: PromptActions(
                child: AdaptiveScaffold(
                  appBar: const FollowSelectionAppBar(
                    child: DefaultAppBar(title: Text('Bookmarks')),
                  ),
                  floatingActionButton: AddTagFloatingActionButton(
                    title: 'Add to bookmarks',
                    onSubmit: (value) async {
                      value = value.trim();
                      if (value.isEmpty) return;
                      await context.read<Client>().follows.create(
                        tags: value,
                        type: FollowType.bookmark,
                      );
                    },
                  ),
                  body: TileLayout(
                    child: ListenableBuilder(
                      listenable: controller,
                      builder: (context, _) => PullToRefresh(
                        onRefresh: () =>
                            controller.refresh(force: true, background: true),
                        child: PagedAlignedGridView<int, Follow>.count(
                          primary: true,
                          padding: defaultActionListPadding,
                          addAutomaticKeepAlives: false,
                          state: controller.state,
                          fetchNextPage: controller.getNextPage,
                          builderDelegate: defaultPagedChildBuilderDelegate(
                            onRetry: controller.getNextPage,
                            itemBuilder: (context, item, index) =>
                                FollowTile(follow: item),
                            onEmpty: const Text('No bookmarks'),
                            onError: const Text('Failed to load bookmarks'),
                          ),
                          crossAxisCount: TileLayout.of(context).crossAxisCount,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
    );
  }
}
