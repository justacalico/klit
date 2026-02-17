import 'dart:io';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart'
    show CachedNetworkImage, CachedNetworkImageProvider;
import 'package:dio/dio.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart'
    show Colors, Theme, ThemeData, Brightness;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import '../../app/routes.dart';
import '../../core/constants/constants.dart';
import '../../core/extensions/extensions.dart';
import '../../core/input/input.dart';
import '../../data/models/models.dart';
import '../../data/services/services.dart';
import '../../providers/providers.dart';
import '../layout/layout_scope.dart';
import '../shell/toolbar.dart';
import '../theme.dart';
import '../widgets/widgets.dart' hide Colors;

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

/// Post detail page with swipe navigation - adapts layout for desktop/mobile
class PostDetailPage extends StatelessWidget {
  final List<int> postIds;
  final int initialIndex;
  final void Function(String tag)? onSearchTag;
  final Future<List<int>> Function()? onLoadMore;
  final bool hasMore;
  final VoidCallback? onClose;

  const PostDetailPage({
    super.key,
    required this.postIds,
    required this.initialIndex,
    this.onSearchTag,
    this.onLoadMore,
    this.hasMore = false,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final mode = LayoutScope.of(context);
    if (mode.isDesktop) {
      return _DesktopPostDetailView(
        postIds: postIds,
        initialIndex: initialIndex,
        onSearchTag: onSearchTag,
        onLoadMore: onLoadMore,
        hasMore: hasMore,
        onClose: onClose ?? () => Navigator.of(context).pop(),
      );
    }
    return _MobilePostDetailView(
      postIds: postIds,
      initialIndex: initialIndex,
      onSearchTag: onSearchTag,
      onLoadMore: onLoadMore,
      hasMore: hasMore,
    );
  }
}

class _MobilePostDetailView extends StatefulWidget {
  final List<int> postIds;
  final int initialIndex;
  final void Function(String tag)? onSearchTag;
  final Future<List<int>> Function()? onLoadMore;
  final bool hasMore;

  const _MobilePostDetailView({
    required this.postIds,
    required this.initialIndex,
    this.onSearchTag,
    this.onLoadMore,
    this.hasMore = false,
  });

  @override
  State<_MobilePostDetailView> createState() => _MobilePostDetailViewState();
}

class _MobilePostDetailViewState extends State<_MobilePostDetailView> {
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

  // Focus node for keyboard controls
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _postIds = List.from(widget.postIds);
    _hasMore = widget.hasMore;
    _pageController = PageController(initialPage: _currentIndex);
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );
    _focusNode = FocusNode();
    _loadPost(_currentIndex);
    _preloadAdjacentPosts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _confettiController.dispose();
    _focusNode.dispose();
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

