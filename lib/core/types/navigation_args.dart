/// Arguments for navigating to search or feed view.
/// When [feedTitle] is non-null, the search page runs in feed mode (no search bar, no history).
/// When [hostUrls] is non-empty, search runs on each host and results are merged.
class SearchRouteArguments {
  const SearchRouteArguments({
    this.query,
    this.feedTitle,
    this.hostUrls,
  });

  final String? query;
  final String? feedTitle;
  /// When non-empty, multi-host search is used (e.g. e926 + e621).
  final List<String>? hostUrls;
}

/// Arguments for navigating to post detail with swipe support.
/// When [postHostUrls] is provided, each post uses that host for API actions (vote, favorite, etc.).
class PostDetailArguments {
  const PostDetailArguments({
    required this.postIds,
    required this.initialIndex,
    this.onLoadMore,
    this.hasMore = false,
    this.postHostUrls,
  });

  final List<int> postIds;
  final int initialIndex;

  /// Callback to load more posts, returns new post IDs
  final Future<List<int>> Function()? onLoadMore;

  /// Whether there are more posts to load
  final bool hasMore;

  /// Host URL per post (same length as [postIds]). When present, post detail uses this host for each post's API calls.
  final List<String>? postHostUrls;
}
