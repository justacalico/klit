/// User-defined feed: saved tag filters and media type (image or video).
/// Used like an RSS feed: open a feed to browse posts matching include/exclude tags and type.
class Feed {
  final String id;
  final String name;
  final bool isVideo;
  final List<String> includeTags;
  final List<String> excludeTags;

  const Feed({
    required this.id,
    required this.name,
    required this.isVideo,
    required this.includeTags,
    required this.excludeTags,
  });

  factory Feed.fromJson(Map<String, dynamic> json) {
    final include = json['includeTags'];
    final exclude = json['excludeTags'];
    return Feed(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      isVideo: json['isVideo'] as bool? ?? false,
      includeTags: include is List<dynamic>
          ? (include).map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList()
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
      'excludeTags': excludeTags,
    };
  }

  Feed copyWith({
    String? id,
    String? name,
    bool? isVideo,
    List<String>? includeTags,
    List<String>? excludeTags,
  }) {
    return Feed(
      id: id ?? this.id,
      name: name ?? this.name,
      isVideo: isVideo ?? this.isVideo,
      includeTags: includeTags ?? this.includeTags,
      excludeTags: excludeTags ?? this.excludeTags,
    );
  }

  /// Build the search query string for this feed (tags + type:image or type:video).
  String toSearchQuery() {
    final parts = <String>[];
    if (includeTags.isNotEmpty) {
      parts.add(includeTags.join(' '));
    }
    for (final t in excludeTags) {
      if (t.trim().isEmpty) continue;
      parts.add('-${t.trim()}');
    }
    parts.add(isVideo ? 'type:video' : 'type:image');
    return parts.join(' ').trim();
  }
}
