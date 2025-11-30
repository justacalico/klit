import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../../app/routes.dart';
import '../../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../post/post_detail_page.dart';

/// Hot page with trending posts
class HotPage extends StatefulWidget {
  const HotPage({super.key});

  @override
  State<HotPage> createState() => _HotPageState();
}

class _HotPageState extends State<HotPage> {
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
    await postsProvider.loadHotPosts(refresh: refresh);
    
    if (refresh) {
      _refreshController.refreshCompleted();
    }
  }

  void _onPostTap(Post post) {
    final postsProvider = context.read<PostsProvider>();
    final posts = postsProvider.hotPosts;
    final index = posts.indexWhere((p) => p.id == post.id);
    
    Navigator.of(context).pushNamed(
      AppRoutes.postDetail,
      arguments: PostDetailArguments(
        postIds: posts.map((p) => p.id).toList(),
        initialIndex: index >= 0 ? index : 0,
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
        middle: const Text('Hot'),
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
                  selected: postsProvider.hotTimeRange,
                  options: const ['day', 'week', 'month'],
                  onChanged: (range) {
                    postsProvider.setHotTimeRange(range);
                  },
                ),
                Expanded(
                  child: SmartRefresher(
                    controller: _refreshController,
                    enablePullDown: true,
                    enablePullUp: postsProvider.hasMoreHot,
                    onRefresh: () => _loadPosts(refresh: true),
                    onLoading: () => _loadPosts(),
                    child: _isGridView
                        ? PostsGrid(
                            posts: postsProvider.hotPosts,
                            columns: gridSize,
                            isLoading: postsProvider.isLoadingHot,
                            hasMore: postsProvider.hasMoreHot,
                            error: postsProvider.hotError,
                            onPostTap: _onPostTap,
                            onLoadMore: () => _loadPosts(),
                            onRetry: () => _loadPosts(refresh: true),
                          )
                        : PostsList(
                            posts: postsProvider.hotPosts,
                            isLoading: postsProvider.isLoadingHot,
                            hasMore: postsProvider.hasMoreHot,
                            error: postsProvider.hotError,
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
