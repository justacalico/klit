import 'dart:ui';
import 'dart:math' show pi;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/extensions.dart';
import '../../../data/models/models.dart';
import '../../../data/services/services.dart';
import '../../widgets/widgets.dart';
import '../widgets/desktop_toolbar.dart';

/// Design constants for the purple/indigo theme
class _ThemeColors {
  static const Color primaryIndigo = Color(0xFF6366F1);
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color primaryViolet = Color(0xFFA855F7);
}

/// Desktop-optimized post detail page with side-by-side layout
class DesktopPostDetailPage extends StatefulWidget {
  final List<int> postIds;
  final int initialIndex;
  final void Function(String tag)? onSearchTag;
  final VoidCallback? onClose;

  /// Callback to load more posts, returns new post IDs
  final Future<List<int>> Function()? onLoadMore;

  /// Whether there are more posts to load
  final bool hasMore;

  const DesktopPostDetailPage({
    super.key,
    required this.postIds,
    required this.initialIndex,
    this.onSearchTag,
    this.onClose,
    this.onLoadMore,
    this.hasMore = false,
  });

  @override
  State<DesktopPostDetailPage> createState() => _DesktopPostDetailPageState();
}

class _DesktopPostDetailPageState extends State<DesktopPostDetailPage> {
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

  // For full screen image view
  bool _isFullScreen = false;
  late FocusNode _focusNode;

  // Confetti controller for favorite animation
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _postIds = List.from(widget.postIds);
    _hasMore = widget.hasMore;
    _focusNode = FocusNode();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    _loadPost(_currentIndex);
    _preloadAdjacentPosts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

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
            _confettiController.play();
          }
        },
        failure: (error) {
          setState(() => _isTogglingFavorite[_currentIndex] = false);
          _showError(error.message);
        },
      );
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
      child: Container(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        child: Column(
          children: [
            _buildTopBar(isDark),
            Expanded(child: _buildContent(isDark)),
          ],
        ),
      ),
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
                    ? DesktopToolbarColors.primaryPurple.withValues(alpha: 0.15)
                    : DesktopToolbarColors.primaryPurple.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Back button with gradient styling
              DesktopToolbarButton(
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
                      DesktopToolbarColors.primaryIndigo,
                      DesktopToolbarColors.primaryPurple,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: DesktopToolbarColors.primaryPurple.withValues(
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
                DesktopToolbarButton(
                  icon: CupertinoIcons.chevron_left,
                  tooltip: 'Previous',
                  onPressed: _currentIndex > 0 ? () => _navigatePost(-1) : null,
                ),
                const SizedBox(width: 8),
                DesktopToolbarButton(
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
                        _ThemeColors.primaryPurple.withValues(alpha: 0.9),
                        _ThemeColors.primaryIndigo.withValues(alpha: 0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _ThemeColors.primaryPurple.withValues(alpha: 0.4),
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
      return VideoPlayerWidget(
        videoUrl: post.file.url!,
        thumbnailUrl: post.preview.url,
        autoPlay: true,
        looping: true,
        showControls: true,
        aspectRatio: post.file.aspectRatio,
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
                      _ThemeColors.primaryPurple.withValues(alpha: 0.08),
                      _ThemeColors.primaryIndigo.withValues(alpha: 0.05),
                    ]
                  : [
                      _ThemeColors.primaryPurple.withValues(alpha: 0.05),
                      _ThemeColors.primaryIndigo.withValues(alpha: 0.03),
                    ],
            ),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? _ThemeColors.primaryPurple.withValues(alpha: 0.15)
                    : _ThemeColors.primaryPurple.withValues(alpha: 0.1),
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
                    _ThemeColors.primaryPurple,
                    _ThemeColors.primaryViolet,
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
                  isLoading: false,
                  activeGradient: [
                    _ThemeColors.primaryIndigo,
                    _ThemeColors.primaryPurple,
                  ],
                  isDark: isDark,
                  onTap: () {
                    // TODO: Implement download
                  },
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
                      ? _ThemeColors.primaryPurple.withValues(alpha: 0.2)
                      : _ThemeColors.primaryPurple.withValues(alpha: 0.1)),
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
                        : _ThemeColors.primaryPurple,
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
                      _ThemeColors.primaryPurple.withValues(alpha: 0.08),
                      _ThemeColors.primaryIndigo.withValues(alpha: 0.05),
                    ]
                  : [
                      _ThemeColors.primaryPurple.withValues(alpha: 0.06),
                      _ThemeColors.primaryIndigo.withValues(alpha: 0.03),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? _ThemeColors.primaryPurple.withValues(alpha: 0.2)
                  : _ThemeColors.primaryPurple.withValues(alpha: 0.12),
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
                    color: _ThemeColors.primaryViolet,
                    isDark: isDark,
                  ),
                  _buildStatColumn(
                    icon: CupertinoIcons.chat_bubble_fill,
                    value: post.commentCount.toString(),
                    label: 'Comments',
                    color: _ThemeColors.primaryIndigo,
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
                      _ThemeColors.primaryIndigo.withValues(alpha: 0.06),
                      _ThemeColors.primaryPurple.withValues(alpha: 0.04),
                    ]
                  : [
                      _ThemeColors.primaryIndigo.withValues(alpha: 0.04),
                      _ThemeColors.primaryPurple.withValues(alpha: 0.02),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? _ThemeColors.primaryIndigo.withValues(alpha: 0.15)
                  : _ThemeColors.primaryIndigo.withValues(alpha: 0.1),
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
                          _ThemeColors.primaryIndigo,
                          _ThemeColors.primaryPurple,
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
                      _ThemeColors.primaryPurple.withValues(alpha: 0.06),
                      _ThemeColors.primaryViolet.withValues(alpha: 0.04),
                    ]
                  : [
                      _ThemeColors.primaryPurple.withValues(alpha: 0.04),
                      _ThemeColors.primaryViolet.withValues(alpha: 0.02),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? _ThemeColors.primaryPurple.withValues(alpha: 0.15)
                  : _ThemeColors.primaryPurple.withValues(alpha: 0.1),
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
                          _ThemeColors.primaryPurple,
                          _ThemeColors.primaryViolet,
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
                          ? _ThemeColors.primaryPurple.withValues(alpha: 0.2)
                          : _ThemeColors.primaryPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${post.tags.all.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _ThemeColors.primaryPurple,
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
                      _ThemeColors.primaryViolet.withValues(alpha: 0.06),
                      _ThemeColors.primaryIndigo.withValues(alpha: 0.04),
                    ]
                  : [
                      _ThemeColors.primaryViolet.withValues(alpha: 0.04),
                      _ThemeColors.primaryIndigo.withValues(alpha: 0.02),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? _ThemeColors.primaryViolet.withValues(alpha: 0.15)
                  : _ThemeColors.primaryViolet.withValues(alpha: 0.1),
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
                          _ThemeColors.primaryViolet,
                          _ThemeColors.primaryIndigo,
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
                        _ThemeColors.primaryPurple.withValues(alpha: 0.9),
                        _ThemeColors.primaryIndigo.withValues(alpha: 0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _ThemeColors.primaryPurple.withValues(
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
