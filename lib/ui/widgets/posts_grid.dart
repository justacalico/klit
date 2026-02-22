import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../core/theme/ui_style_manager.dart';
import '../../data/models/models.dart';
import '../../providers/providers.dart';
import 'loading_indicator.dart';
import 'loading_shimmer.dart';
import 'post_card.dart';

/// Grid view for posts with infinite scroll support
class PostsGrid extends StatelessWidget {
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

  final List<Post> posts;
  final void Function(Post post) onPostTap;
  final int? columns;
  final double? spacing;
  final double? padding;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final VoidCallback? onLoadMore;
  final VoidCallback? onRetry;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final effectiveColumns =
            columns ?? settings.getEffectiveGridSize(screenWidth);
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
            cacheExtent: 600,
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
                      final isOled = settings.themeMode == 3;
                      final isLiquidGlass = UIStyleManager.isLiquidGlass(context);
                      final cellSize = (screenWidth -
                              2 * effectivePadding -
                              (effectiveColumns - 1) * effectiveSpacing) /
                          effectiveColumns;
                      final dpr = MediaQuery.devicePixelRatioOf(context);
                      final cacheW = (cellSize * dpr).round();
                      final cacheH = cacheW;
                      return RepaintBoundary(
                        child: PostCard(
                          post: post,
                          onTap: () => onPostTap(post),
                          style: PostCardStyle.grid,
                          isOled: isOled,
                          isLiquidGlass: isLiquidGlass,
                          memCacheWidth: cacheW,
                          memCacheHeight: cacheH,
                        ),
                      );
                    },
                    childCount: posts.length,
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
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
      },
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
