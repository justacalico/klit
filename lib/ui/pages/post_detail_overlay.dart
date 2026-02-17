import 'package:flutter/cupertino.dart';
import 'post_detail_page.dart';

/// Post detail overlay for desktop - full-screen overlay with close.
class UiPostDetailOverlay extends StatelessWidget {
  final List<int> postIds;
  final int initialIndex;
  final void Function(String tag)? onSearchTag;
  final VoidCallback onClose;
  final Future<List<int>> Function()? onLoadMore;
  final bool hasMore;

  const UiPostDetailOverlay({
    super.key,
    required this.postIds,
    required this.initialIndex,
    this.onSearchTag,
    required this.onClose,
    this.onLoadMore,
    this.hasMore = false,
  });

  @override
  Widget build(BuildContext context) {
    return PostDetailPage(
      postIds: postIds,
      initialIndex: initialIndex,
      onSearchTag: onSearchTag,
      onClose: onClose,
      onLoadMore: onLoadMore,
      hasMore: hasMore,
    );
  }
}
