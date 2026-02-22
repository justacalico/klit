import 'dart:convert';

import '../models/models.dart';

/// Top-level function for use with compute().
/// Parses raw JSON response body from posts list endpoint into `List<Post>`.
List<Post> parsePostsFromJsonString(String body) {
  final decoded = json.decode(body) as Map<String, dynamic>;
  final postsData = decoded['posts'] as List<dynamic>?;
  if (postsData == null || postsData.isEmpty) return [];

  return postsData
      .where((e) => e != null && e is Map<String, dynamic>)
      .map((e) => Post.fromJson(e as Map<String, dynamic>))
      .where((p) => p.file.url != null)
      .toList();
}

/// Top-level function for use with compute().
/// Parses raw JSON response body from single post endpoint (e.g. /posts/:id.json).
Post? parseSinglePostFromJsonString(String body) {
  final decoded = json.decode(body) as Map<String, dynamic>;
  final postData = decoded['post'];
  if (postData == null || postData is! Map<String, dynamic>) return null;

  return Post.fromJson(postData);
}
