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

/// Post detail page
class PostDetailPage extends StatefulWidget {
  final int postId;

  const PostDetailPage({super.key, required this.postId});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  Post? _post;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  Future<void> _loadPost() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final apiService = context.read<ApiService>();
    final result = await apiService.getPostById(widget.postId);

    result.when(
      success: (post) {
        setState(() {
          _post = post;
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

  void _openFullMedia() {
    if (_post == null) return;
    
    if (_post!.isVideo) {
      if (_post!.file.url == null) return;
      Navigator.of(context).push(
        CupertinoPageRoute(
          fullscreenDialog: true,
          builder: (context) => FullScreenVideoViewer(
            videoUrl: _post!.file.url!,
            thumbnailUrl: _post!.preview.url,
          ),
        ),
      );
    } else {
      if (_post?.file.url == null) return;
      Navigator.of(context).push(
        CupertinoPageRoute(
          fullscreenDialog: true,
          builder: (context) => _FullScreenImageViewer(
            imageUrl: _post!.file.url!,
            heroTag: 'post_${_post!.id}',
          ),
        ),
      );
    }
  }

  void _searchTag(String tag) {
    Navigator.of(context).pushNamed(
      AppRoutes.search,
      arguments: tag,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Post #${widget.postId}'),
        trailing: _post != null
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _showMoreOptions(),
                child: const Icon(CupertinoIcons.ellipsis),
              )
            : null,
      ),
      child: SafeArea(
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const FullPageLoading(message: 'Loading post...');
    }

    if (_error != null) {
      return ErrorState(
        message: _error,
        onRetry: _loadPost,
      );
    }

    if (_post == null) {
      return const EmptyState(
        icon: CupertinoIcons.photo,
        title: 'Post not found',
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImage(),
          _buildStats(),
          _buildDescription(),
          _buildTags(),
          _buildMetadata(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildImage() {
    final post = _post!;
    
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

  Widget _buildStats() {
    final post = _post!;
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
            value: post.score.total.toString(),
            label: 'Score',
            color: post.score.total >= 0
                ? AppColors.safeColor
                : AppColors.explicitColor,
          ),
          _buildStatItem(
            icon: CupertinoIcons.heart_fill,
            value: post.favCount.compact,
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

  Widget _buildDescription() {
    final post = _post!;
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

  Widget _buildTags() {
    final post = _post!;

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

  Widget _buildMetadata() {
    final post = _post!;
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
            child: Text(_post?.isVideo == true ? 'View Full Video' : 'View Full Resolution'),
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
