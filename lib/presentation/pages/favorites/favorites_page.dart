import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../../data/models/models.dart';
import '../../../data/services/services.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../post/post_detail_page.dart';

/// Design constants for the purple/indigo mobile theme
class _ThemeColors {
  static const Color primaryIndigo = Color(0xFF6366F1);
  static const Color primaryPurple = Color(0xFF8B5CF6);
}

/// Page displaying user's favorited posts
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<Post> _favorites = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites({bool refresh = false}) async {
    final authProvider = context.read<AuthProvider>();
    final account = authProvider.currentAccount;

    // Guest users can't have favorites
    if (authProvider.isGuest) {
      setState(() {
        _isLoading = false;
        _error = 'Sign in to save and view your favorites';
      });
      return;
    }

    if (account == null) {
      setState(() {
        _isLoading = false;
        _error = 'Not logged in';
      });
      return;
    }

    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _isLoading = true;
        _error = null;
      });
    }

    final apiService = context.read<ApiService>();
    final settingsProvider = context.read<SettingsProvider>();
    final result = await apiService.getFavorites(
      username: account.username,
      page: _currentPage,
      safeMode: settingsProvider.safeMode,
    );

    if (mounted) {
      result.when(
        success: (posts) {
          setState(() {
            if (refresh || _currentPage == 1) {
              _favorites = posts;
            } else {
              _favorites.addAll(posts);
            }
            _hasMore = posts.length >= 50;
            _isLoading = false;
            _isLoadingMore = false;
          });
        },
        failure: (error) {
          setState(() {
            _error = error.message;
            _isLoading = false;
            _isLoadingMore = false;
          });
        },
      );
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    await _loadFavorites();
  }

  void _onPostTap(Post post) {
    final index = _favorites.indexWhere((p) => p.id == post.id);
    Navigator.of(context).pushNamed(
      '/post',
      arguments: PostDetailArguments(
        postIds: _favorites.map((p) => p.id).toList(),
        initialIndex: index >= 0 ? index : 0,
        hasMore: _hasMore,
        onLoadMore: () async {
          await _loadMore();
          return _favorites.map((p) => p.id).toList();
        },
      ),
    );
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
          SliverFillRemaining(
            child: _buildContent(isDark, gridSize),
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
      middle: Text(
        'Favorites',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? CupertinoColors.white : CupertinoColors.black,
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
              CupertinoIcons.heart_fill,
              size: 16,
              color: CupertinoColors.white,
            ),
          ),
          const SizedBox(width: 10),
          const Text('Favorites'),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark, int gridSize) {
    if (_isLoading && _favorites.isEmpty) {
      return const Center(child: CupertinoActivityIndicator(radius: 16));
    }

    if (_error != null && _favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 48,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: CupertinoColors.systemGrey),
            ),
            const SizedBox(height: 16),
            CupertinoButton.filled(
              onPressed: () => _loadFavorites(refresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.heart,
              size: 64,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No favorites yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Posts you favorite will appear here',
              style: TextStyle(color: CupertinoColors.systemGrey),
            ),
          ],
        ),
      );
    }

    return PostsGrid(
      posts: _favorites,
      columns: gridSize,
      isLoading: _isLoadingMore,
      hasMore: _hasMore,
      onPostTap: _onPostTap,
      onLoadMore: _loadMore,
      onRetry: () => _loadFavorites(refresh: true),
    );
  }
}
