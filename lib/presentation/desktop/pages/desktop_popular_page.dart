import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../../data/models/models.dart';
import '../../pages/post/post_detail_page.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../widgets/desktop_toolbar.dart';

/// Desktop popular page with most favorited posts
class DesktopPopularPage extends StatefulWidget {
  final Function(PostDetailArguments) onPostTap;
  final Function([String?]) onSearchTap;

  const DesktopPopularPage({
    super.key,
    required this.onPostTap,
    required this.onSearchTap,
  });

  @override
  State<DesktopPopularPage> createState() => _DesktopPopularPageState();
}

class _DesktopPopularPageState extends State<DesktopPopularPage> {
  final RefreshController _refreshController = RefreshController();
  int _gridColumns = 4;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPosts();
    });
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts({bool refresh = false}) async {
    final postsProvider = context.read<PostsProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    await postsProvider.loadPopularPosts(
      refresh: refresh,
      safeMode: settingsProvider.safeMode,
    );

    if (refresh) {
      _refreshController.refreshCompleted();
    }
  }

  void _onPostTap(Post post) {
    final postsProvider = context.read<PostsProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    final posts = postsProvider.popularPosts;
    final index = posts.indexWhere((p) => p.id == post.id);

    widget.onPostTap(PostDetailArguments(
      postIds: posts.map((p) => p.id).toList(),
      initialIndex: index >= 0 ? index : 0,
      hasMore: postsProvider.hasMorePopular,
      onLoadMore: () async {
        await postsProvider.loadPopularPosts(
          safeMode: settingsProvider.safeMode,
        );
        return postsProvider.popularPosts.map((p) => p.id).toList();
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DesktopToolbar(
          title: 'Popular Posts',
          icon: CupertinoIcons.star_fill,
          actions: [
            DesktopGridSizeSelector(
              value: _gridColumns,
              onChanged: (val) => setState(() => _gridColumns = val),
            ),
            const SizedBox(width: 16),
            DesktopToolbarButton(
              icon: CupertinoIcons.search,
              onPressed: () => widget.onSearchTap(),
            ),
            const SizedBox(width: 8),
            DesktopToolbarButton(
              icon: CupertinoIcons.refresh,
              onPressed: () => _loadPosts(refresh: true),
            ),
          ],
        ),
        Expanded(
          child: Consumer<PostsProvider>(
            builder: (context, postsProvider, _) {
              return Column(
                children: [
                  // Time range selector
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TimeRangeSelector(
                      selected: postsProvider.popularTimeRange,
                      options: const ['day', 'week', 'month'],
                      onChanged: (range) {
                        postsProvider.setPopularTimeRange(range);
                        _loadPosts(refresh: true);
                      },
                    ),
                  ),
                  Expanded(
                    child: SmartRefresher(
                      controller: _refreshController,
                      enablePullDown: true,
                      enablePullUp: postsProvider.hasMorePopular,
                      onRefresh: () => _loadPosts(refresh: true),
                      onLoading: () => _loadPosts(),
                      child: PostsGrid(
                        posts: postsProvider.popularPosts,
                        columns: _gridColumns,
                        isLoading: postsProvider.isLoadingPopular,
                        hasMore: postsProvider.hasMorePopular,
                        error: postsProvider.popularError,
                        onPostTap: _onPostTap,
                        onLoadMore: () => _loadPosts(),
                        onRetry: () => _loadPosts(refresh: true),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
