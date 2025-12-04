import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import '../../../app/routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/extensions.dart';
import '../../../data/models/models.dart';
import '../../../data/services/services.dart';
import '../../widgets/widgets.dart';

/// Arguments for navigating to post detail with swipe support
class PostDetailArguments {
  final List<int> postIds;
  final int initialIndex;

  const PostDetailArguments({
    required this.postIds,
    required this.initialIndex,
  });
}

/// Post detail page with swipe navigation
class PostDetailPage extends StatefulWidget {
  final List<int> postIds;
  final int initialIndex;
  /// Optional callback for searching tags (used in desktop mode)
  final void Function(String tag)? onSearchTag;

  const PostDetailPage({
    super.key,
    required this.postIds,
    required this.initialIndex,
    this.onSearchTag,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  late PageController _pageController;
  late int _currentIndex;
  final Map<int, Post?> _loadedPosts = {};
  final Map<int, bool> _loadingStates = {};
  final Map<int, String?> _errorStates = {};
  
  // Action states per post index
  final Map<int, bool> _isFavorited = {};
  final Map<int, int?> _userVote = {}; // 1 = upvoted, -1 = downvoted, null = no vote
  final Map<int, PostScore?> _updatedScores = {};
  final Map<int, bool> _isVoting = {};
  final Map<int, bool> _isTogglingFavorite = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _loadPost(_currentIndex);
    // Preload adjacent posts
    _preloadAdjacentPosts();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
    if (_loadingStates[index] == true || _loadedPosts.containsKey(index)) return;

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

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    _loadPost(index);
    _preloadAdjacentPosts();
  }

  int get _currentPostId => widget.postIds[_currentIndex];
  Post? get _currentPost => _loadedPosts[_currentIndex];

  // Vote on a post
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

  // Toggle favorite status
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

  // Show comments sheet
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
    // Use callback if provided (desktop mode), otherwise navigate
    if (widget.onSearchTag != null) {
      widget.onSearchTag!(tag);
    } else {
      Navigator.of(context).pushNamed(
        AppRoutes.search,
        arguments: tag,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasMultiplePosts = widget.postIds.length > 1;
    
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          hasMultiplePosts 
            ? 'Post #$_currentPostId (${_currentIndex + 1}/${widget.postIds.length})'
            : 'Post #$_currentPostId',
        ),
        trailing: _currentPost != null
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _showMoreOptions(),
                child: const Icon(CupertinoIcons.ellipsis),
              )
            : null,
      ),
      child: SafeArea(
        child: hasMultiplePosts
            ? PageView.builder(
                controller: _pageController,
                itemCount: widget.postIds.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) => _buildPageContent(index),
              )
            : _buildPageContent(0),
      ),
    );
  }

  Widget _buildPageContent(int index) {
    final post = _loadedPosts[index];
    final isLoading = _loadingStates[index] == true;
    final error = _errorStates[index];

    if (isLoading) {
      return const FullPageLoading(message: 'Loading post...');
    }

    if (error != null) {
      return ErrorState(
        message: error,
        onRetry: () => _loadPost(index),
      );
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
          _buildActionBar(index, post),
          _buildStats(post, index),
          _buildDescription(post),
          _buildTags(post),
          _buildMetadata(post),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildActionBar(int index, Post post) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final isFav = _isFavorited[index] ?? post.isFavorited;
    final userVote = _userVote[index];
    final isVoting = _isVoting[index] == true;
    final isTogglingFav = _isTogglingFavorite[index] == true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSecondaryBackground
            : CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Upvote button
          _buildActionButton(
            icon: CupertinoIcons.arrow_up_circle,
            activeIcon: CupertinoIcons.arrow_up_circle_fill,
            label: 'Upvote',
            isActive: userVote == 1,
            isLoading: isVoting,
            color: AppColors.safeColor,
            onTap: () => _vote(index, userVote == 1 ? 0 : 1),
          ),
          // Downvote button
          _buildActionButton(
            icon: CupertinoIcons.arrow_down_circle,
            activeIcon: CupertinoIcons.arrow_down_circle_fill,
            label: 'Downvote',
            isActive: userVote == -1,
            isLoading: isVoting,
            color: AppColors.explicitColor,
            onTap: () => _vote(index, userVote == -1 ? 0 : -1),
          ),
          // Favorite button
          _buildActionButton(
            icon: CupertinoIcons.heart,
            activeIcon: CupertinoIcons.heart_fill,
            label: 'Favorite',
            isActive: isFav,
            isLoading: isTogglingFav,
            color: AppColors.explicitColor,
            onTap: () => _toggleFavorite(index),
          ),
          // Comments button
          _buildActionButton(
            icon: CupertinoIcons.chat_bubble,
            activeIcon: CupertinoIcons.chat_bubble_fill,
            label: '${post.commentCount}',
            isActive: false,
            isLoading: false,
            color: AppColors.primaryBlue,
            onTap: () => _showComments(index),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onPressed: isLoading ? null : onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            SizedBox(
              width: 24,
              height: 24,
              child: CupertinoActivityIndicator(
                color: color,
              ),
            )
          else
            Icon(
              isActive ? activeIcon : icon,
              size: 24,
              color: isActive ? color : CupertinoColors.secondaryLabel,
            ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isActive ? color : CupertinoColors.secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(Post post) {
    // For videos, show the video player
    if (post.isVideo && post.file.url != null) {
      return AspectRatio(
        aspectRatio: post.file.aspectRatio.clamp(0.5, 2.0),
        child: VideoPlayerWidget(
          videoUrl: post.file.url!,
          thumbnailUrl: post.preview.url,
          autoPlay: false,
          looping: true,
          showControls: true,
          aspectRatio: post.file.aspectRatio,
        ),
      );
    }
    
    // For images
    final imageUrl = post.sample.has ? post.sample.url : post.preview.url;

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
              child: const Center(
                child: CupertinoActivityIndicator(),
              ),
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

  Widget _buildStats(Post post, int index) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final score = _updatedScores[index] ?? post.score;
    final isFav = _isFavorited[index] ?? post.isFavorited;
    // Adjust fav count based on local favorite state change
    final favCount = isFav != post.isFavorited 
        ? (isFav ? post.favCount + 1 : post.favCount - 1)
        : post.favCount;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSecondaryBackground
            : CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: CupertinoIcons.arrow_up,
            value: score.total.toString(),
            label: 'Score',
            color: score.total >= 0
                ? AppColors.safeColor
                : AppColors.explicitColor,
          ),
          _buildStatItem(
            icon: CupertinoIcons.heart_fill,
            value: favCount.compact,
            label: 'Favorites',
            color: AppColors.explicitColor,
          ),
          _buildStatItem(
            icon: CupertinoIcons.chat_bubble_fill,
            value: post.commentCount.toString(),
            label: 'Comments',
            color: AppColors.primaryBlue,
          ),
          _buildRatingBadge(post),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
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
          style: TextStyle(
            fontSize: 12,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingBadge(Post post) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: post.ratingColor,
            borderRadius: BorderRadius.circular(8),
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
        const SizedBox(height: 4),
        Text(
          post.ratingLabel,
          style: TextStyle(
            fontSize: 12,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(Post post) {
    if (post.description.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            post.description,
            style: TextStyle(
              fontSize: 15,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTags(Post post) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tags',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          CategorizedTagList(
            tags: post.tags,
            onTagTap: _searchTag,
          ),
        ],
      ),
    );
  }

  Widget _buildMetadata(Post post) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSecondaryBackground
            : CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildMetadataRow('ID', '#${post.id}'),
          _buildMetadataRow('Posted', post.createdAt.relativeTime),
          _buildMetadataRow('Resolution', '${post.file.width}x${post.file.height}'),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
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
            child: Text(_currentPost?.isVideo == true ? 'View Full Video' : 'View Full Resolution'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              // Could implement share functionality
            },
            child: const Text('Share'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              // Could implement download functionality
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

  const _FullScreenImageViewer({
    required this.imageUrl,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black.withOpacity(0.5),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(
            CupertinoIcons.xmark,
            color: CupertinoColors.white,
          ),
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

/// Comments sheet for displaying and posting comments
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
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkBackground
            : CupertinoColors.systemBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey3,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Comments',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Icon(CupertinoIcons.xmark_circle_fill),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            color: CupertinoColors.separator.resolveFrom(context),
          ),
          // Comments list
          Expanded(
            child: _buildCommentsList(),
          ),
          // Comment input
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: 8 + bottomPadding,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSecondaryBackground
                  : CupertinoColors.white,
              border: Border(
                top: BorderSide(
                  color: CupertinoColors.separator.resolveFrom(context),
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
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBackground
                          : CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _isPosting ? null : _postComment,
                  child: _isPosting
                      ? const CupertinoActivityIndicator()
                      : Icon(
                          CupertinoIcons.paperplane_fill,
                          color: CupertinoTheme.of(context).primaryColor,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    if (_isLoading) {
      return const Center(
        child: CupertinoActivityIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 48,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: CupertinoColors.systemGrey),
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.chat_bubble,
              size: 48,
              color: CupertinoColors.systemGrey,
            ),
            SizedBox(height: 16),
            Text(
              'No comments yet',
              style: TextStyle(color: CupertinoColors.systemGrey),
            ),
            SizedBox(height: 8),
            Text(
              'Be the first to comment!',
              style: TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _comments.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final comment = _comments[index];
        return _CommentCard(comment: comment);
      },
    );
  }
}

/// Individual comment card
class _CommentCard extends StatelessWidget {
  final Comment comment;

  const _CommentCard({required this.comment});

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSecondaryBackground
            : CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                comment.creatorName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  Icon(
                    comment.score >= 0
                        ? CupertinoIcons.arrow_up
                        : CupertinoIcons.arrow_down,
                    size: 14,
                    color: comment.score >= 0
                        ? AppColors.safeColor
                        : AppColors.explicitColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    comment.score.abs().toString(),
                    style: TextStyle(
                      fontSize: 12,
                      color: comment.score >= 0
                          ? AppColors.safeColor
                          : AppColors.explicitColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment.body,
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            comment.createdAt.relativeTime,
            style: TextStyle(
              fontSize: 12,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }
}
