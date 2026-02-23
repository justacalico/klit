import 'post.dart';

/// A post plus its source host URL (for multi-host feed/search).
class PostWithSource {
  const PostWithSource({required this.post, required this.hostUrl});

  final Post post;
  final String hostUrl;
}
