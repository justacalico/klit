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
                  columns: _gridColumns,
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

  Widget _buildToolbar(BuildContext context, bool isDark) {
    const primaryPurple = Color(0xFF8B5CF6);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF18181B).withValues(alpha: 0.85),
                      const Color(0xFF1F1F23).withValues(alpha: 0.9),
                    ]
                  : [
                      const Color(0xFFFFFFFF).withValues(alpha: 0.85),
                      const Color(0xFFFAFAFC).withValues(alpha: 0.9),
                    ],
            ),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? primaryPurple.withValues(alpha: 0.15)
                    : primaryPurple.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Page icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF6366F1),
                      Color(0xFF8B5CF6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: primaryPurple.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.house_fill,
                  size: 16,
                  color: CupertinoColors.white,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Latest Posts',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: isDark ? CupertinoColors.white : const Color(0xFF1F2937),
                ),
              ),
              const Spacer(),
              // Grid size selector
              _buildGridSizeSelector(isDark),
              const SizedBox(width: 16),
              // Search button
              _buildToolbarButton(
                icon: CupertinoIcons.search,
                onPressed: () => widget.onSearchTap(),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              // Refresh button
              _buildToolbarButton(
                icon: CupertinoIcons.refresh,
                onPressed: () => _loadPosts(refresh: true),
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF2C2C2E).withValues(alpha: 0.6)
              : const Color(0xFFF3F4F6).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark
                ? const Color(0xFF3A3A3C).withValues(alpha: 0.3)
                : const Color(0xFFE5E7EB).withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isDark ? CupertinoColors.white : const Color(0xFF374151),
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
