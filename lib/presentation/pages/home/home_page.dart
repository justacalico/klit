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
  static const Color primaryPurple = Color(0xFF8B5CF6);
}

/// Home page with latest posts
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final RefreshController _refreshController = RefreshController();

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
    final settingsProvider = context.read<SettingsProvider>();
    await postsProvider.loadLatestPosts(
      refresh: refresh,
      safeMode: _shouldEnforceSafeMode(context),
      scoreThreshold: settingsProvider.scoreThreshold,
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
    final safeMode = _shouldEnforceSafeMode(context);

    Navigator.of(context).pushNamed(
      AppRoutes.postDetail,
      arguments: PostDetailArguments(
        postIds: posts.map((p) => p.id).toList(),
        initialIndex: index >= 0 ? index : 0,
        hasMore: postsProvider.hasMoreLatest,
        onLoadMore: () async {
          await postsProvider.loadLatestPosts(
            safeMode: safeMode,
            scoreThreshold: settingsProvider.scoreThreshold,
          );
          return postsProvider.latestPosts.map((p) => p.id).toList();
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

    return CupertinoPageScaffold(
      child: Stack(
        children: [
          // Content with custom nav bar
          CustomScrollView(
            slivers: [
              // Modern navigation bar
              _buildNavigationBar(isDark),
              // Content
              SliverFillRemaining(
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
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationBar(bool isDark) {
    return SliverToBoxAdapter(
      child: CupertinoNavigationBar(
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
        middle: Text(
          'Home',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildToolbarButton(
              icon: CupertinoIcons.square_grid_2x2,
              isDark: isDark,
              onTap: () {}, // Grid view indicator only
            ),
            const SizedBox(width: 8),
            _buildToolbarButton(
              icon: CupertinoIcons.search,
              isDark: isDark,
              onTap: _openSearch,
            ),
          ],
        ),
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
