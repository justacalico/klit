import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../data/models/models.dart';
import '../providers/settings_provider.dart';
import 'post_card.dart';
import 'loading_shimmer.dart';
import 'loading_indicator.dart';

/// Grid view for posts with infinite scroll support
class PostsGrid extends StatelessWidget {
  final List<Post> posts;
  final int? columns; // Optional - if null, uses settings
  final double? spacing; // Optional - if null, uses settings
  final double? padding; // Optional - if null, uses settings
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final VoidCallback? onLoadMore;
  final Function(Post post) onPostTap;
  final VoidCallback? onRetry;
  final ScrollController? scrollController;

  const PostsGrid({
    super.key,
    required this.posts,
    required this.onPostTap,
    this.columns,
    this.spacing,
    this.padding,
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.onLoadMore,
    this.onRetry,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Use provided values or fall back to settings
    final effectiveColumns = columns ?? settings.getEffectiveGridSize(screenWidth);
    final effectiveSpacing = spacing ?? settings.getEffectiveGridSpacing();
    final effectivePadding = padding ?? settings.getEffectiveGridPadding();

    if (posts.isEmpty && isLoading) {
      return PostGridShimmer(columns: effectiveColumns);
    }

    if (posts.isEmpty && error != null) {
      return _buildErrorView(context);
    }

    if (posts.isEmpty) {
      return _buildEmptyView(context);
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Trigger load more when user is approaching the end (800 pixels threshold)
        // Use ScrollUpdateNotification to catch scrolling as it happens
        if (notification is ScrollUpdateNotification || 
            notification is ScrollEndNotification) {
          final metrics = notification.metrics;
          if (metrics.pixels >= metrics.maxScrollExtent - 800) {
            if (hasMore && !isLoading && onLoadMore != null) {
              onLoadMore!();
            }
          }
        }
        return false;
      },
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverPadding(
            padding: EdgeInsets.all(effectivePadding),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: effectiveColumns,
                mainAxisSpacing: effectiveSpacing,
                crossAxisSpacing: effectiveSpacing,
                childAspectRatio: 1,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final post = posts[index];
                  return PostCard(
                    post: post,
                    onTap: () => onPostTap(post),
                    style: PostCardStyle.grid,
                  );
                },
                childCount: posts.length,
              ),
            ),
          ),
          if (isLoading && hasMore)
            const SliverToBoxAdapter(
              child: InfiniteScrollLoading(isLoading: true),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.photo_on_rectangle,
            size: 64,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
          const SizedBox(height: 16),
          Text(
            'No posts found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.exclamationmark_triangle,
            size: 64,
            color: CupertinoColors.destructiveRed.resolveFrom(context),
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error ?? 'An error occurred while loading posts',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 24),
            CupertinoButton.filled(
              onPressed: onRetry,
              child: const Text('Try Again'),
            ),
          ],
        ],
      ),
    );
  }
}
