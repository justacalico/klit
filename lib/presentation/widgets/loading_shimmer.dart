import 'package:flutter/cupertino.dart';
import 'package:shimmer/shimmer.dart';

/// Loading shimmer effect for content
class LoadingShimmer extends StatelessWidget {
  final double height;
  final double width;
  final double borderRadius;

  const LoadingShimmer({
    super.key,
    this.height = 100,
    this.width = double.infinity,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark
          ? const Color(0xFF2C2C2E)
          : const Color(0xFFE5E5EA),
      highlightColor: isDark
          ? const Color(0xFF3A3A3C)
          : const Color(0xFFF2F2F7),
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Grid shimmer for loading posts
class PostGridShimmer extends StatelessWidget {
  final int columns;
  final int itemCount;
  final double spacing;

  const PostGridShimmer({
    super.key,
    this.columns = 2,
    this.itemCount = 6,
    this.spacing = 4,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(spacing),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: 1,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => const LoadingShimmer(
        borderRadius: 8,
      ),
    );
  }
}

/// List shimmer for loading posts
class PostListShimmer extends StatelessWidget {
  final int itemCount;

  const PostListShimmer({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            const LoadingShimmer(
              height: 100,
              width: 100,
              borderRadius: 8,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LoadingShimmer(
                    height: 16,
                    width: MediaQuery.of(context).size.width * 0.4,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 8),
                  const LoadingShimmer(
                    height: 12,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 4),
                  LoadingShimmer(
                    height: 12,
                    width: MediaQuery.of(context).size.width * 0.3,
                    borderRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
