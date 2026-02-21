/// User-defined feed: saved tag filters and media type (image, video, or both).
/// Used like an RSS feed: open a feed to browse posts matching and/or/exclude tags and type.
class Feed {
  static const String mediaTypeImage = 'image';
  static const String mediaTypeVideo = 'video';
  static const String mediaTypeAll = 'all';

  final String id;
  final String name;
  /// One of [mediaTypeImage], [mediaTypeVideo], [mediaTypeAll].
  final String mediaType;
  final List<String> includeTags;
  final List<String> orTags;
  final List<String> excludeTags;

  const Feed({
    required this.id,
    required this.name,
    required this.mediaType,
    required this.includeTags,
    required this.orTags,
    required this.excludeTags,
  });

  /// True if this feed is video-only (for backward compatibility).
  bool get isVideo => mediaType == mediaTypeVideo;

  factory Feed.fromJson(Map<String, dynamic> json) {
    final include = json['includeTags'];
    final or = json['orTags'];
    final exclude = json['excludeTags'];
    String mt = json['mediaType'] as String? ?? '';
    if (mt != mediaTypeImage && mt != mediaTypeVideo && mt != mediaTypeAll) {
      mt = json['isVideo'] == true ? mediaTypeVideo : mediaTypeImage;
    }
    return Feed(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      mediaType: mt,
      includeTags: include is List<dynamic>
          ? (include).map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList()
          : [],
      orTags: or is List<dynamic>
          ? (or).map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList()
          : [],
      excludeTags: exclude is List<dynamic>
          ? (exclude).map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mediaType': mediaType,
      'includeTags': includeTags,
      'orTags': orTags,
      'excludeTags': excludeTags,
    };
  }

  Feed copyWith({
    String? id,
    String? name,
    String? mediaType,
    List<String>? includeTags,
    List<String>? orTags,
    List<String>? excludeTags,
  }) {
    return Feed(
      id: id ?? this.id,
      name: name ?? this.name,
      mediaType: mediaType ?? this.mediaType,
      includeTags: includeTags ?? this.includeTags,
      orTags: orTags ?? this.orTags,
      excludeTags: excludeTags ?? this.excludeTags,
    );
  }

  /// Build the search query string for this feed (tags + e621 file-type metatags).
  /// e621: space = AND, ~tag = OR (group with spaces around parens), -tag = exclude.
  String toSearchQuery() {
    final parts = <String>[];
    if (includeTags.isNotEmpty) {
      parts.add(includeTags.join(' '));
    }
    if (orTags.isNotEmpty) {
      final orClause = orTags.map((t) => '~${t.trim()}').where((s) => s.length > 1).join(' ');
      if (orClause.isNotEmpty) {
        parts.add('( $orClause )');
      }
    }
    for (final t in excludeTags) {
      if (t.trim().isEmpty) continue;
      parts.add('-${t.trim()}');
    }
    switch (mediaType) {
      case mediaTypeVideo:
        parts.add('( ~type:mp4 ~type:webm )');
        break;
      case mediaTypeAll:
        parts.add('( ~type:jpg ~type:png ~type:gif ~type:webp ~type:mp4 ~type:webm )');
        break;
      default:
        parts.add('( ~type:jpg ~type:png ~type:gif ~type:webp )');
    }
    return parts.join(' ').trim();
  }
}