  /// Navigate to next (+1) or previous (-1) post via keyboard
  void _navigatePost(int direction) {
    final newIndex = _currentIndex + direction;
    if (newIndex >= 0 && newIndex < _postIds.length) {
      _pageController.animateToPage(
        newIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
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
    final leftHandedMode = settingsProvider.leftHandedMode;

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey.keyLabel.toLowerCase();
          // Navigation
          if (key == 'd' || event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _navigatePost(1);
            return;
          }
          if (key == 'a' || event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _navigatePost(-1);
            return;
          }
          // Actions
          if (key == 'f') {
            _toggleFavorite(_currentIndex);
            return;
          }
          if (key == 'w' || event.logicalKey == LogicalKeyboardKey.arrowUp) {
            final currentVote = _userVote[_currentIndex];
            _vote(_currentIndex, currentVote == 1 ? 0 : 1);
            return;
          }
          if (key == 's' || event.logicalKey == LogicalKeyboardKey.arrowDown) {
            final currentVote = _userVote[_currentIndex];
            _vote(_currentIndex, currentVote == -1 ? 0 : -1);
            return;
          }
        }
      },
      child: CupertinoPageScaffold(
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
              alignment: Alignment(leftHandedMode ? -0.3 : 0.3, 0.45),
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
      final settings = context.read<SettingsProvider>();
      return AspectRatio(
        aspectRatio: post.file.aspectRatio.clamp(0.5, 2.0),
        child: VideoPlayerWidget(
          key: ValueKey('video_${post.id}_${post.file.url}'),
          videoUrl: post.file.url!,
          thumbnailUrl: post.preview.url,
          autoPlay: settings.videoAutoPlay,
          looping: true,
          showControls: true,
          aspectRatio: post.file.aspectRatio,
          muteByDefault: settings.videoMuteByDefault,
        ),
      );
    }

    // For GIFs, use the full file URL to preserve animation
    // For other images, prefer full resolution, fallback to sample, then preview
    final imageUrl = post.isGif
        ? post.file.url
        : (post.file.url ?? post.sample.url ?? post.preview.url);

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
/// Desktop-optimized post detail page with side-by-side layout
class _DesktopPostDetailView extends StatefulWidget {
  final List<int> postIds;
  final int initialIndex;
  final void Function(String tag)? onSearchTag;
  final VoidCallback? onClose;

  /// Callback to load more posts, returns new post IDs
  final Future<List<int>> Function()? onLoadMore;

  /// Whether there are more posts to load
  final bool hasMore;

  const _DesktopPostDetailView({
    super.key,
    required this.postIds,
    required this.initialIndex,
    this.onSearchTag,
    this.onClose,
    this.onLoadMore,
    this.hasMore = false,
  });

  @override
  State<_DesktopPostDetailView> createState() => _DesktopPostDetailViewState();
}

class _DesktopPostDetailViewState extends State<_DesktopPostDetailView>
    with GamepadInputMixin {
  late int _currentIndex;
  late List<int> _postIds;
  late bool _hasMore;
  bool _isLoadingMore = false;
  final Map<int, Post?> _loadedPosts = {};
  final Map<int, bool> _loadingStates = {};
  final Map<int, String?> _errorStates = {};

  // Action states
  final Map<int, bool> _isFavorited = {};
  final Map<int, int?> _userVote = {};
  final Map<int, PostScore?> _updatedScores = {};
  final Map<int, bool> _isVoting = {};
  final Map<int, bool> _isTogglingFavorite = {};
  final Map<int, bool> _isDownloading = {};
  final Map<int, double> _downloadProgress = {};

  // For full screen image view
  bool _isFullScreen = false;
  late FocusNode _focusNode;

  // Confetti controller for favorite animation
  late ConfettiController _confettiController;

  // Controller state for visual feedback
  bool _showControllerHints = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _postIds = List.from(widget.postIds);
    _hasMore = widget.hasMore;
    _focusNode = FocusNode();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );
    _loadPost(_currentIndex);
    _preloadAdjacentPosts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });

    // Show controller hints if gamepad is connected
    if (gamepad.isConnected) {
      _showControllerHints = true;
    }

    // Listen for controller connection
    gamepad.stateChanges.listen((state) {
      if (mounted && state.isConnected != _showControllerHints) {
        setState(() => _showControllerHints = state.isConnected);
      }
    });
  }

  /// Handle gamepad button presses
  /// Button mapping:
  /// - LB: Previous post
  /// - RB: Next post
  /// - Y: Toggle favorite
  /// - RT: Upvote
  /// - X: Downvote
  /// - B: Close/Back
  @override
  void onGamepadButton(GamepadButton button) {
    if (!mounted) return;

    switch (button) {
      case GamepadButton.leftBumper:
        // Previous post
        _navigatePost(-1);
        HapticFeedback.mediumImpact();

      case GamepadButton.rightBumper:
        // Next post
        _navigatePost(1);
        HapticFeedback.mediumImpact();

      case GamepadButton.y:
        // Toggle favorite
        _toggleFavorite();
        HapticFeedback.heavyImpact();

      case GamepadButton.rightTrigger:
        // Upvote
        final currentVote = _userVote[_currentIndex];
        _vote(currentVote == 1 ? 0 : 1);
        HapticFeedback.mediumImpact();

      case GamepadButton.x:
        // Downvote
        final currentVote = _userVote[_currentIndex];
        _vote(currentVote == -1 ? 0 : -1);
        HapticFeedback.mediumImpact();

      case GamepadButton.b:
        // Close/Back
        if (_isFullScreen) {
          setState(() => _isFullScreen = false);
        } else {
          widget.onClose?.call();
        }
        HapticFeedback.lightImpact();

      case GamepadButton.a:
        // Toggle fullscreen for images
        final post = _currentPost;
        if (post != null && !post.isVideo) {
          setState(() => _isFullScreen = !_isFullScreen);
          HapticFeedback.lightImpact();
        }

      default:
        break;
    }
  }

  /// Handle thumbstick for scrolling
  @override
  void onGamepadDirection(GamepadDirection direction) {
    if (!mounted) return;

    switch (direction) {
      case GamepadDirection.left:
        _navigatePost(-1);
      case GamepadDirection.right:
        _navigatePost(1);
      default:
        // Up/Down could be used for scrolling info panel
        break;
    }
  }

  @override
  @override
  void dispose() {
    _focusNode.dispose();
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

  Future<void> _loadPost(int index) async {
    if (index < 0 || index >= _postIds.length) return;
    if (_loadingStates[index] == true || _loadedPosts.containsKey(index)) {
      return;
    }

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

  void _navigatePost(int delta) {
    final newIndex = _currentIndex + delta;
    if (newIndex >= 0 && newIndex < _postIds.length) {
      setState(() {
        _currentIndex = newIndex;
      });
      _loadPost(newIndex);
      _preloadAdjacentPosts();
    }
  }

  int get _currentPostId => _postIds[_currentIndex];
  Post? get _currentPost => _loadedPosts[_currentIndex];

  Future<void> _vote(int score) async {
    final post = _currentPost;
    if (post == null || _isVoting[_currentIndex] == true) return;

    setState(() => _isVoting[_currentIndex] = true);

    final apiService = context.read<ApiService>();
    final result = await apiService.votePost(post.id, score);

    if (mounted) {
      result.when(
        success: (newScore) {
          setState(() {
            _updatedScores[_currentIndex] = newScore;
            _userVote[_currentIndex] = score;
            _isVoting[_currentIndex] = false;
          });
        },
        failure: (error) {
          setState(() => _isVoting[_currentIndex] = false);
          _showError(error.message);
        },
      );
    }
  }

  Future<void> _toggleFavorite() async {
    final post = _currentPost;
    if (post == null || _isTogglingFavorite[_currentIndex] == true) return;

    final isFav = _isFavorited[_currentIndex] ?? post.isFavorited;
    setState(() => _isTogglingFavorite[_currentIndex] = true);

    final apiService = context.read<ApiService>();
    final result = isFav
        ? await apiService.removeFavorite(post.id)
        : await apiService.addFavorite(post.id);

    if (mounted) {
      result.when(
        success: (_) {
          setState(() {
            _isFavorited[_currentIndex] = !isFav;
            _isTogglingFavorite[_currentIndex] = false;
          });

          // Play confetti animation when adding favorite
          if (!isFav) {
            final settings = context.read<SettingsProvider>();
            if (settings.confettiOnFavorite) {
              _confettiController.play();
            }
          }
        },
        failure: (error) {
          setState(() => _isTogglingFavorite[_currentIndex] = false);
          _showError(error.message);
        },
      );
    }
  }

  /// Download the current post's file to the user's Downloads folder
  Future<void> _downloadPost() async {
    final post = _currentPost;
    if (post == null || _isDownloading[_currentIndex] == true) return;

    final fileUrl = post.file.url;
    if (fileUrl == null) {
      _showError('No file URL available for download');
      return;
    }

    setState(() {
      _isDownloading[_currentIndex] = true;
      _downloadProgress[_currentIndex] = 0;
    });

    try {
      // Get Downloads directory
      final downloadsDir = await _getDownloadsDirectory();
      if (downloadsDir == null) {
        throw Exception('Could not find Downloads directory');
      }

      // Create filename from post ID and extension
      final extension = post.file.ext.isNotEmpty ? post.file.ext : 'png';
      final filename = 'e926_${post.id}.$extension';
      final filePath = '${downloadsDir.path}/$filename';

      // Check if file already exists
      final file = File(filePath);
      if (await file.exists()) {
        if (mounted) {
          setState(() => _isDownloading[_currentIndex] = false);
          _showDownloadComplete(filePath, alreadyExists: true);
        }
        return;
      }

      // Download the file using Dio
      final dio = Dio();
      await dio.download(
        fileUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() {
              _downloadProgress[_currentIndex] = received / total;
            });
          }
        },
      );

      if (mounted) {
        setState(() => _isDownloading[_currentIndex] = false);
        _showDownloadComplete(filePath);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDownloading[_currentIndex] = false);
        _showError('Download failed: ${e.toString()}');
      }
    }
  }

  /// Get the Downloads directory based on platform
  Future<Directory?> _getDownloadsDirectory() async {
    if (Platform.isLinux || Platform.isMacOS) {
      final home = Platform.environment['HOME'];
      if (home != null) {
        return Directory('$home/Downloads');
      }
    } else if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        return Directory('$userProfile\\Downloads');
      }
    }
    return null;
  }

  /// Show download complete notification
  void _showDownloadComplete(String filePath, {bool alreadyExists = false}) {
    final fileName = filePath.split('/').last.split('\\').last;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(alreadyExists ? 'File Exists' : 'Download Complete'),
        content: Text(
          alreadyExists
              ? 'File already exists:\n$fileName'
              : 'Saved to Downloads:\n$fileName',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Open Folder'),
            onPressed: () {
              Navigator.of(context).pop();
              _openDownloadsFolder(filePath);
            },
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// Open the Downloads folder in the system file manager
  Future<void> _openDownloadsFolder(String filePath) async {
    try {
      final directory = File(filePath).parent.path;
      if (Platform.isLinux) {
        await Process.run('xdg-open', [directory]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [directory]);
      } else if (Platform.isWindows) {
        await Process.run('explorer', [directory]);
      }
    } catch (e) {
      // Silently fail if we can't open the folder
    }
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

  void _searchTag(String tag) {
    if (widget.onSearchTag != null) {
      widget.onSearchTag!(tag);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;

    if (_isFullScreen && _currentPost != null) {
      return _buildFullScreenView(isDark);
    }

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey.keyLabel.toLowerCase();
          // Navigation
          if (key == 'd') {
            _navigatePost(1);
            return;
          }
          if (key == 'a') {
            _navigatePost(-1);
            return;
          }
          // Actions
          if (key == 'f') {
            _toggleFavorite();
            return;
          }
          if (key == 'w') {
            final currentVote = _userVote[_currentIndex];
            _vote(currentVote == 1 ? 0 : 1);
            return;
          }
          if (key == 's') {
            final currentVote = _userVote[_currentIndex];
            _vote(currentVote == -1 ? 0 : -1);
            return;
          }
        }
      },
      child: Stack(
        children: [
          Container(
            color: isDark
                ? AppColors.darkBackground
                : AppColors.lightBackground,
            child: Column(
              children: [
                _buildTopBar(isDark),
                Expanded(child: _buildContent(isDark)),
              ],
            ),
          ),
          // Confetti overlay - positioned near the favorite button on the right panel
          Align(
            alignment: const Alignment(0.85, -0.3),
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
          // Controller hints overlay
          if (_showControllerHints)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: _buildControllerHints(isDark),
            ),
        ],
      ),
    );
  }

  /// Builds the controller button hints overlay
  Widget _buildControllerHints(bool isDark) {
    final currentVote = _userVote[_currentIndex];
    final isFavorited = _isFavorited[_currentIndex] ?? false;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xFF18181B) : const Color(0xFFFFFFFF))
                .withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHintButton('LB', 'Previous', isDark),
              const SizedBox(width: 16),
              _buildHintButton('RB', 'Next', isDark),
              _buildHintDivider(isDark),
              _buildHintButton(
                'Y',
                isFavorited ? 'Unfavorite' : 'Favorite',
                isDark,
                color: isFavorited ? const Color(0xFFFF6B9D) : null,
              ),
              const SizedBox(width: 16),
              _buildHintButton(
                'RT',
                currentVote == 1 ? 'Remove Vote' : 'Upvote',
                isDark,
                color: currentVote == 1 ? const Color(0xFF22C55E) : null,
              ),
              const SizedBox(width: 16),
              _buildHintButton(
                'X',
                currentVote == -1 ? 'Remove Vote' : 'Downvote',
                isDark,
                color: currentVote == -1 ? const Color(0xFFEF4444) : null,
              ),
              _buildHintDivider(isDark),
              _buildHintButton('B', 'Close', isDark),
              const SizedBox(width: 16),
              _buildHintButton('A', 'Fullscreen', isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHintButton(
    String button,
    String label,
    bool isDark, {
    Color? color,
  }) {
    final buttonColor =
        color ?? (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: buttonColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: buttonColor.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Text(
            button,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: buttonColor,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFFE4E4E7) : const Color(0xFF3F3F46),
          ),
        ),
      ],
    );
  }

  Widget _buildHintDivider(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: 1,
      height: 20,
      color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFD4D4D8),
    );
  }

  Widget _buildTopBar(bool isDark) {
    final hasMultiple = _postIds.length > 1;

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
                    ? UIColors.primaryPurple.withValues(alpha: 0.15)
                    : UIColors.primaryPurple.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Back button with gradient styling
              ToolbarButton(
                icon: CupertinoIcons.back,
                tooltip: 'Back',
                onPressed: widget.onClose ?? () {},
              ),
              const SizedBox(width: 8),
              Text(
                'Back',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? CupertinoColors.white
                      : const Color(0xFF1F2937),
                ),
              ),
              const Spacer(),
              // Post title with gradient icon
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      UIColors.primaryIndigo,
                      UIColors.primaryPurple,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: UIColors.primaryPurple.withValues(
                        alpha: 0.3,
                      ),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.photo,
                  size: 14,
                  color: CupertinoColors.white,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                hasMultiple
                    ? 'Post #$_currentPostId (${_currentIndex + 1}/${_postIds.length})'
                    : 'Post #$_currentPostId',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? CupertinoColors.white
                      : const Color(0xFF1F2937),
                ),
              ),
              const Spacer(),
              // Navigation buttons (if multiple posts)
              if (hasMultiple) ...[
                ToolbarButton(
                  icon: CupertinoIcons.chevron_left,
                  tooltip: 'Previous',
                  onPressed: _currentIndex > 0 ? () => _navigatePost(-1) : null,
                ),
                const SizedBox(width: 8),
                ToolbarButton(
                  icon: CupertinoIcons.chevron_right,
                  tooltip: 'Next',
                  onPressed: _currentIndex < _postIds.length - 1
                      ? () => _navigatePost(1)
                      : null,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    final isLoading = _loadingStates[_currentIndex] == true;
    final error = _errorStates[_currentIndex];
    final post = _currentPost;

    if (isLoading) {
      return const Center(child: CupertinoActivityIndicator(radius: 16));
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.exclamationmark_triangle, size: 48),
            const SizedBox(height: 16),
            Text(error),
            const SizedBox(height: 16),
            CupertinoButton.filled(
              onPressed: () => _loadPost(_currentIndex),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (post == null) {
      return const Center(child: Text('Post not found'));
    }

    // Desktop layout: media on left, info panel on right
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Media viewer (takes most space)
        Expanded(flex: 3, child: _buildMediaPanel(post, isDark)),
        // Divider
        Container(
          width: 1,
          color: isDark ? AppColors.darkSeparator : AppColors.lightSeparator,
        ),
        // Right: Info panel (scrollable)
        SizedBox(width: 380, child: _buildInfoPanel(post, isDark)),
      ],
    );
  }

  Widget _buildMediaPanel(Post post, bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF0A0A0C) : CupertinoColors.systemGrey6,
      child: Stack(
        children: [
          // Media content
          Center(child: _buildMedia(post)),
          // Fullscreen button with gradient (only for images, video player has its own)
          if (!post.isVideo)
            Positioned(
              bottom: 20,
              right: 20,
              child: GestureDetector(
                onTap: () => setState(() => _isFullScreen = true),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        UIColors.primaryPurple.withValues(alpha: 0.9),
                        UIColors.primaryIndigo.withValues(alpha: 0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: UIColors.primaryPurple.withValues(
                          alpha: 0.4,
                        ),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    CupertinoIcons.fullscreen,
                    color: CupertinoColors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMedia(Post post) {
    if (post.isVideo && post.file.url != null) {
      final settings = context.read<SettingsProvider>();
      return VideoPlayerWidget(
        key: ValueKey('video_${post.id}_${post.file.url}'),
        videoUrl: post.file.url!,
        thumbnailUrl: post.preview.url,
        autoPlay: settings.videoAutoPlay,
        looping: true,
        showControls: true,
        aspectRatio: post.file.aspectRatio,
        muteByDefault: settings.videoMuteByDefault,
      );
    }

    // Use full resolution image, fallback to sample, then preview
    final imageUrl = post.file.url ?? post.sample.url ?? post.preview.url;
    if (imageUrl == null) {
      return const Icon(CupertinoIcons.photo, size: 64);
    }

    // Use sample/preview as placeholder while loading full image
    final placeholderUrl = post.preview.url;
    final aspectRatio = post.file.aspectRatio;

    return GestureDetector(
      onDoubleTap: () => setState(() => _isFullScreen = true),
      child: AspectRatio(
        aspectRatio: aspectRatio.clamp(0.3, 3.0),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.contain,
          placeholder: (context, url) => placeholderUrl != null
              ? CachedNetworkImage(
                  imageUrl: placeholderUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) =>
                      const CupertinoActivityIndicator(),
                  errorWidget: (context, url, error) =>
                      const CupertinoActivityIndicator(),
                )
              : const CupertinoActivityIndicator(),
          errorWidget: (context, url, error) =>
              const Icon(CupertinoIcons.exclamationmark_triangle, size: 48),
        ),
      ),
    );
  }

  Widget _buildInfoPanel(Post post, bool isDark) {
    final score = _updatedScores[_currentIndex] ?? post.score;
    final isFav = _isFavorited[_currentIndex] ?? post.isFavorited;
    final userVote = _userVote[_currentIndex];
    final isVoting = _isVoting[_currentIndex] == true;
    final isTogglingFav = _isTogglingFavorite[_currentIndex] == true;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF2C2C2E).withValues(alpha: 0.7),
                      const Color(0xFF1C1C1E).withValues(alpha: 0.8),
                    ]
                  : [
                      const Color(0xFFFFFFFF).withValues(alpha: 0.7),
                      const Color(0xFFF8F8FA).withValues(alpha: 0.8),
                    ],
            ),
          ),
          child: Column(
            children: [
              // Action buttons
              _buildActionBar(
                score,
                isFav,
                userVote,
                isVoting,
                isTogglingFav,
                isDark,
              ),
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsCard(post, score, isFav, isDark),
                      const SizedBox(height: 16),
                      if (post.description.isNotEmpty) ...[
                        _buildDescriptionCard(post, isDark),
                        const SizedBox(height: 16),
                      ],
                      _buildTagsCard(post, isDark),
                      const SizedBox(height: 16),
                      _buildMetadataCard(post, isDark),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionBar(
    PostScore score,
    bool isFav,
    int? userVote,
    bool isVoting,
    bool isTogglingFav,
    bool isDark,
  ) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      UIColors.primaryPurple.withValues(alpha: 0.08),
                      UIColors.primaryIndigo.withValues(alpha: 0.05),
                    ]
                  : [
                      UIColors.primaryPurple.withValues(alpha: 0.05),
                      UIColors.primaryIndigo.withValues(alpha: 0.03),
                    ],
            ),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? UIColors.primaryPurple.withValues(alpha: 0.15)
                    : UIColors.primaryPurple.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildGradientActionButton(
                  icon: CupertinoIcons.arrow_up,
                  activeIcon: CupertinoIcons.arrow_up_circle_fill,
                  isActive: userVote == 1,
                  isLoading: isVoting,
                  activeGradient: const [Color(0xFF22C55E), Color(0xFF16A34A)],
                  isDark: isDark,
                  onTap: () => _vote(userVote == 1 ? 0 : 1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildGradientActionButton(
                  icon: CupertinoIcons.arrow_down,
                  activeIcon: CupertinoIcons.arrow_down_circle_fill,
                  isActive: userVote == -1,
                  isLoading: isVoting,
                  activeGradient: const [Color(0xFFEF4444), Color(0xFFDC2626)],
                  isDark: isDark,
                  onTap: () => _vote(userVote == -1 ? 0 : -1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildGradientActionButton(
                  icon: CupertinoIcons.heart,
                  activeIcon: CupertinoIcons.heart_fill,
                  isActive: isFav,
                  isLoading: isTogglingFav,
                  activeGradient: [
                    UIColors.primaryPurple,
                    UIColors.primaryViolet,
                  ],
                  isDark: isDark,
                  onTap: _toggleFavorite,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildGradientActionButton(
                  icon: CupertinoIcons.square_arrow_down,
                  activeIcon: CupertinoIcons.square_arrow_down_fill,
                  isActive: false,
                  isLoading: _isDownloading[_currentIndex] == true,
                  activeGradient: [
                    UIColors.primaryIndigo,
                    UIColors.primaryPurple,
                  ],
                  isDark: isDark,
                  onTap: _downloadPost,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradientActionButton({
    required IconData icon,
    required IconData activeIcon,
    required bool isActive,
    required bool isLoading,
    required List<Color> activeGradient,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: activeGradient,
                )
              : null,
          color: isActive
              ? null
              : (isDark
                    ? const Color(0xFF2C2C2E).withValues(alpha: 0.6)
                    : const Color(0xFFF3F4F6).withValues(alpha: 0.8)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? Colors.transparent
                : (isDark
                      ? UIColors.primaryPurple.withValues(alpha: 0.2)
                      : UIColors.primaryPurple.withValues(alpha: 0.1)),
            width: 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: activeGradient[0].withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CupertinoActivityIndicator(
                    color: isActive
                        ? CupertinoColors.white
                        : UIColors.primaryPurple,
                  ),
                )
              : Icon(
                  isActive ? activeIcon : icon,
                  size: 20,
                  color: isActive
                      ? CupertinoColors.white
                      : (isDark
                            ? CupertinoColors.white.withValues(alpha: 0.7)
                            : const Color(0xFF374151)),
                ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(Post post, PostScore score, bool isFav, bool isDark) {
    final favCount = isFav != post.isFavorited
        ? (isFav ? post.favCount + 1 : post.favCount - 1)
        : post.favCount;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      UIColors.primaryPurple.withValues(alpha: 0.08),
                      UIColors.primaryIndigo.withValues(alpha: 0.05),
                    ]
                  : [
                      UIColors.primaryPurple.withValues(alpha: 0.06),
                      UIColors.primaryIndigo.withValues(alpha: 0.03),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? UIColors.primaryPurple.withValues(alpha: 0.2)
                  : UIColors.primaryPurple.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn(
                    icon: CupertinoIcons.arrow_up_circle_fill,
                    value: score.total.toString(),
                    label: 'Score',
                    color: score.total >= 0
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFEF4444),
                    isDark: isDark,
                  ),
                  _buildStatColumn(
                    icon: CupertinoIcons.heart_fill,
                    value: favCount.compact,
                    label: 'Favorites',
                    color: UIColors.primaryViolet,
                    isDark: isDark,
                  ),
                  _buildStatColumn(
                    icon: CupertinoIcons.chat_bubble_fill,
                    value: post.commentCount.toString(),
                    label: 'Comments',
                    color: UIColors.primaryIndigo,
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Rating badge with gradient
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      post.ratingColor,
                      post.ratingColor.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: post.ratingColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${post.rating.toUpperCase()} - ${post.ratingLabel}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: CupertinoColors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn({
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
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.15),
                color.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? CupertinoColors.white : const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark
                ? CupertinoColors.white.withValues(alpha: 0.6)
                : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionCard(Post post, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      UIColors.primaryIndigo.withValues(alpha: 0.06),
                      UIColors.primaryPurple.withValues(alpha: 0.04),
                    ]
                  : [
                      UIColors.primaryIndigo.withValues(alpha: 0.04),
                      UIColors.primaryPurple.withValues(alpha: 0.02),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? UIColors.primaryIndigo.withValues(alpha: 0.15)
                  : UIColors.primaryIndigo.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          UIColors.primaryIndigo,
                          UIColors.primaryPurple,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.doc_text_fill,
                      size: 12,
                      color: CupertinoColors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? CupertinoColors.white
                          : const Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                post.description,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark
                      ? CupertinoColors.white.withValues(alpha: 0.85)
                      : const Color(0xFF374151),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTagsCard(Post post, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      UIColors.primaryPurple.withValues(alpha: 0.06),
                      UIColors.primaryViolet.withValues(alpha: 0.04),
                    ]
                  : [
                      UIColors.primaryPurple.withValues(alpha: 0.04),
                      UIColors.primaryViolet.withValues(alpha: 0.02),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? UIColors.primaryPurple.withValues(alpha: 0.15)
                  : UIColors.primaryPurple.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          UIColors.primaryPurple,
                          UIColors.primaryViolet,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.tag_fill,
                      size: 12,
                      color: CupertinoColors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Tags',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? CupertinoColors.white
                          : const Color(0xFF1F2937),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? UIColors.primaryPurple.withValues(alpha: 0.2)
                          : UIColors.primaryPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${post.tags.all.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: UIColors.primaryPurple,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CategorizedTagList(tags: post.tags, onTagTap: _searchTag),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataCard(Post post, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      UIColors.primaryViolet.withValues(alpha: 0.06),
                      UIColors.primaryIndigo.withValues(alpha: 0.04),
                    ]
                  : [
                      UIColors.primaryViolet.withValues(alpha: 0.04),
                      UIColors.primaryIndigo.withValues(alpha: 0.02),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? UIColors.primaryViolet.withValues(alpha: 0.15)
                  : UIColors.primaryViolet.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          UIColors.primaryViolet,
                          UIColors.primaryIndigo,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.info_circle_fill,
                      size: 12,
                      color: CupertinoColors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? CupertinoColors.white
                          : const Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildMetadataRow('ID', '#${post.id}', isDark),
              _buildMetadataRow('Posted', post.createdAt.relativeTime, isDark),
              _buildMetadataRow(
                'Resolution',
                '${post.file.width}×${post.file.height}',
                isDark,
              ),
              _buildMetadataRow('File Size', post.file.size.fileSize, isDark),
              _buildMetadataRow('Type', post.file.ext.toUpperCase(), isDark),
              if (post.sources.isNotEmpty)
                _buildMetadataRow(
                  'Sources',
                  '${post.sources.length} source(s)',
                  isDark,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? CupertinoColors.white.withValues(alpha: 0.6)
                  : const Color(0xFF6B7280),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? CupertinoColors.white : const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullScreenView(bool isDark) {
    final post = _currentPost!;
    final imageUrl = post.file.url ?? post.sample.url ?? post.preview.url;

    if (imageUrl == null) {
      return Container();
    }

    return GestureDetector(
      onTap: () => setState(() => _isFullScreen = false),
      child: Container(
        color: CupertinoColors.black,
        child: Stack(
          children: [
            PhotoView(
              imageProvider: CachedNetworkImageProvider(imageUrl),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 3,
              backgroundDecoration: const BoxDecoration(
                color: CupertinoColors.black,
              ),
              loadingBuilder: (context, event) => const Center(
                child: CupertinoActivityIndicator(color: CupertinoColors.white),
              ),
            ),
            // Close button with gradient
            Positioned(
              top: 20,
              left: 20,
              child: GestureDetector(
                onTap: () => setState(() => _isFullScreen = false),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        UIColors.primaryPurple.withValues(alpha: 0.9),
                        UIColors.primaryIndigo.withValues(alpha: 0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: UIColors.primaryPurple.withValues(
                          alpha: 0.4,
                        ),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    CupertinoIcons.xmark,
                    color: CupertinoColors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
