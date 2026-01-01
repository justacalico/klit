import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart'
    show CachedNetworkImage, CachedNetworkImageProvider;
import 'package:confetti/confetti.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart'
    show Colors, Theme, ThemeData, Brightness;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import '../../../app/routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/extensions.dart';
import '../../../data/models/models.dart';
import '../../../data/services/services.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/widgets.dart' hide Colors;

/// Arguments for navigating to post detail with swipe support
class PostDetailArguments {
  final List<int> postIds;
  final int initialIndex;

  /// Callback to load more posts, returns new post IDs
  final Future<List<int>> Function()? onLoadMore;

  /// Whether there are more posts to load
  final bool hasMore;

  const PostDetailArguments({
    required this.postIds,
    required this.initialIndex,
    this.onLoadMore,
    this.hasMore = false,
  });
}

/// Post detail page with swipe navigation
class PostDetailPage extends StatefulWidget {
  final List<int> postIds;
  final int initialIndex;

  /// Optional callback for searching tags (used in desktop mode)
  final void Function(String tag)? onSearchTag;

  /// Callback to load more posts, returns new post IDs
  final Future<List<int>> Function()? onLoadMore;

  /// Whether there are more posts to load
  final bool hasMore;

  const PostDetailPage({
    super.key,
    required this.postIds,
    required this.initialIndex,
    this.onSearchTag,
    this.onLoadMore,
    this.hasMore = false,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  late PageController _pageController;
  late int _currentIndex;
  late List<int> _postIds;
  late bool _hasMore;
  bool _isLoadingMore = false;
  final Map<int, Post?> _loadedPosts = {};
  final Map<int, bool> _loadingStates = {};
  final Map<int, String?> _errorStates = {};

  // Action states per post index
  final Map<int, bool> _isFavorited = {};
  final Map<int, int?> _userVote =
      {}; // 1 = upvoted, -1 = downvoted, null = no vote
  final Map<int, PostScore?> _updatedScores = {};
  final Map<int, bool> _isVoting = {};
  final Map<int, bool> _isTogglingFavorite = {};

  // Confetti controller for favorite animation
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _postIds = List.from(widget.postIds);
    _hasMore = widget.hasMore;
    _pageController = PageController(initialPage: _currentIndex);
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    _loadPost(_currentIndex);
    _preloadAdjacentPosts();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _preloadAdjacentPosts() {
    if (_currentIndex > 0) {
      _loadPost(_currentIndex - 1);
    }
    if (_currentIndex < _postIds.length - 1) {
      _loadPost(_currentIndex + 1);
    }

    // Load more posts when approaching the end (3 posts before the end)
    if (_hasMore &&
        !_isLoadingMore &&
        widget.onLoadMore != null &&
        _currentIndex >= _postIds.length - 3) {
      _loadMorePosts();
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMore || widget.onLoadMore == null) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final newPostIds = await widget.onLoadMore!();
      if (mounted) {
        setState(() {
          // Add only new post IDs that aren't already in the list
          for (final id in newPostIds) {
            if (!_postIds.contains(id)) {
              _postIds.add(id);
            }
          }
          _hasMore = newPostIds.isNotEmpty;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _loadPost(int index, {bool forceRefresh = false}) async {
    if (index < 0 || index >= _postIds.length) return;
    if (_loadingStates[index] == true) return;
    if (!forceRefresh && _loadedPosts.containsKey(index)) return;

    setState(() {
      _loadingStates[index] = true;
      _errorStates[index] = null;
    });

    final postId = _postIds[index];
    final apiService = context.read<ApiService>();
    final result = await apiService.getPostById(postId);

    result.when(
      success: (post) {
        if (mounted) {
          setState(() {
            _loadedPosts[index] = post;
            _loadingStates[index] = false;
            _isFavorited[index] = post.isFavorited;
            _updatedScores[index] = post.score;
          });
        }
      },
      failure: (error) {
        if (mounted) {
          setState(() {
            _errorStates[index] = error.message;
            _loadingStates[index] = false;
          });
        }
      },
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    _loadPost(index);
    _preloadAdjacentPosts();
  }

  int get _currentPostId => _postIds[_currentIndex];
  Post? get _currentPost => _loadedPosts[_currentIndex];

  Future<void> _refreshCurrentPost() async {
    await _loadPost(_currentIndex, forceRefresh: true);
  }

  Future<void> _vote(int index, int score) async {
    final post = _loadedPosts[index];
    if (post == null || _isVoting[index] == true) return;

    setState(() {
      _isVoting[index] = true;
    });

    final apiService = context.read<ApiService>();
    final result = await apiService.votePost(post.id, score);

    if (mounted) {
      result.when(
        success: (newScore) {
          setState(() {
            _updatedScores[index] = newScore;
            _userVote[index] = score;
            _isVoting[index] = false;
          });
        },
        failure: (error) {
          setState(() {
            _isVoting[index] = false;
          });
          _showError(error.message);
        },
      );
    }
  }

  Future<void> _toggleFavorite(int index) async {
    final post = _loadedPosts[index];
    if (post == null || _isTogglingFavorite[index] == true) return;

    final isFav = _isFavorited[index] ?? post.isFavorited;

    setState(() {
      _isTogglingFavorite[index] = true;
    });

    final apiService = context.read<ApiService>();
    final result = isFav
        ? await apiService.removeFavorite(post.id)
        : await apiService.addFavorite(post.id);

    if (mounted) {
      result.when(
        success: (_) {
          setState(() {
            _isFavorited[index] = !isFav;
            _isTogglingFavorite[index] = false;
          });

          // Play confetti animation when adding favorite
          if (!isFav) {
            final settings = context.read<SettingsProvider>();
            if (settings.confettiOnFavorite) {
              _confettiController.play();
            }

            // Auto-upvote when favoriting if the setting is enabled
            if (settings.upvoteWhenFavorited) {
              final currentVote = _userVote[index];
              // Only upvote if not already upvoted
              if (currentVote != 1) {
                _vote(index, 1);
              }
            }
          }
        },
        failure: (error) {
          setState(() {
            _isTogglingFavorite[index] = false;
          });
          _showError(error.message);
        },
      );
    }
  }

  void _showComments(int index) {
    final post = _loadedPosts[index];
    if (post == null) return;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => _CommentsSheet(postId: post.id),
    );
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _openFullMedia() {
    if (_currentPost == null) return;

    // Handle videos with the video viewer
    if (_currentPost!.isVideo) {
      if (_currentPost!.file.url == null) return;
      Navigator.of(context).push(
        CupertinoPageRoute(
          fullscreenDialog: true,
          builder: (context) => FullScreenVideoViewer(
            videoUrl: _currentPost!.file.url!,
            thumbnailUrl: _currentPost!.preview.url,
          ),
        ),
      );
    } else {
      if (_currentPost?.file.url == null) return;
      Navigator.of(context).push(
        CupertinoPageRoute(
          fullscreenDialog: true,
          builder: (context) => _FullScreenImageViewer(
            imageUrl: _currentPost!.file.url!,
            heroTag: 'post_${_currentPost!.id}',
          ),
        ),
      );
    }
  }

  void _searchTag(String tag) {
    if (widget.onSearchTag != null) {
      widget.onSearchTag!(tag);
    } else {
      Navigator.of(context).pushNamed(AppRoutes.search, arguments: tag);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final isDark =
        settingsProvider.themeMode == 2 ||
        settingsProvider.themeMode == 3 ||
        (settingsProvider.themeMode == 0 &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final isOled = settingsProvider.themeMode == 3;
    final hasMultiplePosts = _postIds.length > 1;

    return CupertinoPageScaffold(
      backgroundColor: isOled
          ? CupertinoColors.black
          : isDark
          ? AppColors.darkBackground
          : AppColors.lightSecondaryBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isOled
            ? CupertinoColors.black.withValues(alpha: 0.8)
            : isDark
            ? CupertinoColors.darkBackgroundGray.withValues(alpha: 0.8)
            : CupertinoColors.systemBackground.withValues(alpha: 0.8),
        middle: Text(
          hasMultiplePosts
              ? 'Post #$_currentPostId (${_currentIndex + 1}/${_postIds.length})'
              : 'Post #$_currentPostId',
        ),
        trailing: _currentPost != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _loadingStates[_currentIndex] == true
                        ? null
                        : _refreshCurrentPost,
                    child: Icon(
                      CupertinoIcons.refresh,
                      color: _loadingStates[_currentIndex] == true
                          ? CupertinoColors.systemGrey
                          : null,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _showMoreOptions(),
                    child: const Icon(CupertinoIcons.ellipsis),
                  ),
                ],
              )
            : null,
      ),
      child: Stack(
        children: [
          SafeArea(
            child: hasMultiplePosts
                ? PageView.builder(
                    controller: _pageController,
                    itemCount: _postIds.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, index) =>
                        _buildPageContent(index, isDark, isOled),
                  )
                : _buildPageContent(0, isDark, isOled),
          ),
          // Confetti overlay - positioned near the favorite button area
          Align(
            alignment: const Alignment(0.3, 0.45),
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              maxBlastForce: 20,
              minBlastForce: 8,
              emissionFrequency: 0.05,
              numberOfParticles: 25,
              gravity: 0.3,
              colors: const [
                Color(0xFFFF6B9D), // Pink
                Color(0xFFFF8E53), // Orange
                Color(0xFFFFD93D), // Yellow
                Color(0xFF6BCB77), // Green
                Color(0xFF4D96FF), // Blue
                Color(0xFFC9B1FF), // Purple
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(int index, bool isDark, bool isOled) {
    final post = _loadedPosts[index];
    final isLoading = _loadingStates[index] == true;
    final error = _errorStates[index];

    if (isLoading) {
      return const FullPageLoading(message: 'Loading post...');
    }

    if (error != null) {
      return ErrorState(message: error, onRetry: () => _loadPost(index));
    }

    if (post == null) {
      return const EmptyState(
        icon: CupertinoIcons.photo,
        title: 'Post not found',
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImage(post),
          const SizedBox(height: 16),
          _buildActionBar(index, post, isDark, isOled),
          const SizedBox(height: 16),
          _buildStats(post, index, isDark, isOled),
          if (post.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildDescription(post, isDark, isOled),
          ],
          const SizedBox(height: 16),
          _buildTags(post, isDark, isOled),
          const SizedBox(height: 16),
          _buildMetadata(post, isDark, isOled),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLiquidGlassContainer({
    required bool isDark,
    required bool isOled,
    required Widget child,
    EdgeInsets? margin,
    EdgeInsets? padding,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isOled
                    ? [
                        Colors.white.withValues(alpha: 0.06),
                        Colors.white.withValues(alpha: 0.02),
                      ]
                    : isDark
                    ? [
                        Colors.white.withValues(alpha: 0.12),
                        Colors.white.withValues(alpha: 0.06),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.8),
                        Colors.white.withValues(alpha: 0.6),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isOled
                    ? Colors.white.withValues(alpha: 0.08)
                    : isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.5),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isOled ? 0.4 : 0.1),
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildActionBar(int index, Post post, bool isDark, bool isOled) {
    final authProvider = context.watch<AuthProvider>();
    final isGuest = authProvider.isGuest;
    
    // Don't show action bar for guest users
    if (isGuest) {
      return const SizedBox.shrink();
    }
    
    final isFav = _isFavorited[index] ?? post.isFavorited;
    final userVote = _userVote[index];
    final isVoting = _isVoting[index] == true;
    final isTogglingFav = _isTogglingFavorite[index] == true;
    final leftHandedMode = context.watch<SettingsProvider>().leftHandedMode;

    // Comment button is always available
    final commentButton = _buildGlassActionButton(
      icon: CupertinoIcons.chat_bubble,
      activeIcon: CupertinoIcons.chat_bubble_fill,
      label: '${post.commentCount}',
      isActive: false,
      isLoading: false,
      color: CupertinoColors.systemBlue,
      isDark: isDark,
      onTap: () => _showComments(index),
    );

    final upvoteButton = _buildGlassActionButton(
      icon: CupertinoIcons.arrow_up_circle,
      activeIcon: CupertinoIcons.arrow_up_circle_fill,
      label: 'Upvote',
      isActive: userVote == 1,
      isLoading: isVoting,
      color: AppColors.safeColor,
      isDark: isDark,
      onTap: () => _vote(index, userVote == 1 ? 0 : 1),
    );

    final downvoteButton = _buildGlassActionButton(
      icon: CupertinoIcons.arrow_down_circle,
      activeIcon: CupertinoIcons.arrow_down_circle_fill,
      label: 'Downvote',
      isActive: userVote == -1,
      isLoading: isVoting,
      color: AppColors.explicitColor,
      isDark: isDark,
      onTap: () => _vote(index, userVote == -1 ? 0 : -1),
    );

    final favoriteButton = _buildGlassActionButton(
      icon: CupertinoIcons.heart,
      activeIcon: CupertinoIcons.heart_fill,
      label: 'Favorite',
      isActive: isFav,
      isLoading: isTogglingFav,
      color: CupertinoColors.systemPink,
      isDark: isDark,
      onTap: () => _toggleFavorite(index),
    );

    // Left-handed mode: Favorite, Upvote, Downvote, Comment
    // Normal mode: Upvote, Downvote, Favorite, Comment
    final actions = leftHandedMode
        ? [favoriteButton, upvoteButton, downvoteButton, commentButton]
        : [upvoteButton, downvoteButton, favoriteButton, commentButton];

    return _buildLiquidGlassContainer(
      isDark: isDark,
      isOled: isOled,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: actions,
      ),
    );
  }

  Widget _buildGlassActionButton({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
    required bool isLoading,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onPressed: isLoading
          ? null
          : () {
              HapticFeedback.lightImpact();
              onTap();
            },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isActive
                    ? [
                        color.withValues(alpha: 0.3),
                        color.withValues(alpha: 0.15),
                      ]
                    : [
                        (isDark ? Colors.white : Colors.black).withValues(
                          alpha: 0.1,
                        ),
                        (isDark ? Colors.white : Colors.black).withValues(
                          alpha: 0.05,
                        ),
                      ],
              ),
              shape: BoxShape.circle,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
            child: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CupertinoActivityIndicator(color: color),
                  )
                : Icon(
                    isActive ? activeIcon : icon,
                    size: 24,
                    color: isActive
                        ? color
                        : isDark
                        ? CupertinoColors.white.withValues(alpha: 0.6)
                        : CupertinoColors.systemGrey,
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive
                  ? color
                  : isDark
                  ? CupertinoColors.white.withValues(alpha: 0.6)
                  : CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(Post post) {
    // Handle videos with the video player
    if (post.isVideo && post.file.url != null) {
      return AspectRatio(
        aspectRatio: post.file.aspectRatio.clamp(0.5, 2.0),
        child: VideoPlayerWidget(
          key: ValueKey('video_${post.id}_${post.file.url}'),
          videoUrl: post.file.url!,
          thumbnailUrl: post.preview.url,
          autoPlay: true,
          looping: true,
          showControls: true,
          aspectRatio: post.file.aspectRatio,
        ),
      );
    }

    // For GIFs, use the full file URL to preserve animation
    // For other images, use sample if available
    final imageUrl = post.isGif 
        ? post.file.url 
        : (post.sample.has ? post.sample.url : post.preview.url);

    if (imageUrl == null) {
      return AspectRatio(
        aspectRatio: post.file.aspectRatio,
        child: Container(
          color: CupertinoColors.systemGrey5,
          child: const Center(
            child: Icon(
              CupertinoIcons.photo,
              size: 64,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _openFullMedia,
      child: Hero(
        tag: 'post_${post.id}',
        child: AspectRatio(
          aspectRatio: post.file.aspectRatio.clamp(0.5, 2.0),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => Container(
              color: CupertinoColors.systemGrey5,
              child: const Center(child: CupertinoActivityIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              color: CupertinoColors.systemGrey5,
              child: const Center(
                child: Icon(
                  CupertinoIcons.exclamationmark_triangle,
                  size: 48,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStats(Post post, int index, bool isDark, bool isOled) {
    final score = _updatedScores[index] ?? post.score;
    final isFav = _isFavorited[index] ?? post.isFavorited;
    final favCount = isFav != post.isFavorited
        ? (isFav ? post.favCount + 1 : post.favCount - 1)
        : post.favCount;

    return _buildLiquidGlassContainer(
      isDark: isDark,
      isOled: isOled,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildGlassStatItem(
            icon: CupertinoIcons.arrow_up,
            value: score.total.toString(),
            label: 'Score',
            color: score.total >= 0
                ? AppColors.safeColor
                : AppColors.explicitColor,
            isDark: isDark,
          ),
          _buildGlassStatItem(
            icon: CupertinoIcons.heart_fill,
            value: favCount.compact,
            label: 'Favorites',
            color: CupertinoColors.systemPink,
            isDark: isDark,
          ),
          _buildGlassStatItem(
            icon: CupertinoIcons.chat_bubble_fill,
            value: post.commentCount.toString(),
            label: 'Comments',
            color: CupertinoColors.systemBlue,
            isDark: isDark,
          ),
          _buildRatingBadge(post, isDark),
        ],
      ),
    );
  }

  Widget _buildGlassStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.25),
                color.withValues(alpha: 0.1),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10),
            ],
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? CupertinoColors.white.withValues(alpha: 0.6)
                : CupertinoColors.systemGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingBadge(Post post, bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                post.ratingColor,
                post.ratingColor.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: post.ratingColor.withValues(alpha: 0.4),
                blurRadius: 10,
              ),
            ],
          ),
          child: Text(
            post.rating.toUpperCase(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          post.ratingLabel,
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? CupertinoColors.white.withValues(alpha: 0.6)
                : CupertinoColors.systemGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(Post post, bool isDark, bool isOled) {
    return _buildLiquidGlassContainer(
      isDark: isDark,
      isOled: isOled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      CupertinoColors.systemIndigo.withValues(alpha: 0.3),
                      CupertinoColors.systemIndigo.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  CupertinoIcons.doc_text_fill,
                  size: 18,
                  color: isDark
                      ? CupertinoColors.systemIndigo.withValues(alpha: 0.8)
                      : CupertinoColors.systemIndigo,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Theme(
            data: ThemeData(
              brightness: isDark ? Brightness.dark : Brightness.light,
            ),
            child: MarkdownBody(
              data: post.description,
              selectable: true,
              shrinkWrap: true,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                  fontSize: 15,
                  color: isDark
                      ? CupertinoColors.white.withValues(alpha: 0.8)
                      : CupertinoColors.label,
                ),
                a: TextStyle(
                  color: CupertinoColors.systemBlue,
                  decoration: TextDecoration.underline,
                ),
                code: TextStyle(
                  fontSize: 13,
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                  color: isDark
                      ? CupertinoColors.white.withValues(alpha: 0.9)
                      : CupertinoColors.black,
                ),
                codeblockDecoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                blockquoteDecoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: CupertinoColors.systemBlue.withValues(alpha: 0.5),
                      width: 3,
                    ),
                  ),
                ),
                blockquotePadding: const EdgeInsets.only(left: 12),
                h1: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
                h2: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
                h3: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
                listBullet: TextStyle(
                  color: isDark
                      ? CupertinoColors.white.withValues(alpha: 0.8)
                      : CupertinoColors.label,
                ),
              ),
              onTapLink: (text, href, title) {
                // Handle link taps - could open in browser
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTags(Post post, bool isDark, bool isOled) {
    return _buildLiquidGlassContainer(
      isDark: isDark,
      isOled: isOled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      CupertinoColors.systemOrange.withValues(alpha: 0.3),
                      CupertinoColors.systemOrange.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  CupertinoIcons.tag_fill,
                  size: 18,
                  color: isDark
                      ? CupertinoColors.systemOrange.withValues(alpha: 0.8)
                      : CupertinoColors.systemOrange,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Tags',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CategorizedTagList(tags: post.tags, onTagTap: _searchTag),
        ],
      ),
    );
  }

  Widget _buildMetadata(Post post, bool isDark, bool isOled) {
    return _buildLiquidGlassContainer(
      isDark: isDark,
      isOled: isOled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      CupertinoColors.systemTeal.withValues(alpha: 0.3),
                      CupertinoColors.systemTeal.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  CupertinoIcons.info_circle_fill,
                  size: 18,
                  color: isDark
                      ? CupertinoColors.systemTeal.withValues(alpha: 0.8)
                      : CupertinoColors.systemTeal,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Details',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMetadataRow('ID', '#${post.id}', isDark),
          _buildMetadataRow('Posted', post.createdAt.relativeTime, isDark),
          _buildMetadataRow(
            'Resolution',
            '${post.file.width}x${post.file.height}',
            isDark,
          ),
          _buildMetadataRow('File Size', post.file.size.fileSize, isDark),
          _buildMetadataRow('Type', post.file.ext.toUpperCase(), isDark),
          if (post.sources.isNotEmpty)
            _buildMetadataRow(
              'Sources',
              '${post.sources.length} source(s)',
              isDark,
              isLast: true,
            ),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(
    String label,
    String value,
    bool isDark, {
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                  width: 0.5,
                ),
              ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? CupertinoColors.white.withValues(alpha: 0.6)
                  : CupertinoColors.systemGrey,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
            ),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _openFullMedia();
            },
            child: Text(
              _currentPost?.isVideo == true
                  ? 'View Full Video'
                  : 'View Full Resolution',
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Share'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Download'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}

class _FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const _FullScreenImageViewer({required this.imageUrl, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black.withValues(alpha: 0.5),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.xmark, color: CupertinoColors.white),
        ),
      ),
      child: Hero(
        tag: heroTag,
        child: PhotoView(
          imageProvider: CachedNetworkImageProvider(imageUrl),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3,
          backgroundDecoration: const BoxDecoration(
            color: CupertinoColors.black,
          ),
          loadingBuilder: (context, event) => const Center(
            child: CupertinoActivityIndicator(color: CupertinoColors.white),
          ),
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 48,
              color: CupertinoColors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// Comments sheet with liquid glass design
class _CommentsSheet extends StatefulWidget {
  final int postId;

  const _CommentsSheet({required this.postId});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  List<Comment> _comments = [];
  bool _isLoading = true;
  String? _error;
  final _commentController = TextEditingController();
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final apiService = context.read<ApiService>();
    final result = await apiService.getComments(widget.postId);

    if (mounted) {
      result.when(
        success: (comments) {
          setState(() {
            _comments = comments;
            _isLoading = false;
          });
        },
        failure: (error) {
          setState(() {
            _error = error.message;
            _isLoading = false;
          });
        },
      );
    }
  }

  Future<void> _postComment() async {
    final body = _commentController.text.trim();
    if (body.isEmpty || _isPosting) return;

    setState(() {
      _isPosting = true;
    });

    final apiService = context.read<ApiService>();
    final result = await apiService.postComment(widget.postId, body);

    if (mounted) {
      result.when(
        success: (comment) {
          setState(() {
            _comments.insert(0, comment);
            _commentController.clear();
            _isPosting = false;
          });
        },
        failure: (error) {
          setState(() {
            _isPosting = false;
          });
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Error'),
              content: Text(error.message),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final isDark =
        settingsProvider.themeMode == 2 ||
        settingsProvider.themeMode == 3 ||
        (settingsProvider.themeMode == 0 &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final isOled = settingsProvider.themeMode == 3;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isOled
                  ? [Colors.black.withValues(alpha: 0.95), Colors.black]
                  : isDark
                  ? [
                      AppColors.darkBackground.withValues(alpha: 0.95),
                      AppColors.darkBackground,
                    ]
                  : [
                      CupertinoColors.systemBackground.withValues(alpha: 0.95),
                      CupertinoColors.systemBackground,
                    ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(
                color: isOled
                    ? Colors.white.withValues(alpha: 0.08)
                    : isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.5),
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.3)
                      : CupertinoColors.systemGrey3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                CupertinoColors.systemBlue.withValues(
                                  alpha: 0.3,
                                ),
                                CupertinoColors.systemBlue.withValues(
                                  alpha: 0.1,
                                ),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            CupertinoIcons.chat_bubble_2_fill,
                            size: 18,
                            color: isDark
                                ? CupertinoColors.systemBlue.withValues(
                                    alpha: 0.8,
                                  )
                                : CupertinoColors.systemBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Comments',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? CupertinoColors.white
                                : CupertinoColors.black,
                          ),
                        ),
                      ],
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.xmark,
                          size: 18,
                          color: isDark
                              ? CupertinoColors.white.withValues(alpha: 0.6)
                              : CupertinoColors.systemGrey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 0.5,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
              ),
              // Comments list
              Expanded(child: _buildCommentsList(isDark, isOled)),
              // Comment input
              _buildCommentInput(isDark, isOled, bottomPadding),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentInput(bool isDark, bool isOled, double bottomPadding) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: 12 + bottomPadding,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isOled
                  ? [
                      Colors.white.withValues(alpha: 0.05),
                      Colors.white.withValues(alpha: 0.02),
                    ]
                  : isDark
                  ? [
                      Colors.white.withValues(alpha: 0.08),
                      Colors.white.withValues(alpha: 0.04),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.9),
                      Colors.white.withValues(alpha: 0.8),
                    ],
            ),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: CupertinoTextField(
                  controller: _commentController,
                  placeholder: 'Write a comment...',
                  maxLines: 3,
                  minLines: 1,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.08),
                      width: 0.5,
                    ),
                  ),
                  style: TextStyle(
                    color: isDark
                        ? CupertinoColors.white
                        : CupertinoColors.black,
                  ),
                  placeholderStyle: TextStyle(
                    color: isDark
                        ? CupertinoColors.white.withValues(alpha: 0.4)
                        : CupertinoColors.systemGrey,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _isPosting ? null : _postComment,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        CupertinoColors.systemBlue,
                        CupertinoColors.systemBlue.withValues(alpha: 0.8),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.systemBlue.withValues(
                          alpha: 0.4,
                        ),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: _isPosting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CupertinoActivityIndicator(
                            color: CupertinoColors.white,
                          ),
                        )
                      : const Icon(
                          CupertinoIcons.paperplane_fill,
                          size: 20,
                          color: CupertinoColors.white,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentsList(bool isDark, bool isOled) {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    CupertinoColors.systemRed.withValues(alpha: 0.2),
                    CupertinoColors.systemRed.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.exclamationmark_triangle,
                size: 32,
                color: CupertinoColors.systemRed,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? CupertinoColors.white.withValues(alpha: 0.6)
                    : CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 16),
            CupertinoButton(
              onPressed: _loadComments,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    CupertinoColors.systemBlue.withValues(alpha: 0.2),
                    CupertinoColors.systemBlue.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.chat_bubble,
                size: 40,
                color: isDark
                    ? CupertinoColors.systemBlue.withValues(alpha: 0.6)
                    : CupertinoColors.systemBlue,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No comments yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to comment!',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? CupertinoColors.white.withValues(alpha: 0.6)
                    : CupertinoColors.systemGrey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _comments.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final comment = _comments[index];
        return _CommentCard(comment: comment, isDark: isDark, isOled: isOled);
      },
    );
  }
}

/// Individual comment card with liquid glass design
class _CommentCard extends StatelessWidget {
  final Comment comment;
  final bool isDark;
  final bool isOled;

  const _CommentCard({
    required this.comment,
    required this.isDark,
    required this.isOled,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isOled
                  ? [
                      Colors.white.withValues(alpha: 0.05),
                      Colors.white.withValues(alpha: 0.02),
                    ]
                  : isDark
                  ? [
                      Colors.white.withValues(alpha: 0.1),
                      Colors.white.withValues(alpha: 0.05),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.8),
                      Colors.white.withValues(alpha: 0.6),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isOled
                  ? Colors.white.withValues(alpha: 0.06)
                  : isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.4),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              CupertinoColors.systemBlue.withValues(
                                alpha: 0.25,
                              ),
                              CupertinoColors.systemBlue.withValues(alpha: 0.1),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.person_fill,
                          size: 14,
                          color: isDark
                              ? CupertinoColors.systemBlue.withValues(
                                  alpha: 0.8,
                                )
                              : CupertinoColors.systemBlue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        comment.creatorName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isDark
                              ? CupertinoColors.white
                              : CupertinoColors.black,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: comment.score >= 0
                            ? [
                                AppColors.safeColor.withValues(alpha: 0.25),
                                AppColors.safeColor.withValues(alpha: 0.1),
                              ]
                            : [
                                AppColors.explicitColor.withValues(alpha: 0.25),
                                AppColors.explicitColor.withValues(alpha: 0.1),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          comment.score >= 0
                              ? CupertinoIcons.arrow_up
                              : CupertinoIcons.arrow_down,
                          size: 12,
                          color: comment.score >= 0
                              ? AppColors.safeColor
                              : AppColors.explicitColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          comment.score.abs().toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: comment.score >= 0
                                ? AppColors.safeColor
                                : AppColors.explicitColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Theme(
                data: ThemeData(
                  brightness: isDark ? Brightness.dark : Brightness.light,
                ),
                child: MarkdownBody(
                  data: comment.body,
                  selectable: true,
                  shrinkWrap: true,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? CupertinoColors.white.withValues(alpha: 0.85)
                          : CupertinoColors.label,
                    ),
                    a: TextStyle(
                      color: CupertinoColors.systemBlue,
                      decoration: TextDecoration.underline,
                    ),
                    code: TextStyle(
                      fontSize: 12,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05),
                      color: isDark
                          ? CupertinoColors.white.withValues(alpha: 0.9)
                          : CupertinoColors.black,
                    ),
                    codeblockDecoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    blockquoteDecoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: CupertinoColors.systemBlue.withValues(
                            alpha: 0.5,
                          ),
                          width: 2,
                        ),
                      ),
                    ),
                    blockquotePadding: const EdgeInsets.only(left: 10),
                  ),
                  onTapLink: (text, href, title) {
                    // Handle link taps
                  },
                ),
              ),
              const SizedBox(height: 10),
              Text(
                comment.createdAt.relativeTime,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? CupertinoColors.white.withValues(alpha: 0.5)
                      : CupertinoColors.secondaryLabel,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
