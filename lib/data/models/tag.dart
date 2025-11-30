import 'package:flutter/cupertino.dart';
import '../../core/constants/app_constants.dart';

/// Model representing a tag from e621 API
class Tag {
  final int id;
  final String name;
  final int postCount;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isLocked;

  const Tag({
    required this.id,
    required this.name,
    required this.postCount,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    required this.isLocked,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as int,
      name: json['name'] as String,
      postCount: json['post_count'] as int,
      category: _categoryFromInt(json['category'] as int),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isLocked: json['is_locked'] as bool,
    );
  }

  static String _categoryFromInt(int category) {
    switch (category) {
      case 0:
        return 'general';
      case 1:
        return 'artist';
      case 3:
        return 'copyright';
      case 4:
        return 'character';
      case 5:
        return 'species';
      case 6:
        return 'invalid';
      case 7:
        return 'meta';
      case 8:
        return 'lore';
      default:
        return 'general';
    }
  }

  /// Get the color for this tag category
  Color get color {
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

/// Search parameters for posts
class PostSearchParams {
  final String? tags;
  final String? rating;
  final String? order;
  final int page;
  final int limit;

  const PostSearchParams({
    this.tags,
    this.rating,
    this.order,
    this.page = 1,
    this.limit = 50,
  });

  PostSearchParams copyWith({
    String? tags,
    String? rating,
    String? order,
    int? page,
    int? limit,
  }) {
    return PostSearchParams(
      tags: tags ?? this.tags,
      rating: rating ?? this.rating,
      order: order ?? this.order,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };

    final tagParts = <String>[];
    if (tags != null && tags!.isNotEmpty) {
      tagParts.add(tags!);
    }
    if (rating != null && rating!.isNotEmpty) {
      tagParts.add('rating:$rating');
    }
    if (order != null && order!.isNotEmpty) {
      tagParts.add('order:$order');
    }

    if (tagParts.isNotEmpty) {
      params['tags'] = tagParts.join(' ');
    }

    return params;
  }
}

/// Search history item
class SearchHistoryItem {
  final String query;
  final DateTime timestamp;

  const SearchHistoryItem({
    required this.query,
    required this.timestamp,
  });

  factory SearchHistoryItem.fromJson(Map<String, dynamic> json) {
    return SearchHistoryItem(
      query: json['query'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
