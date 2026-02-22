import '../data/models/models.dart';

/// Input for [filterBlacklistStatic]. Used with compute() to run filtering off the main isolate.
class BlacklistFilterInput {
  const BlacklistFilterInput({
    required this.posts,
    required this.blacklistLines,
    required this.enabled,
  });

  final List<Post> posts;
  final List<String> blacklistLines;
  final bool enabled;
}

/// Top-level function for use with compute().
/// Filters posts by blacklist rules; returns only posts that do not match any blacklist line.
List<Post> filterBlacklistStatic(BlacklistFilterInput input) {
  if (!input.enabled || input.blacklistLines.isEmpty) return input.posts;
  return input.posts
      .where((post) => !_isPostBlacklisted(post, input.blacklistLines))
      .toList();
}

bool _isPostBlacklisted(Post post, List<String> blacklistLines) {
  final postTags = post.tags.all.map((t) => t.toLowerCase()).toSet();
  for (final line in blacklistLines) {
    if (_matchesBlacklistLine(post, postTags, line)) return true;
  }
  return false;
}

bool _matchesBlacklistLine(Post post, Set<String> postTags, String line) {
  final parts = line.toLowerCase().split(RegExp(r'\s+'));
  if (parts.isEmpty) return false;
  for (final part in parts) {
    if (part.isEmpty) continue;
    if (part.startsWith('-')) {
      final tag = part.substring(1);
      if (_tagMatches(post, postTags, tag)) return false;
    } else {
      if (!_tagMatches(post, postTags, part)) return false;
    }
  }
  return true;
}

bool _tagMatches(Post post, Set<String> postTags, String condition) {
  if (condition.startsWith('rating:')) {
    return post.rating.toLowerCase() == condition.substring(7);
  }
  if (condition.startsWith('type:')) {
    final type = condition.substring(5);
    if (type == 'video' || type == 'webm' || type == 'gif') {
      return post.isVideo || post.file.ext.toLowerCase() == 'gif';
    }
    return post.file.ext.toLowerCase() == type;
  }
  if (condition.startsWith('user:')) {
    return post.uploaderId.toString() == condition.substring(5);
  }
  if (condition.contains('*')) {
    final pattern = RegExp('^${condition.replaceAll('*', '.*')}\$');
    return postTags.any((tag) => pattern.hasMatch(tag));
  }
  return postTags.contains(condition);
}
