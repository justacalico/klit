import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../../app/routes.dart';
import '../../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../post/post_detail_page.dart';

/// Design constants for the purple/indigo mobile theme
class _ThemeColors {
  static const Color primaryIndigo = Color(0xFF6366F1);
  static const Color primaryPurple = Color(0xFF8B5CF6);
}

/// Hot page with trending posts
class HotPage extends StatefulWidget {
  const HotPage({super.key});

  @override
  State<HotPage> createState() => _HotPageState();
}

class _HotPageState extends State<HotPage> {
  final RefreshController _refreshController = RefreshController();
  bool _isGridView = true;

  /// Check if safe mode should be enforced (guest mode OR safe mode setting)
  bool _shouldEnforceSafeMode(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    return authProvider.isGuest || settingsProvider.safeMode;
  }

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
    await postsProvider.loadHotPosts(
      refresh: refresh,
      safeMode: _shouldEnforceSafeMode(context),
    );

    if (refresh) {
      _refreshController.refreshCompleted();
    }
  }

  void _onPostTap(Post post) {
    final postsProvider = context.read<PostsProvider>();
    final posts = postsProvider.hotPosts;
    final index = posts.indexWhere((p) => p.id == post.id);
    final safeMode = _shouldEnforceSafeMode(context);

    Navigator.of(context).pushNamed(
      AppRoutes.postDetail,
      arguments: PostDetailArguments(
        postIds: posts.map((p) => p.id).toList(),
        initialIndex: index >= 0 ? index : 0,
        hasMore: postsProvider.hasMoreHot,
        onLoadMore: () async {
          await postsProvider.loadHotPosts(safeMode: safeMode);
          return postsProvider.hotPosts.map((p) => p.id).toList();
        },
      ),
    );
  }

  void _openSearch() {
    Navigator.of(context).pushNamed(AppRoutes.search);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final gridSize = context.watch<SettingsProvider>().gridSize;

    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          _buildNavigationBar(isDark),
          SliverToBoxAdapter(
            child: Consumer<PostsProvider>(
              builder: (context, postsProvider, _) {
                return TimeRangeSelector(
                  selected: postsProvider.hotTimeRange,
                  options: const ['day', 'week', 'month'],
                  onChanged: (range) {
                    postsProvider.setHotTimeRange(range);
                  },
                );
              },
            ),
          ),
          SliverFillRemaining(
            child: Consumer<PostsProvider>(
              builder: (context, postsProvider, _) {
                return SmartRefresher(
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationBar(bool isDark) {
    return CupertinoSliverNavigationBar(
      transitionBetweenRoutes: false,
      backgroundColor: isDark
          ? const Color(0xFF1C1C1E).withValues(alpha: 0.85)
          : CupertinoColors.white.withValues(alpha: 0.85),
      border: Border(
        bottom: BorderSide(
          color: isDark
              ? _ThemeColors.primaryPurple.withValues(alpha: 0.15)
              : _ThemeColors.primaryPurple.withValues(alpha: 0.1),
          width: 0.5,
        ),
      ),
      largeTitle: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _ThemeColors.primaryIndigo,
                  _ThemeColors.primaryPurple,
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: _ThemeColors.primaryPurple.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              CupertinoIcons.flame_fill,
              size: 16,
              color: CupertinoColors.white,
            ),
          ),
          const SizedBox(width: 10),
          const Text('Hot'),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToolbarButton(
            icon: _isGridView ? CupertinoIcons.list_bullet : CupertinoIcons.square_grid_2x2,
            isDark: isDark,
            onTap: () => setState(() => _isGridView = !_isGridView),
          ),
          const SizedBox(width: 8),
          _buildToolbarButton(
            icon: CupertinoIcons.search,
            isDark: isDark,
            onTap: _openSearch,
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF2C2C2E).withValues(alpha: 0.6)
              : const Color(0xFFF3F4F6).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark
                ? _ThemeColors.primaryPurple.withValues(alpha: 0.2)
                : _ThemeColors.primaryPurple.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark
              ? CupertinoColors.white.withValues(alpha: 0.8)
              : const Color(0xFF374151),
        ),
      ),
    );
  }
}
