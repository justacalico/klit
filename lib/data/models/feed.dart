/// User-defined feed: saved tag filters and media type (image or video).
/// Used like an RSS feed: open a feed to browse posts matching and/or/exclude tags and type.
class Feed {
  final String id;
  final String name;
  final bool isVideo;
  final List<String> includeTags;
  final List<String> orTags;
  final List<String> excludeTags;

  const Feed({
    required this.id,
    required this.name,
    required this.isVideo,
    required this.includeTags,
    required this.orTags,
    required this.excludeTags,
  });

  factory Feed.fromJson(Map<String, dynamic> json) {
    final include = json['includeTags'];
    final or = json['orTags'];
    final exclude = json['excludeTags'];
    return Feed(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      isVideo: json['isVideo'] as bool? ?? false,
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
      'isVideo': isVideo,
      'includeTags': includeTags,
      'orTags': orTags,
      'excludeTags': excludeTags,
    };
  }

  Feed copyWith({
    String? id,
    String? name,
    bool? isVideo,
    List<String>? includeTags,
    List<String>? orTags,
    List<String>? excludeTags,
  }) {
    return Feed(
      id: id ?? this.id,
      name: name ?? this.name,
      isVideo: isVideo ?? this.isVideo,
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
    if (isVideo) {
      parts.add('( ~type:mp4 ~type:webm )');
    } else {
      parts.add('( ~type:jpg ~type:png ~type:gif ~type:webp )');
    }
    return parts.join(' ').trim();
  }
}
