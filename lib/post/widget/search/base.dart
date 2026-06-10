import 'package:kilt/client/client.dart';
import 'package:kilt/follow/follow.dart';
import 'package:kilt/history/history.dart';
import 'package:kilt/pool/pool.dart';
import 'package:kilt/post/post.dart';
import 'package:kilt/shared/shared.dart';
import 'package:kilt/tag/tag.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Consumer;
import 'package:flutter_sub/flutter_sub.dart';

class PostsSearchPage extends ConsumerStatefulWidget {
  const PostsSearchPage({
    super.key,
    this.query,
    this.orderPoolsByOldest = true,
    this.readerMode = false,
  });

  final QueryMap? query;
  final bool orderPoolsByOldest;
  final bool readerMode;

  @override
  ConsumerState<PostsSearchPage> createState() => _PostsSearchPageState();
}

class _PostsSearchPageState extends ConsumerState<PostsSearchPage> {
  late bool readerMode = widget.readerMode;
  bool loadingInfo = true;
  Pool? pool;
  Follow? follow;
  QueryMap? lastQuery;

  @override
  Widget build(BuildContext context) {
    return PostProvider(
      query: widget.query,
      orderPools: widget.orderPoolsByOldest,
      child: Consumer<PostController>(
        builder: (context, controller, child) {
          final client = context.read<Client>();
          Future<void> updateFollow() async {
            String? tags = controller.query['tags'];
            if (tags?.nullWhenEmpty != null) {
              follow = await client.follows.getByTags(tags: tags!);
            } else {
              follow = null;
            }
            if (follow != null) {
              await client.followServer.syncWith(
                id: follow!.id,
                posts: controller.items,
                pool: pool,
              );
              if (!context.mounted) return;
              Follow updated = await client.follows.get(id: follow!.id);
              if (follow == updated) return;
              if (!context.mounted) return;
              setState(() => follow = updated);
            }
          }

          Future<void> updatePool() async {
            if (!mounted) return;
            setState(() {
              loadingInfo = true;
            });
            RegExpMatch? match = poolRegex().firstMatch(
              controller.query['tags'] ?? '',
            );
            if (match != null) {
              if (match.namedGroup('id')! != pool?.id.toString()) {
                try {
                  pool = await client.pools.get(
                    id: int.parse(match.namedGroup('id')!),
                  );
                } on ClientException {
                  pool = null;
                }
              }
            } else {
              pool = null;
            }
            if (!mounted) return;
            setState(() {
              loadingInfo = false;
            });
          }

          Future<void> updateSearch() async {
            if (!mounted) return;
            if (mapEquals(lastQuery, controller.query)) return;
            lastQuery = controller.query;
            final client = context.read<Client>();
            await updatePool();
            await controller.waitForNextPage();
            if (controller.error != null) return;
            await updateFollow();
            if (pool != null) {
              client.histories.add(
                PoolHistoryRequest.item(pool: pool!, posts: controller.items),
              );
            } else {
              client.histories.add(
                PostHistoryRequest.search(
                  query: controller.query,
                  posts: controller.items,
                ),
              );
            }
          }

          return SubListener(
            initialize: true,
            listenable: controller,
            listener: () => WidgetsBinding.instance.addPostFrameCallback(
              (_) => updateSearch(),
            ),
            builder: (context) {
              final requestFocus =
                  ref.read(navigationProvider.notifier).takeRequestSearchFocus();
              return PostsPage(
                controller: controller,
                appBar: SearchPageAppBar(
                  controller: controller,
                  requestFocus: requestFocus,
                ),
                displayType: readerMode ? PostDisplayType.comic : null,
                drawerActions: [
                  if (pool != null)
                    Builder(
                      builder: (context) => PoolReaderSwitch(
                        readerMode: readerMode,
                        onChange: (value) {
                          setState(() => readerMode = value);
                          Scaffold.of(context).closeEndDrawer();
                        },
                      ),
                    ),
                  if (pool != null)
                    AnimatedBuilder(
                      animation: controller,
                      builder: (context, child) => PoolOrderSwitch(
                        oldestFirst: controller.orderPools,
                        onChange: (value) {
                          controller.orderPools = value;
                          Scaffold.of(context).closeEndDrawer();
                        },
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
