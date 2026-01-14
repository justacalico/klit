import 'package:flutter/cupertino.dart';
import '../../desktop/pages/desktop_post_detail_page.dart';
import '../../desktop/responsive_layout.dart';
import 'post_detail_page.dart';

/// Responsive wrapper that switches between mobile and desktop post detail views
/// based on screen size. This allows live switching when resizing the window.
class ResponsivePostDetailPage extends StatelessWidget {
  final List<int> postIds;
  final int initialIndex;

  /// Optional callback for searching tags
  final void Function(String tag)? onSearchTag;

  /// Callback to load more posts, returns new post IDs
  final Future<List<int>> Function()? onLoadMore;

  /// Whether there are more posts to load
  final bool hasMore;

  const ResponsivePostDetailPage({
    super.key,
    required this.postIds,
    required this.initialIndex,
    this.onSearchTag,
    this.onLoadMore,
    this.hasMore = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use desktop layout for screens wider than desktop breakpoint
        if (constraints.maxWidth >= Breakpoints.desktop) {
          return DesktopPostDetailPage(
            postIds: postIds,
            initialIndex: initialIndex,
            onSearchTag: onSearchTag,
            onLoadMore: onLoadMore,
            hasMore: hasMore,
            onClose: () => Navigator.of(context).pop(),
          );
        }

        // Use mobile layout for smaller screens
        return PostDetailPage(
          postIds: postIds,
          initialIndex: initialIndex,
          onSearchTag: onSearchTag,
          onLoadMore: onLoadMore,
          hasMore: hasMore,
        );
      },
    );
  }
}
