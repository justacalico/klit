import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../core/types/navigation_args.dart';
import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../shell/toolbar.dart';
import '../widgets/selectors.dart';
import '../widgets/widgets.dart';

class UiPopularPage extends StatefulWidget {
  const UiPopularPage({
    super.key,
    required this.onPostTap,
    required this.onSearchTap,
  });

  final void Function(PostDetailArguments) onPostTap;
  final VoidCallback onSearchTap;

  @override
  State<UiPopularPage> createState() => _UiPopularPageState();
}

class _UiPopularPageState extends State<UiPopularPage> {
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
    await pp.loadPopularPosts(refresh: refresh, safeMode: _safeMode(context));
    if (refresh) {
      _refresh.refreshCompleted();
    } else {
      _refresh.loadComplete();
    }
  }

  void _onPostTap(Post post) {
    final pp = context.read<PostsProvider>();
    final posts = pp.popularPosts;
    final idx = posts.indexWhere((p) => p.id == post.id);

    widget.onPostTap(PostDetailArguments(
      postIds: posts.map((p) => p.id).toList(),
      initialIndex: idx >= 0 ? idx : 0,
      hasMore: pp.hasMorePopular,
      onLoadMore: () async {
        await pp.loadPopularPosts(safeMode: _safeMode(context));
        return pp.popularPosts.map((p) => p.id).toList();
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const ValueKey('popular-page'),
      child: Column(
        children: [
          PageToolbar(
            title: 'Popular Posts',
            icon: CupertinoIcons.star_fill,
            actions: [
              ToolbarButton(icon: CupertinoIcons.search, onPressed: widget.onSearchTap),
              const SizedBox(width: 8),
              ToolbarButton(icon: CupertinoIcons.refresh, onPressed: () => _load(refresh: true)),
            ],
          ),
          Expanded(
            child: Consumer<PostsProvider>(
              builder: (_, pp, __) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: DesktopTimeRangeSelector(
                      selected: pp.popularTimeRange,
                      options: const ['day', 'week', 'month'],
                      customDate: pp.popularCustomDate,
                      onChanged: (r) => pp.setPopularTimeRange(r, safeMode: _safeMode(context)),
                      onDateSelected: (d) => pp.setPopularCustomDate(d, safeMode: _safeMode(context)),
                    ),
                  ),
                  Expanded(
                    child: SmartRefresher(
                      controller: _refresh,
                      enablePullDown: true,
                      enablePullUp: pp.hasMorePopular,
                      onRefresh: () => _load(refresh: true),
                      onLoading: () => _load(),
                      child: PostsGrid(
                        posts: pp.popularPosts,
                        isLoading: pp.isLoadingPopular,
                        hasMore: pp.hasMorePopular,
                        error: pp.popularError,
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
