import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../../app/routes.dart';
import '../../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../post/post_detail_page.dart';

/// Popular page with most favorited posts
class PopularPage extends StatefulWidget {
  const PopularPage({super.key});

  @override
  State<PopularPage> createState() => _PopularPageState();
}

class _PopularPageState extends State<PopularPage> {
  final RefreshController _refreshController = RefreshController();
  bool _isGridView = true;

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
    
    Navigator.of(context).pushNamed(
      AppRoutes.postDetail,
      arguments: PostDetailArguments(
        postIds: posts.map((p) => p.id).toList(),
        initialIndex: index >= 0 ? index : 0,
        hasMore: postsProvider.hasMorePopular,
        onLoadMore: () async {
          await postsProvider.loadPopularPosts(
            safeMode: settingsProvider.safeMode,
          );
          return postsProvider.popularPosts.map((p) => p.id).toList();
        },
      ),
    );
  }

  void _openSearch() {
    Navigator.of(context).pushNamed(AppRoutes.search);
  }

  @override
  Widget build(BuildContext context) {
    final gridSize = context.watch<SettingsProvider>().gridSize;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Popular'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ViewToggleButton(
              isGrid: _isGridView,
              onToggle: () => setState(() => _isGridView = !_isGridView),
            ),
            AppBarSearchButton(onTap: _openSearch),
          ],
        ),
      ),
      child: SafeArea(
        child: Consumer<PostsProvider>(
          builder: (context, postsProvider, _) {
            return Column(
              children: [
                TimeRangeSelector(
                  selected: postsProvider.popularTimeRange,
                  options: const ['day', 'week', 'month'],
                  onChanged: (range) {
                    postsProvider.setPopularTimeRange(range);
                  },
                ),
                Expanded(
                  child: SmartRefresher(
                    controller: _refreshController,
                    enablePullDown: true,
                    enablePullUp: postsProvider.hasMorePopular,
                    onRefresh: () => _loadPosts(refresh: true),
                    onLoading: () => _loadPosts(),
                    child: _isGridView
                        ? PostsGrid(
                            posts: postsProvider.popularPosts,
                            columns: gridSize,
                            isLoading: postsProvider.isLoadingPopular,
                            hasMore: postsProvider.hasMorePopular,
                            error: postsProvider.popularError,
                            onPostTap: _onPostTap,
                            onLoadMore: () => _loadPosts(),
                            onRetry: () => _loadPosts(refresh: true),
                          )
                        : PostsList(
                            posts: postsProvider.popularPosts,
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
    );
  }
}
