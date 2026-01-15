import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/constants.dart';
import '../../../data/models/models.dart';
import '../../../data/services/services.dart';
import '../../pages/post/post_detail_page.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../widgets/desktop_toolbar.dart';

/// Desktop favorites page with larger grid
class DesktopFavoritesPage extends StatefulWidget {
  final Function(PostDetailArguments) onPostTap;

  const DesktopFavoritesPage({super.key, required this.onPostTap});

  @override
  State<DesktopFavoritesPage> createState() => _DesktopFavoritesPageState();
}

class _DesktopFavoritesPageState extends State<DesktopFavoritesPage> {
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
    widget.onPostTap(
      PostDetailArguments(
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

    return Column(
      children: [
        _buildToolbar(isDark),
        Expanded(child: _buildContent(isDark)),
      ],
    );
  }

  Widget _buildToolbar(bool isDark) {
    return DesktopToolbar(
      title: 'Favorites',
      icon: CupertinoIcons.heart_fill,
      actions: [
        DesktopToolbarButton(
          icon: CupertinoIcons.refresh,
          tooltip: 'Refresh',
          onPressed: () => _loadFavorites(refresh: true),
        ),
      ],
    );
  }

  Widget _buildContent(bool isDark) {
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
            Icon(
              CupertinoIcons.heart,
              size: 64,
              color: AppColors.explicitColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No favorites yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Posts you favorite will appear here',
              style: TextStyle(fontSize: 15, color: CupertinoColors.systemGrey),
            ),
          ],
        ),
      );
    }

    return PostsGrid(
      posts: _favorites,
      isLoading: _isLoadingMore,
      hasMore: _hasMore,
      onPostTap: _onPostTap,
      onLoadMore: _loadMore,
      onRetry: () => _loadFavorites(refresh: true),
    );
  }
}
