import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/extensions.dart';
import '../../../data/models/models.dart';
import '../../../data/services/services.dart';
import '../../widgets/widgets.dart';

/// Desktop-optimized post detail page with side-by-side layout
class DesktopPostDetailPage extends StatefulWidget {
  final List<int> postIds;
  final int initialIndex;
  final void Function(String tag)? onSearchTag;
  final VoidCallback? onClose;

  const DesktopPostDetailPage({
    super.key,
    required this.postIds,
    required this.initialIndex,
    this.onSearchTag,
    this.onClose,
  });

  @override
  State<DesktopPostDetailPage> createState() => _DesktopPostDetailPageState();
}

class _DesktopPostDetailPageState extends State<DesktopPostDetailPage> {
  late int _currentIndex;
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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadPost(_currentIndex);
    _preloadAdjacentPosts();
  }

  void _preloadAdjacentPosts() {
    if (_currentIndex > 0) {
      _loadPost(_currentIndex - 1);
    }
    if (_currentIndex < widget.postIds.length - 1) {
      _loadPost(_currentIndex + 1);
    }
  }

  Future<void> _loadPost(int index) async {
    if (index < 0 || index >= widget.postIds.length) return;
    if (_loadingStates[index] == true || _loadedPosts.containsKey(index))
      return;

    setState(() {
      _loadingStates[index] = true;
      _errorStates[index] = null;
    });

    final postId = widget.postIds[index];
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
    if (newIndex >= 0 && newIndex < widget.postIds.length) {
      setState(() {
        _currentIndex = newIndex;
      });
      _loadPost(newIndex);
      _preloadAdjacentPosts();
    }
  }

  int get _currentPostId => widget.postIds[_currentIndex];
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

    return Container(
      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      child: Column(
        children: [
          _buildTopBar(isDark),
          Expanded(child: _buildContent(isDark)),
        ],
      ),
    );
  }

  Widget _buildTopBar(bool isDark) {
    final hasMultiple = widget.postIds.length > 1;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSecondaryBackground
            : CupertinoColors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkSeparator : AppColors.lightSeparator,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: widget.onClose,
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.back,
                  size: 20,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
                const SizedBox(width: 4),
                Text(
                  'Back',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark
                        ? CupertinoColors.white
                        : CupertinoColors.black,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Post title
          Text(
            hasMultiple
                ? 'Post #$_currentPostId (${_currentIndex + 1}/${widget.postIds.length})'
                : 'Post #$_currentPostId',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          // Navigation buttons (if multiple posts)
          if (hasMultiple) ...[
            CupertinoButton(
              padding: const EdgeInsets.all(8),
              onPressed: _currentIndex > 0 ? () => _navigatePost(-1) : null,
              child: Icon(
                CupertinoIcons.chevron_left,
                color: _currentIndex > 0
                    ? (isDark ? CupertinoColors.white : CupertinoColors.black)
                    : CupertinoColors.systemGrey,
              ),
            ),
            CupertinoButton(
              padding: const EdgeInsets.all(8),
              onPressed: _currentIndex < widget.postIds.length - 1
                  ? () => _navigatePost(1)
                  : null,
              child: Icon(
                CupertinoIcons.chevron_right,
                color: _currentIndex < widget.postIds.length - 1
                    ? (isDark ? CupertinoColors.white : CupertinoColors.black)
                    : CupertinoColors.systemGrey,
              ),
            ),
          ],
        ],
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
      color: isDark ? CupertinoColors.black : CupertinoColors.systemGrey6,
      child: Stack(
        children: [
          // Media content
          Center(child: _buildMedia(post)),
          // Fullscreen button
          Positioned(
            bottom: 16,
            right: 16,
            child: CupertinoButton(
              padding: const EdgeInsets.all(12),
              color: CupertinoColors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              onPressed: () {
                if (post.isVideo) {
                  _openFullScreenVideo(post);
                } else {
                  setState(() => _isFullScreen = true);
                }
              },
              child: const Icon(
                CupertinoIcons.fullscreen,
                color: CupertinoColors.white,
                size: 20,
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
        autoPlay: false,
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

    return Container(
      color: isDark ? AppColors.darkSecondaryBackground : CupertinoColors.white,
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkSeparator : AppColors.lightSeparator,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: CupertinoIcons.arrow_up,
            activeIcon: CupertinoIcons.arrow_up_circle_fill,
            label: 'Up',
            isActive: userVote == 1,
            isLoading: isVoting,
            color: AppColors.safeColor,
            onTap: () => _vote(userVote == 1 ? 0 : 1),
          ),
          _buildActionButton(
            icon: CupertinoIcons.arrow_down,
            activeIcon: CupertinoIcons.arrow_down_circle_fill,
            label: 'Down',
            isActive: userVote == -1,
            isLoading: isVoting,
            color: AppColors.explicitColor,
            onTap: () => _vote(userVote == -1 ? 0 : -1),
          ),
          _buildActionButton(
            icon: CupertinoIcons.heart,
            activeIcon: CupertinoIcons.heart_fill,
            label: 'Fav',
            isActive: isFav,
            isLoading: isTogglingFav,
            color: AppColors.explicitColor,
            onTap: _toggleFavorite,
          ),
          _buildActionButton(
            icon: CupertinoIcons.square_arrow_down,
            activeIcon: CupertinoIcons.square_arrow_down_fill,
            label: 'Save',
            isActive: false,
            isLoading: false,
            color: AppColors.primaryBlue,
            onTap: () {
              // TODO: Implement download
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
    required bool isLoading,
    required Color color,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onPressed: isLoading ? null : onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            SizedBox(
              width: 22,
              height: 22,
              child: CupertinoActivityIndicator(color: color),
            )
          else
            Icon(
              isActive ? activeIcon : icon,
              size: 22,
              color: isActive ? color : CupertinoColors.secondaryLabel,
            ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? color : CupertinoColors.secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(Post post, PostScore score, bool isFav, bool isDark) {
    final favCount = isFav != post.isFavorited
        ? (isFav ? post.favCount + 1 : post.favCount - 1)
        : post.favCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(
                icon: CupertinoIcons.arrow_up,
                value: score.total.toString(),
                label: 'Score',
                color: score.total >= 0
                    ? AppColors.safeColor
                    : AppColors.explicitColor,
              ),
              _buildStatColumn(
                icon: CupertinoIcons.heart_fill,
                value: favCount.compact,
                label: 'Favorites',
                color: AppColors.explicitColor,
              ),
              _buildStatColumn(
                icon: CupertinoIcons.chat_bubble_fill,
                value: post.commentCount.toString(),
                label: 'Comments',
                color: AppColors.primaryBlue,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Rating badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: post.ratingColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${post.rating.toUpperCase()} - ${post.ratingLabel}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: CupertinoColors.secondaryLabel,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionCard(Post post, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(post.description, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildTagsCard(Post post, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tags',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          CategorizedTagList(tags: post.tags, onTagTap: _searchTag),
        ],
      ),
    );
  }

  Widget _buildMetadataCard(Post post, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Details',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildMetadataRow('ID', '#${post.id}'),
          _buildMetadataRow('Posted', post.createdAt.relativeTime),
          _buildMetadataRow(
            'Resolution',
            '${post.file.width}×${post.file.height}',
          ),
          _buildMetadataRow('File Size', post.file.size.fileSize),
          _buildMetadataRow('Type', post.file.ext.toUpperCase()),
          if (post.sources.isNotEmpty)
            _buildMetadataRow('Sources', '${post.sources.length} source(s)'),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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
            // Close button
            Positioned(
              top: 16,
              left: 16,
              child: CupertinoButton(
                padding: const EdgeInsets.all(12),
                color: CupertinoColors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                onPressed: () => setState(() => _isFullScreen = false),
                child: const Icon(
                  CupertinoIcons.xmark,
                  color: CupertinoColors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFullScreenVideo(Post post) {
    if (post.file.url == null) return;
    Navigator.of(context).push(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (context) => FullScreenVideoViewer(
          videoUrl: post.file.url!,
          thumbnailUrl: post.preview.url,
        ),
      ),
    );
  }
}
