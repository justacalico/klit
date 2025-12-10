import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/models.dart';
import '../../pages/post/post_detail_page.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

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

    widget.onPostTap(PostDetailArguments(
      postIds: posts.map((p) => p.id).toList(),
      initialIndex: index >= 0 ? index : 0,
      hasMore: postsProvider.hasMoreHot,
      onLoadMore: () async {
        await postsProvider.loadHotPosts(
          safeMode: settingsProvider.safeMode,
        );
        return postsProvider.hotPosts.map((p) => p.id).toList();
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;

    return Column(
      children: [
        _buildToolbar(context, isDark),
        Expanded(
          child: Consumer<PostsProvider>(
            builder: (context, postsProvider, _) {
              return Column(
                children: [
                  // Time range selector
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TimeRangeSelector(
                      selected: postsProvider.hotTimeRange,
                      options: const ['day', 'week', 'month'],
                      onChanged: (range) {
                        postsProvider.setHotTimeRange(range);
                        _loadPosts(refresh: true);
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

  Widget _buildToolbar(BuildContext context, bool isDark) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      const Color(0xFF2C2C2E).withValues(alpha: 0.8),
                      const Color(0xFF1C1C1E).withValues(alpha: 0.9),
                    ]
                  : [
                      const Color(0xFFFFFFFF).withValues(alpha: 0.8),
                      const Color(0xFFF8F8FA).withValues(alpha: 0.9),
                    ],
            ),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? const Color(0xFF3A3A3C).withValues(alpha: 0.3)
                    : const Color(0xFFD1D1D6).withValues(alpha: 0.5),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              const Icon(CupertinoIcons.flame_fill, color: AppColors.primaryOrange),
              const SizedBox(width: 8),
              const Text(
                'Hot Posts',
                style: TextStyle(
                  fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          _buildGridSizeSelector(isDark),
          const SizedBox(width: 12),
          CupertinoButton(
            padding: const EdgeInsets.all(8),
            onPressed: () => widget.onSearchTap(),
            child: const Icon(CupertinoIcons.search, size: 20),
          ),
          CupertinoButton(
            padding: const EdgeInsets.all(8),
            onPressed: () => _loadPosts(refresh: true),
            child: const Icon(CupertinoIcons.refresh, size: 20),
          ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridSizeSelector(bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          CupertinoIcons.square_grid_2x2,
          size: 16,
          color: CupertinoColors.secondaryLabel,
        ),
        const SizedBox(width: 8),
        CupertinoSlidingSegmentedControl<int>(
          groupValue: _gridColumns,
          children: const {
            2: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('2', style: TextStyle(fontSize: 13)),
            ),
            3: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('3', style: TextStyle(fontSize: 13)),
            ),
            4: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('4', style: TextStyle(fontSize: 13)),
            ),
            5: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('5', style: TextStyle(fontSize: 13)),
            ),
            6: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('6', style: TextStyle(fontSize: 13)),
            ),
          },
          onValueChanged: (value) {
            if (value != null) {
              setState(() => _gridColumns = value);
            }
          },
        ),
      ],
    );
  }
}
