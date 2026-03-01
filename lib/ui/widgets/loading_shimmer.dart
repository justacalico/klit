import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/constants.dart';
import '../../providers/providers.dart';

/// Loading shimmer effect for content
class LoadingShimmer extends StatelessWidget {
  const LoadingShimmer({
    super.key,
    this.height = 100,
    this.width = double.infinity,
    this.borderRadius = 8,
    this.isOled,
  });

  final double height;
  final double width;
  final double borderRadius;
  /// When provided, avoids watching [SettingsProvider]. Pass from parent for grid performance.
  final bool? isOled;

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final oled = isOled ?? context.watch<SettingsProvider>().themeMode == 3;
    final baseColor = oled
        ? AppColors.oledBackground
        : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA));
    final highlightColor = oled
        ? const Color(0xFF0A0A0A)
        : (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF2F2F7));

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
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
  const PostGridShimmer({
    super.key,
    this.columns = 2,
    this.itemCount = 6,
    this.spacing = 4,
    this.isOled,
  });

  final int columns;
  final int itemCount;
  final double spacing;
  /// When provided, avoids each cell watching [SettingsProvider]. Pass from grid for performance.
  final bool? isOled;

  @override
  Widget build(BuildContext context) {
    final oled = isOled ?? context.read<SettingsProvider>().themeMode == 3;
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
      itemBuilder: (context, index) => LoadingShimmer(borderRadius: 8, isOled: oled),
    );
  }
}
