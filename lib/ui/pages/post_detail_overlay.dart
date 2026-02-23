import 'package:flutter/cupertino.dart';

import 'post_detail_page.dart';

/// Post detail overlay for desktop - full-screen overlay with close.
class UiPostDetailOverlay extends StatelessWidget {
  const UiPostDetailOverlay({
    super.key,
    required this.postIds,
    required this.initialIndex,
    this.onSearchTag,
    this.onCurrentIndexChanged,
    required this.onClose,
    this.onLoadMore,
    this.hasMore = false,
    this.postHostUrls,
  });

  final List<int> postIds;
  final int initialIndex;
  final void Function(String tag)? onSearchTag;
  final void Function(int currentIndex)? onCurrentIndexChanged;
  final VoidCallback onClose;
  final Future<List<int>> Function()? onLoadMore;
  final bool hasMore;
  final List<String>? postHostUrls;

  @override
  Widget build(BuildContext context) {
    return PostDetailPage(
      postIds: postIds,
      initialIndex: initialIndex,
      onSearchTag: onSearchTag,
      onCurrentIndexChanged: onCurrentIndexChanged,
      onClose: onClose,
      onLoadMore: onLoadMore,
      hasMore: hasMore,
      postHostUrls: postHostUrls,
    );
  }
}
