import 'package:flutter/cupertino.dart';

enum PostActionId {
  upvote('upvote', 'Upvote', CupertinoIcons.hand_thumbsup),
  downvote('downvote', 'Downvote', CupertinoIcons.hand_thumbsdown),
  favorite('favorite', 'Favorite', CupertinoIcons.heart),
  share('share', 'Share', CupertinoIcons.share),
  download('download', 'Download', CupertinoIcons.arrow_down_to_line),
  browse('browse', 'Browse', CupertinoIcons.globe);

  const PostActionId(this.key, this.label, this.icon);

  final String key;
  final String label;
  final IconData icon;

  static PostActionId? fromKey(String key) {
    for (final value in values) {
      if (value.key == key) return value;
    }
    return null;
  }
}

class PostActionPreferences {
  static const String settingKey = 'postActionBarActions';
  static const String legacyShareButtonKey = 'showShareButton';
  static const List<PostActionId> defaultActions = [
    PostActionId.favorite,
    PostActionId.downvote,
    PostActionId.upvote,
    PostActionId.download,
  ];
  static const List<PostActionId> menuActions = [
    PostActionId.share,
    PostActionId.download,
    PostActionId.browse,
  ];

  static List<PostActionId> decode(String raw) {
    final source = raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .map(PostActionId.fromKey)
        .whereType<PostActionId>();
    final deduped = <PostActionId>[];
    for (final action in source) {
      if (!deduped.contains(action)) {
        deduped.add(action);
      }
    }
    return deduped.isEmpty ? [...defaultActions] : deduped;
  }

  static String encode(List<PostActionId> actions) {
    if (actions.isEmpty) {
      return defaultActions.map((e) => e.key).join(',');
    }
    final deduped = <PostActionId>[];
    for (final action in actions) {
      if (!deduped.contains(action)) {
        deduped.add(action);
      }
    }
    return deduped.map((e) => e.key).join(',');
  }
}
