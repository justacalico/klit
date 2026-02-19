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
