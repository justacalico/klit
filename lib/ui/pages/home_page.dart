import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../widgets/widgets.dart';
import 'post_detail_page.dart';
import '../shell/toolbar.dart';

class UiHomePage extends StatefulWidget {
  final void Function(PostDetailArguments) onPostTap;
  final VoidCallback onSearchTap;

  const UiHomePage({
    super.key,
    required this.onPostTap,
    required this.onSearchTap,
  });

  @override
  State<UiHomePage> createState() => _UiHomePageState();
}

class _UiHomePageState extends State<UiHomePage> {
  final _refresh = RefreshController();

  bool _safeMode(BuildContext c) =>
      c.read<AuthProvider>().isGuest || c.read<SettingsProvider>().safeMode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _refresh.dispose();
    super.dispose();
  }

  Future<void> _load({bool refresh = false}) async {
    final pp = context.read<PostsProvider>();
    final sp = context.read<SettingsProvider>();
    await pp.loadLatestPosts(
      refresh: refresh,
      safeMode: _safeMode(context),
      scoreThreshold: sp.scoreThreshold,
    );
    if (refresh) _refresh.refreshCompleted();
  }

  void _onPostTap(Post post) {
    final pp = context.read<PostsProvider>();
    final sp = context.read<SettingsProvider>();
    final posts = pp.latestPosts;
    final idx = posts.indexWhere((p) => p.id == post.id);

    widget.onPostTap(PostDetailArguments(
      postIds: posts.map((p) => p.id).toList(),
      initialIndex: idx >= 0 ? idx : 0,
      hasMore: pp.hasMoreLatest,
      onLoadMore: () async {
        await pp.loadLatestPosts(
          safeMode: _safeMode(context),
          scoreThreshold: sp.scoreThreshold,
        );
        return pp.latestPosts.map((p) => p.id).toList();
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PageToolbar(
          title: 'Latest Posts',
          icon: CupertinoIcons.house_fill,
          actions: [
            ToolbarButton(icon: CupertinoIcons.search, onPressed: widget.onSearchTap),
            const SizedBox(width: 8),
            ToolbarButton(icon: CupertinoIcons.refresh, onPressed: () => _load(refresh: true)),
          ],
        ),
        Expanded(
          child: Consumer<PostsProvider>(
            builder: (_, pp, _) => SmartRefresher(
              controller: _refresh,
              enablePullDown: true,
              enablePullUp: pp.hasMoreLatest,
              onRefresh: () => _load(refresh: true),
              onLoading: () => _load(),
              child: PostsGrid(
                posts: pp.latestPosts,
                isLoading: pp.isLoadingLatest,
                hasMore: pp.hasMoreLatest,
                error: pp.latestError,
                onPostTap: _onPostTap,
                onLoadMore: () => _load(),
                onRetry: () => _load(refresh: true),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
