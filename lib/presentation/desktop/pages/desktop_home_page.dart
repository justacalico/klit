import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../../data/models/models.dart';
import '../../pages/post/post_detail_page.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../widgets/desktop_toolbar.dart';

/// Desktop home page with larger grid and toolbar
class DesktopHomePage extends StatefulWidget {
  final Function(PostDetailArguments) onPostTap;
  final Function([String?]) onSearchTap;

  const DesktopHomePage({
    super.key,
    required this.onPostTap,
    required this.onSearchTap,
  });

  @override
  State<DesktopHomePage> createState() => _DesktopHomePageState();
}

class _DesktopHomePageState extends State<DesktopHomePage> {
  final RefreshController _refreshController = RefreshController();

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
    await postsProvider.loadLatestPosts(
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
    final posts = postsProvider.latestPosts;
    final index = posts.indexWhere((p) => p.id == post.id);

    widget.onPostTap(PostDetailArguments(
      postIds: posts.map((p) => p.id).toList(),
      initialIndex: index >= 0 ? index : 0,
      hasMore: postsProvider.hasMoreLatest,
      onLoadMore: () async {
        await postsProvider.loadLatestPosts(
          safeMode: settingsProvider.safeMode,
        );
        return postsProvider.latestPosts.map((p) => p.id).toList();
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar
        DesktopToolbar(
          title: 'Latest Posts',
          icon: CupertinoIcons.house_fill,
          actions: [
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
        // Content
        Expanded(
          child: Consumer<PostsProvider>(
            builder: (context, postsProvider, _) {
              return SmartRefresher(
                controller: _refreshController,
                enablePullDown: true,
                enablePullUp: postsProvider.hasMoreLatest,
                onRefresh: () => _loadPosts(refresh: true),
                onLoading: () => _loadPosts(),
                child: PostsGrid(
                  posts: postsProvider.latestPosts,
                  isLoading: postsProvider.isLoadingLatest,
                  hasMore: postsProvider.hasMoreLatest,
                  error: postsProvider.latestError,
                  onPostTap: _onPostTap,
                  onLoadMore: () => _loadPosts(),
                  onRetry: () => _loadPosts(refresh: true),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
