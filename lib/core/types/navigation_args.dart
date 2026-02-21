/// Arguments for navigating to search or feed view.
/// When [feedTitle] is non-null, the search page runs in feed mode (no search bar, no history).
class SearchRouteArguments {
  const SearchRouteArguments({this.query, this.feedTitle});

  final String? query;
  final String? feedTitle;
}

/// Arguments for navigating to post detail with swipe support
class PostDetailArguments {
  const PostDetailArguments({
    required this.postIds,
    required this.initialIndex,
    this.onLoadMore,
    this.hasMore = false,
  });

  final List<int> postIds;
  final int initialIndex;

  /// Callback to load more posts, returns new post IDs
  final Future<List<int>> Function()? onLoadMore;

  /// Whether there are more posts to load
  final bool hasMore;
}
