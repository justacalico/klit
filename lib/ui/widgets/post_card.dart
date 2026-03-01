import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../core/constants/constants.dart';
import '../../core/extensions/extensions.dart';
import '../../core/theme/ui_style_manager.dart';
import '../../data/models/models.dart';
import '../../providers/providers.dart';
import 'loading_shimmer.dart';

/// When a GIF is only shown animated when [visibleFraction] > threshold, to reduce lag.
const double _kGifVisibleThreshold = 0.15;

class _VisibilityAwareGifImage extends StatefulWidget {
  const _VisibilityAwareGifImage({
    required this.staticUrl,
    required this.animatedUrl,
    required this.postId,
    required this.placeholderColor,
    required this.style,
    required this.post,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  final String staticUrl;
  final String animatedUrl;
  final int postId;
  final Color placeholderColor;
  final PostCardStyle style;
  final Post post;
  final int? memCacheWidth;
  final int? memCacheHeight;

  @override
  State<_VisibilityAwareGifImage> createState() => _VisibilityAwareGifImageState();
}

class _VisibilityAwareGifImageState extends State<_VisibilityAwareGifImage> {
  double _visibleFraction = 0;

  @override
  Widget build(BuildContext context) {
    final useAnimated = _visibleFraction >= _kGifVisibleThreshold;
    final imageUrl = useAnimated ? widget.animatedUrl : widget.staticUrl;
    return VisibilityDetector(
      key: Key('gif_${widget.postId}'),
      onVisibilityChanged: (info) {
        if (mounted && info.visibleFraction != _visibleFraction) {
          setState(() => _visibleFraction = info.visibleFraction);
        }
      },
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        cacheKey: '${widget.postId}_$imageUrl',
        fit: BoxFit.cover,
        memCacheWidth: widget.memCacheWidth,
        memCacheHeight: widget.memCacheHeight,
        fadeInDuration: const Duration(milliseconds: 150),
        fadeInCurve: Curves.easeOut,
        placeholder: (context, url) => widget.style == PostCardStyle.grid
            ? Container(color: widget.placeholderColor)
            : const LoadingShimmer(),
        errorWidget: (context, url, error) => Container(
          color: widget.placeholderColor,
          child: Center(
            child: Icon(
              widget.post.isVideo
                  ? CupertinoIcons.play_rectangle_fill
                  : CupertinoIcons.exclamationmark_triangle,
              size: 30,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ),
      ),
    );
  }
}

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
    this.isOled,
    this.isLiquidGlass,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  final Post post;
  final VoidCallback onTap;
  final PostCardStyle style;
  final bool showInfo;
  /// When provided, avoids watching [SettingsProvider] for theme. Pass from parent for grid/list performance.
  final bool? isOled;
  /// When provided, avoids reading [UIStyleManager] in card. Pass from parent for grid/list performance.
  final bool? isLiquidGlass;
  /// Decode image at this width for grid thumbnails (reduces memory and decode time). Pass from grid.
  final int? memCacheWidth;
  /// Decode image at this height for grid thumbnails. Pass from grid.
  final int? memCacheHeight;

  @override
  Widget build(BuildContext context) {
    return style == PostCardStyle.grid
        ? _buildGridCard(context)
        : _buildListCard(context);
  }

  Widget _buildGridCard(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final liquidGlass = isLiquidGlass ?? UIStyleManager.isLiquidGlass(context);
    final ratingColor = post.ratingColor;
    final oled = isOled ?? context.read<SettingsProvider>().themeMode == 3;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.resolveSecondaryBackground(isDark, isOled: oled),
          borderRadius: BorderRadius.circular(liquidGlass ? 12 : 8),
          border: Border.all(
            color: ratingColor.withValues(alpha: liquidGlass ? 0.7 : 0.6),
            width: liquidGlass ? 1.5 : 2,
          ),
          boxShadow: liquidGlass
              ? [
                  BoxShadow(
                    color: ratingColor.withValues(alpha: isDark ? 0.45 : 0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: CupertinoColors.black.withValues(
                      alpha: isDark ? 0.35 : 0.1,
                    ),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
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
          children: [_buildImage(context), if (showInfo) _buildOverlay(context)],
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final oled = isOled ?? context.read<SettingsProvider>().themeMode == 3;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.resolveSecondaryBackground(isDark, isOled: oled),
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
            SizedBox(width: 120, height: 120, child: _buildImage(context)),
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

  Widget _buildImage(BuildContext context) {
    final gifAutoplay = context.watch<SettingsProvider>().gifAutoplay;
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final oled = isOled ?? context.read<SettingsProvider>().themeMode == 3;
    final placeholderColor =
        AppColors.resolveSecondaryBackground(isDark, isOled: oled);

    final staticUrl = post.preview.url ?? post.displayUrl;
    if (staticUrl == null) {
      return Container(
        color: placeholderColor,
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

    final useVisibilityAwareGif =
        post.isGif && gifAutoplay && (post.sample.url != null || post.file.url != null);
    final animatedUrl = post.sample.url ?? post.file.url ?? post.preview.url;

    Widget imageChild;
    if (useVisibilityAwareGif && animatedUrl != null) {
      imageChild = _VisibilityAwareGifImage(
        staticUrl: staticUrl,
        animatedUrl: animatedUrl,
        postId: post.id,
        placeholderColor: placeholderColor,
        style: style,
        post: post,
        memCacheWidth: memCacheWidth,
        memCacheHeight: memCacheHeight,
      );
    } else {
      final imageUrl = (post.isGif && gifAutoplay)
          ? (post.sample.url ?? post.file.url ?? post.preview.url)
          : staticUrl;
      imageChild = CachedNetworkImage(
        imageUrl: imageUrl ?? staticUrl,
        cacheKey: '${post.id}_$imageUrl',
        fit: BoxFit.cover,
        memCacheWidth: memCacheWidth,
        memCacheHeight: memCacheHeight,
        fadeInDuration: const Duration(milliseconds: 150),
        fadeInCurve: Curves.easeOut,
        placeholder: (context, url) => style == PostCardStyle.grid
            ? Container(color: placeholderColor)
            : const LoadingShimmer(),
        errorWidget: (context, url, error) => Container(
          color: placeholderColor,
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
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        imageChild,
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
