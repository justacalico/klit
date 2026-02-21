import 'package:flutter/cupertino.dart';
import '../../core/constants/app_constants.dart';

/// Model representing a post from e926 API
class Post {
  final int id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final PostFile file;
  final PostPreview preview;
  final PostSample sample;
  final PostScore score;
  final PostTags tags;
  final List<int> lockedTags;
  final int changeSeq;
  final PostFlags flags;
  final String rating;
  final int favCount;
  final List<String> sources;
  final List<int> pools;
  final PostRelationships relationships;
  final int? approverId;
  final int uploaderId;
  final String? uploaderName;
  final String description;
  final int commentCount;
  final bool isFavorited;
  final bool hasNotes;
  final double? duration;

  const Post({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.file,
    required this.preview,
    required this.sample,
    required this.score,
    required this.tags,
    required this.lockedTags,
    required this.changeSeq,
    required this.flags,
    required this.rating,
    required this.favCount,
    required this.sources,
    required this.pools,
    required this.relationships,
    this.approverId,
    required this.uploaderId,
    this.uploaderName,
    required this.description,
    required this.commentCount,
    required this.isFavorited,
    required this.hasNotes,
    this.duration,
  });

  /// Create a Post from JSON
  factory Post.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse int
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    // Helper to safely parse required int
    int parseIntRequired(dynamic value, int defaultValue) {
      return parseInt(value) ?? defaultValue;
    }

    return Post(
      id: parseIntRequired(json['id'], 0),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      file: PostFile.fromJson(json['file'] as Map<String, dynamic>),
      preview: PostPreview.fromJson(json['preview'] as Map<String, dynamic>),
      sample: PostSample.fromJson(json['sample'] as Map<String, dynamic>),
      score: PostScore.fromJson(json['score'] as Map<String, dynamic>),
      tags: PostTags.fromJson(json['tags'] as Map<String, dynamic>),
      lockedTags:
          (json['locked_tags'] as List<dynamic>?)
              ?.map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
              .toList() ??
          [],
      changeSeq: parseIntRequired(json['change_seq'], 0),
      flags: PostFlags.fromJson(json['flags'] as Map<String, dynamic>),
      rating: json['rating'] as String? ?? 's',
      favCount: parseIntRequired(json['fav_count'], 0),
      sources: List<String>.from(json['sources'] ?? []),
      pools:
          (json['pools'] as List<dynamic>?)
              ?.map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
              .toList() ??
          [],
      relationships: PostRelationships.fromJson(
        json['relationships'] as Map<String, dynamic>,
      ),
      approverId: parseInt(json['approver_id']),
      uploaderId: parseIntRequired(json['uploader_id'], 0),
      uploaderName: json['owner'] as String? ?? json['uploader'] as String?,
      description: json['description'] as String? ?? '',
      commentCount: parseIntRequired(json['comment_count'], 0),
      isFavorited: json['is_favorited'] as bool? ?? false,
      hasNotes: json['has_notes'] as bool? ?? false,
      duration: json['duration'] != null
          ? (json['duration'] as num).toDouble()
          : null,
    );
  }

  /// Get the rating color
  Color get ratingColor {
    switch (rating) {
      case 's':
        return AppColors.safeColor;
      case 'q':
        return AppColors.questionableColor;
      case 'e':
        return AppColors.explicitColor;
      default:
        return AppColors.metaTagColor;
    }
  }

  /// Get the rating label
  String get ratingLabel {
    switch (rating) {
      case 's':
        return 'Safe';
      case 'q':
        return 'Questionable';
      case 'e':
        return 'Explicit';
      default:
        return 'Unknown';
    }
  }

  /// Check if post is a video
  bool get isVideo => file.ext == 'webm' || file.ext == 'mp4';

  /// Check if post is a gif
  bool get isGif => file.ext == 'gif';

  /// Check if post has sample
  bool get hasSample => sample.has;

  /// Get display URL (full resolution preferred, fallback to sample, then preview)
  String? get displayUrl => file.url ?? sample.url ?? preview.url;
}

/// Post file information
class PostFile {
  final int width;
  final int height;
  final String ext;
  final int size;
  final String md5;
  final String? url;

  const PostFile({
    required this.width,
    required this.height,
    required this.ext,
    required this.size,
    required this.md5,
    this.url,
  });

  factory PostFile.fromJson(Map<String, dynamic> json) {
    return PostFile(
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
      ext: json['ext'] as String? ?? '',
      size: (json['size'] as num?)?.toInt() ?? 0,
      md5: json['md5'] as String? ?? '',
      url: json['url'] as String?,
    );
  }

