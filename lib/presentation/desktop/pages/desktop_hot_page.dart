import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../../data/models/models.dart';
import '../../pages/post/post_detail_page.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../widgets/desktop_toolbar.dart';

/// Desktop hot page with trending posts
class DesktopHotPage extends StatefulWidget {
  final Function(PostDetailArguments) onPostTap;
  final Function([String?]) onSearchTap;

  const DesktopHotPage({
    super.key,
    required this.onPostTap,
    required this.onSearchTap,
  });

  @override
  State<DesktopHotPage> createState() => _DesktopHotPageState();
}

class _DesktopHotPageState extends State<DesktopHotPage> {
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
    await postsProvider.loadHotPosts(
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
    final posts = postsProvider.hotPosts;
    final index = posts.indexWhere((p) => p.id == post.id);

    widget.onPostTap(
      PostDetailArguments(
        postIds: posts.map((p) => p.id).toList(),
        initialIndex: index >= 0 ? index : 0,
        hasMore: postsProvider.hasMoreHot,
        onLoadMore: () async {
          await postsProvider.loadHotPosts(safeMode: settingsProvider.safeMode);
          return postsProvider.hotPosts.map((p) => p.id).toList();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DesktopToolbar(
          title: 'Hot Posts',
          icon: CupertinoIcons.flame_fill,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: DesktopTimeRangeSelector(
                      selected: postsProvider.hotTimeRange,
                      options: const ['day', 'week', 'month'],
                      customDate: postsProvider.hotCustomDate,
                      onChanged: (range) {
                        final settingsProvider = context
                            .read<SettingsProvider>();
                        postsProvider.setHotTimeRange(
                          range,
                          safeMode: settingsProvider.safeMode,
                        );
                      },
                      onDateSelected: (date) {
                        final settingsProvider = context
                            .read<SettingsProvider>();
                        postsProvider.setHotCustomDate(
                          date,
                          safeMode: settingsProvider.safeMode,
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: SmartRefresher(
                      controller: _refreshController,
                      enablePullDown: true,
                      enablePullUp: postsProvider.hasMoreHot,
                      onRefresh: () => _loadPosts(refresh: true),
                      onLoading: () => _loadPosts(),
                      child: PostsGrid(
                        posts: postsProvider.hotPosts,
                        columns: _gridColumns,
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
      ],
    );
  }
}
