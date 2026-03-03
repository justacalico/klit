import 'package:klit/client/client.dart';
import 'package:klit/follow/follow.dart';
import 'package:klit/post/post.dart';
import 'package:klit/settings/settings.dart';
import 'package:klit/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sub/flutter_sub.dart';

class FollowsSubscriptionsPage extends StatelessWidget {
  const FollowsSubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: context.watch<Settings>().filterUnseenFollows,
        builder: (context, filterUnseenFollows, child) =>
            SubChangeNotifierProvider<Client, FollowController>(
              create: (context, value) => FollowController(
                client: value,
                types: [FollowType.update, FollowType.notify],
                filterUnseen: filterUnseenFollows,
              ),
              keys: (context) => [filterUnseenFollows],
              child: child,
            ),
        child: Consumer<FollowController>(
          builder: (context, controller, _) => SubEffect(
            effect: () {
              // remove this when the paged grid view is implemented
              controller.getNextPage();
              final client = context.read<Client>();
              client.followServer.sync();
              return null;
            },
            keys: [controller],
            child: SelectionLayout<Follow>(
              items: controller.items,
              child: PromptActions(
                child: AdaptiveScaffold(
                  appBar: const FollowSelectionAppBar(
                    child: DefaultAppBar(
                      title: Text('Subscriptions'),
                      actions: [ContextDrawerButton()],
                    ),
                  ),
                  endDrawer: const ContextDrawer(
                    title: Text('Subscriptions'),
                    children: [
                      FollowEditingTile(),
                      Divider(),
                      FollowFilterReadTile(),
                      FollowMarkReadTile(),
                      Divider(),
                      FollowForceSyncTile(),
                    ],
                  ),
                  floatingActionButton: AddTagFloatingActionButton(
                    title: 'Add to subscriptions',
                    onSubmit: (value) async {
                      value = value.trim();
                      if (value.isEmpty) return;
                      await context.read<Client>().follows.create(
                        tags: value,
                        type: FollowType.update,
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
                          state: controller.state,
                          fetchNextPage: controller.getNextPage,
                          addAutomaticKeepAlives: false,
                          builderDelegate: defaultPagedChildBuilderDelegate(
                            onRetry: controller.getNextPage,
                            itemBuilder: (context, item, index) =>
                                FollowTile(follow: item),
                            onEmpty: const Text('No subscriptions'),
                            onError: const Text('Failed to load subscriptions'),
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
