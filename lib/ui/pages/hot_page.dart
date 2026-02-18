import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../widgets/widgets.dart';
import 'post_detail_page.dart';
import '../shell/toolbar.dart';

class UiHotPage extends StatefulWidget {
  final void Function(PostDetailArguments) onPostTap;
  final VoidCallback onSearchTap;

  const UiHotPage({
    super.key,
    required this.onPostTap,
    required this.onSearchTap,
  });

  @override
  State<UiHotPage> createState() => _UiHotPageState();
}

class _UiHotPageState extends State<UiHotPage> {
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
    await pp.loadHotPosts(refresh: refresh, safeMode: _safeMode(context));
    if (refresh) _refresh.refreshCompleted();
  }

  void _onPostTap(Post post) {
    final pp = context.read<PostsProvider>();
    final posts = pp.hotPosts;
    final idx = posts.indexWhere((p) => p.id == post.id);

    widget.onPostTap(PostDetailArguments(
      postIds: posts.map((p) => p.id).toList(),
      initialIndex: idx >= 0 ? idx : 0,
      hasMore: pp.hasMoreHot,
      onLoadMore: () async {
        await pp.loadHotPosts(safeMode: _safeMode(context));
        return pp.hotPosts.map((p) => p.id).toList();
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const ValueKey('hot-page'),
      child: Column(
      children: [
        PageToolbar(
          title: 'Hot Posts',
          icon: CupertinoIcons.flame_fill,
          actions: [
            ToolbarButton(icon: CupertinoIcons.search, onPressed: widget.onSearchTap),
            const SizedBox(width: 8),
            ToolbarButton(icon: CupertinoIcons.refresh, onPressed: () => _load(refresh: true)),
          ],
        ),
        Expanded(
          child: Consumer<PostsProvider>(
            builder: (_, pp, _) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: DesktopTimeRangeSelector(
                    selected: pp.hotTimeRange,
                    options: const ['day', 'week', 'month'],
                    customDate: pp.hotCustomDate,
                    onChanged: (r) => pp.setHotTimeRange(r, safeMode: _safeMode(context)),
                    onDateSelected: (d) => pp.setHotCustomDate(d, safeMode: _safeMode(context)),
                  ),
                ),
                Expanded(
                  child: SmartRefresher(
                    controller: _refresh,
                    enablePullDown: true,
                    enablePullUp: pp.hasMoreHot,
                    onRefresh: () => _load(refresh: true),
                    onLoading: () => _load(),
                    child: PostsGrid(
                      posts: pp.hotPosts,
                      isLoading: pp.isLoadingHot,
                      hasMore: pp.hasMoreHot,
                      error: pp.hotError,
                      onPostTap: _onPostTap,
                      onLoadMore: () => _load(),
                      onRetry: () => _load(refresh: true),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      ),
    );
  }
}