  double get aspectRatio => width / height;
}

/// Post preview information
class PostPreview {
  final int width;
  final int height;
  final String? url;

  const PostPreview({required this.width, required this.height, this.url});

  factory PostPreview.fromJson(Map<String, dynamic> json) {
    return PostPreview(
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
      url: json['url'] as String?,
    );
  }
}

/// Post sample information
class PostSample {
  final bool has;
  final int height;
  final int width;
  final String? url;
  final Map<String, dynamic>? alternates;

  const PostSample({
    required this.has,
    required this.height,
    required this.width,
    this.url,
    this.alternates,
  });

  factory PostSample.fromJson(Map<String, dynamic> json) {
    return PostSample(
      has: json['has'] as bool? ?? false,
      height: (json['height'] as num?)?.toInt() ?? 0,
      width: (json['width'] as num?)?.toInt() ?? 0,
      url: json['url'] as String?,
      alternates: json['alternates'] as Map<String, dynamic>?,
    );
  }
}

/// Post score information
class PostScore {
  final int up;
  final int down;
  final int total;

  const PostScore({required this.up, required this.down, required this.total});

  factory PostScore.fromJson(Map<String, dynamic> json) {
    return PostScore(
      up: (json['up'] as num?)?.toInt() ?? 0,
      down: (json['down'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Post tags
class PostTags {
  final List<String> general;
  final List<String> species;
  final List<String> character;
  final List<String> copyright;
  final List<String> artist;
  final List<String> invalid;
  final List<String> lore;
  final List<String> meta;

  const PostTags({
    required this.general,
    required this.species,
    required this.character,
    required this.copyright,
    required this.artist,
    required this.invalid,
    required this.lore,
    required this.meta,
  });

  factory PostTags.fromJson(Map<String, dynamic> json) {
    return PostTags(
      general: List<String>.from(json['general'] ?? []),
      species: List<String>.from(json['species'] ?? []),
      character: List<String>.from(json['character'] ?? []),
      copyright: List<String>.from(json['copyright'] ?? []),
      artist: List<String>.from(json['artist'] ?? []),
      invalid: List<String>.from(json['invalid'] ?? []),
      lore: List<String>.from(json['lore'] ?? []),
      meta: List<String>.from(json['meta'] ?? []),
    );
  }

  /// Get all tags as a flat list
  List<String> get all => [
    ...artist,
    ...copyright,
    ...character,
    ...species,
    ...general,
    ...lore,
    ...meta,
  ];

  /// Get tag color by category
  static Color getColorForCategory(String category) {
    switch (category) {
      case 'general':
        return AppColors.generalTagColor;
      case 'artist':
        return AppColors.artistTagColor;
      case 'copyright':
        return AppColors.copyrightTagColor;
      case 'character':
        return AppColors.characterTagColor;
      case 'species':
        return AppColors.speciesTagColor;
      case 'lore':
        return AppColors.lorTagColor;
      case 'meta':
        return AppColors.metaTagColor;
      default:
        return AppColors.generalTagColor;
    }
  }
}

/// Post flags
class PostFlags {
  final bool pending;
  final bool flagged;
  final bool noteLocked;
  final bool statusLocked;
  final bool ratingLocked;
  final bool deleted;

  const PostFlags({
    required this.pending,
    required this.flagged,
    required this.noteLocked,
    required this.statusLocked,
    required this.ratingLocked,
    required this.deleted,
  });

  factory PostFlags.fromJson(Map<String, dynamic> json) {
    return PostFlags(
      pending: json['pending'] as bool? ?? false,
      flagged: json['flagged'] as bool? ?? false,
      noteLocked: json['note_locked'] as bool? ?? false,
      statusLocked: json['status_locked'] as bool? ?? false,
      ratingLocked: json['rating_locked'] as bool? ?? false,
      deleted: json['deleted'] as bool? ?? false,
    );
  }
}

/// Post relationships
class PostRelationships {
  final int? parentId;
  final bool hasChildren;
  final bool hasActiveChildren;
  final List<int> children;

  const PostRelationships({
    this.parentId,
    required this.hasChildren,
    required this.hasActiveChildren,
    required this.children,
  });

  factory PostRelationships.fromJson(Map<String, dynamic> json) {
    return PostRelationships(
      parentId: (json['parent_id'] as num?)?.toInt(),
      hasChildren: json['has_children'] as bool? ?? false,
      hasActiveChildren: json['has_active_children'] as bool? ?? false,
      children:
          (json['children'] as List<dynamic>?)
              ?.map((e) => e is int ? e : (e as num).toInt())
              .toList() ??
          [],
    );
  }
}
