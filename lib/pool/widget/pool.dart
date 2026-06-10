import 'package:kilt/history/history.dart';
import 'package:kilt/pool/pool.dart';
import 'package:kilt/post/post.dart';
import 'package:kilt/shared/shared.dart';
import 'package:flutter/material.dart';

class PoolPage extends StatefulWidget {
  const PoolPage({super.key, required this.pool, this.orderByOldest});

  final Pool pool;
  final bool? orderByOldest;

  @override
  State<PoolPage> createState() => _PoolPageState();
}

class _PoolPageState extends State<PoolPage> {
  bool readerMode = true;

  @override
  Widget build(BuildContext context) {
    return PostProvider.builder(
      create: (context, client) => PoolPostController(
        client: client,
        id: widget.pool.id,
        orderByOldest: widget.orderByOldest ?? true,
      ),
      child: Consumer<PostController>(
        builder: (context, controller, child) => ControllerHistoryConnector(
          controller: controller,
          addToHistory: (context, client, data) {
            client.histories.add(
              PoolHistoryRequest.item(
                pool: widget.pool,
                posts: controller.items,
              ),
            );
          },
          child: PostsPage(
            controller: controller,
            displayType: readerMode ? PostDisplayType.comic : null,
            drawerActions: [
              Builder(
                builder: (context) => PoolReaderSwitch(
                  readerMode: readerMode,
                  onChange: (value) {
                    setState(() => readerMode = value);
                    Scaffold.of(context).closeEndDrawer();
                  },
                ),
              ),
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
          ),
        ),
      ),
    );
  }
}

class PoolOrderSwitch extends StatelessWidget {
  const PoolOrderSwitch({
    super.key,
    required this.oldestFirst,
    required this.onChange,
  });

  final bool oldestFirst;
  final ValueChanged<bool> onChange;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: const Icon(Icons.sort),
      title: const Text('Pool order'),
      subtitle: Text(oldestFirst ? 'oldest first' : 'newest first'),
      value: oldestFirst,
      onChanged: onChange,
    );
  }
}

class PoolReaderSwitch extends StatelessWidget {
  const PoolReaderSwitch({
    super.key,
    required this.readerMode,
    required this.onChange,
  });

  final bool readerMode;
  final ValueChanged<bool> onChange;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: const Icon(Icons.auto_stories),
      title: const Text('Pool reader mode'),
      subtitle: Text(readerMode ? 'large images' : 'normal grid'),
      value: readerMode,
      onChanged: onChange,
    );
  }
}
