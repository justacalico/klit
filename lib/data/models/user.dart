/// Model representing a user profile from the e926 API
class User {
  final int id;
  final String name;
  final int level;
  final String levelString;
  final int postUploadCount;
  final int postUpdateCount;
  final int noteUpdateCount;
  final bool isBanned;
  final bool canApprovePosts;
  final bool canUploadFree;
  final int favoriteCount;
  final int positiveFeedbackCount;
  final int neutralFeedbackCount;
  final int negativeFeedbackCount;
  final DateTime createdAt;
  final String? avatarId;
  final String? blacklistedTags;

  const User({
    required this.id,
    required this.name,
    required this.level,
    required this.levelString,
    required this.postUploadCount,
    required this.postUpdateCount,
    required this.noteUpdateCount,
    required this.isBanned,
    required this.canApprovePosts,
    required this.canUploadFree,
    required this.favoriteCount,
    required this.positiveFeedbackCount,
    required this.neutralFeedbackCount,
    required this.negativeFeedbackCount,
    required this.createdAt,
    this.avatarId,
    this.blacklistedTags,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      level: json['level'] as int,
      levelString: json['level_string'] as String? ?? _levelToString(json['level'] as int),
      postUploadCount: json['post_upload_count'] as int? ?? 0,
      postUpdateCount: json['post_update_count'] as int? ?? 0,
      noteUpdateCount: json['note_update_count'] as int? ?? 0,
      isBanned: json['is_banned'] as bool? ?? false,
      canApprovePosts: json['can_approve_posts'] as bool? ?? false,
      canUploadFree: json['can_upload_free'] as bool? ?? false,
      favoriteCount: json['favorite_count'] as int? ?? 0,
      positiveFeedbackCount: json['positive_feedback_count'] as int? ?? 0,
      neutralFeedbackCount: json['neutral_feedback_count'] as int? ?? 0,
      negativeFeedbackCount: json['negative_feedback_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      avatarId: json['avatar_id']?.toString(),
    );
  }

  static String _levelToString(int level) {
    switch (level) {
      case 0:
        return 'Anonymous';
      case 10:
        return 'Restricted';
      case 20:
        return 'Member';
      case 30:
        return 'Privileged';
      case 31:
        return 'Former Staff';
      case 32:
        return 'Janitor';
      case 33:
        return 'Moderator';
      case 34:
        return 'Admin';
      default:
        return 'Member';
    }
  }

  /// Get the account age in a human-readable format
  String get accountAge {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays >= 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''}';
    } else if (difference.inDays >= 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''}';
    } else if (difference.inDays >= 1) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''}';
    } else {
      return 'Today';
    }
  }

  /// Get total feedback count
  int get totalFeedback => positiveFeedbackCount + neutralFeedbackCount + negativeFeedbackCount;

  /// Get feedback ratio (positive / total)
  double get feedbackRatio {
    if (totalFeedback == 0) return 0;
    return positiveFeedbackCount / totalFeedback;
  }
}
