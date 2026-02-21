import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';

import '../../core/constants/constants.dart';
import '../../core/extensions/extensions.dart';
import '../../core/theme/ui_style_manager.dart';
import '../../data/models/models.dart';
import 'loading_shimmer.dart';

/// Post card display style
enum PostCardStyle { grid, list }

/// Reusable post card widget
class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.onTap,
    this.style = PostCardStyle.grid,
    this.showInfo = true,
  });

  final Post post;
  final VoidCallback onTap;
  final PostCardStyle style;
  final bool showInfo;

  @override
  Widget build(BuildContext context) {
    return style == PostCardStyle.grid
        ? _buildGridCard(context)
        : _buildListCard(context);
  }

  Widget _buildGridCard(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final isLiquidGlass = UIStyleManager.isLiquidGlass(context);
    final ratingColor = post.ratingColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSecondaryBackground
              : CupertinoColors.white,
          borderRadius: BorderRadius.circular(isLiquidGlass ? 12 : 8),
          border: Border.all(
            color: ratingColor.withValues(alpha: isLiquidGlass ? 0.7 : 0.6),
            width: isLiquidGlass ? 1.5 : 2,
          ),
          boxShadow: isLiquidGlass
              ? [
                  BoxShadow(
                    color: ratingColor.withValues(alpha: isDark ? 0.5 : 0.35),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: ratingColor.withValues(alpha: isDark ? 0.3 : 0.2),
                    blurRadius: 6,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: CupertinoColors.white.withValues(
                      alpha: isDark ? 0.08 : 0.15,
                    ),
                    blurRadius: 2,
                    spreadRadius: 0,
                    offset: const Offset(0, -1),
                  ),
                  BoxShadow(
                    color: CupertinoColors.black.withValues(
                      alpha: isDark ? 0.4 : 0.12,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: ratingColor.withValues(alpha: isDark ? 0.4 : 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: CupertinoColors.black.withValues(
                      alpha: isDark ? 0.3 : 0.08,
                    ),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [_buildImage(), if (showInfo) _buildOverlay(context)],
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSecondaryBackground
              : CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(
                alpha: isDark ? 0.3 : 0.08,
              ),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            SizedBox(width: 120, height: 120, child: _buildImage()),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildRatingBadge(),
                        const SizedBox(width: 8),
                        if (post.isVideo) _buildVideoBadge(),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildStats(context),
                    const SizedBox(height: 8),
                    _buildTagsPreview(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    final imageUrl = post.preview.url ?? post.displayUrl;

    if (imageUrl == null) {
      return Container(
        color: CupertinoColors.systemGrey5,
        child: Center(
          child: Icon(
            post.isVideo
                ? CupertinoIcons.play_rectangle_fill
                : CupertinoIcons.photo,
            size: 40,
            color: CupertinoColors.systemGrey,
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => const LoadingShimmer(),
          errorWidget: (context, url, error) => Container(
            color: CupertinoColors.systemGrey5,
            child: Center(
              child: Icon(
                post.isVideo
                    ? CupertinoIcons.play_rectangle_fill
                    : CupertinoIcons.exclamationmark_triangle,
                size: 30,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ),
        ),
        if (post.isVideo)
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.play_fill,
                color: CupertinoColors.white,
                size: 24,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOverlay(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              CupertinoColors.black.withValues(alpha: 0),
              CupertinoColors.black.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: Row(
          children: [
            if (post.isVideo) ...[_buildVideoBadge(), const SizedBox(width: 4)],
            const Spacer(),
            _buildScoreBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: post.ratingColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        post.rating.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: CupertinoColors.white,
        ),
      ),
    );
  }

  Widget _buildVideoBadge() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CupertinoColors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(
        CupertinoIcons.play_fill,
        size: 12,
        color: CupertinoColors.white,
      ),
    );
  }

  Widget _buildScoreBadge() {
    final score = post.score.total;
    final color = score >= 0 ? AppColors.safeColor : AppColors.explicitColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: CupertinoColors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            score >= 0 ? CupertinoIcons.arrow_up : CupertinoIcons.arrow_down,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            score.abs().compact,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    return Row(
      children: [
        _buildStatItem(CupertinoIcons.arrow_up, post.score.total.compact),
        const SizedBox(width: 12),
        _buildStatItem(CupertinoIcons.heart_fill, post.favCount.compact),
        const SizedBox(width: 12),
        _buildStatItem(
          CupertinoIcons.chat_bubble,
          post.commentCount.toString(),
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: CupertinoColors.secondaryLabel),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: CupertinoColors.secondaryLabel,
          ),
        ),
      ],
    );
  }

  Widget _buildTagsPreview(BuildContext context) {
    final previewTags = post.tags.all.take(3).toList();

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: previewTags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey5,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            tag.replaceAll('_', ' '),
            style: const TextStyle(
              fontSize: 10,
              color: CupertinoColors.secondaryLabel,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
    );
  }
}
