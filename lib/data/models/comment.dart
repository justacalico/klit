/// Model representing a comment from e621 API
class Comment {
  final int id;
  final int postId;
  final int creatorId;
  final String creatorName;
  final String body;
  final int score;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? updaterId;
  final bool doNotBumpPost;
  final bool isHidden;
  final bool isSticky;
  final String? warningType;
  final int? warningUserId;

  const Comment({
    required this.id,
    required this.postId,
    required this.creatorId,
    required this.creatorName,
    required this.body,
    required this.score,
    required this.createdAt,
    required this.updatedAt,
    this.updaterId,
    required this.doNotBumpPost,
    required this.isHidden,
    required this.isSticky,
    this.warningType,
    this.warningUserId,
  });

  /// Create a Comment from JSON
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as int,
      postId: json['post_id'] as int,
      creatorId: json['creator_id'] as int,
      creatorName: json['creator_name'] as String? ?? 'Anonymous',
      body: json['body'] as String? ?? '',
      score: json['score'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      updaterId: json['updater_id'] as int?,
      doNotBumpPost: json['do_not_bump_post'] as bool? ?? false,
      isHidden: json['is_hidden'] as bool? ?? false,
      isSticky: json['is_sticky'] as bool? ?? false,
      warningType: json['warning_type'] as String?,
      warningUserId: json['warning_user_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'creator_id': creatorId,
      'creator_name': creatorName,
      'body': body,
      'score': score,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'updater_id': updaterId,
      'do_not_bump_post': doNotBumpPost,
      'is_hidden': isHidden,
      'is_sticky': isSticky,
      'warning_type': warningType,
      'warning_user_id': warningUserId,
    };
  }
}
