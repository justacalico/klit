/// Optional subfeed attached to a feed: adds extra include/exclude tags when active.
class SubFeed {
  final String id;
  final String name;
  final List<String> includeTags;
  final List<String> excludeTags;

  const SubFeed({
    required this.id,
    required this.name,
    this.includeTags = const [],
    this.excludeTags = const [],
  });

  factory SubFeed.fromJson(Map<String, dynamic> json) {
    final include = json['includeTags'];
    final exclude = json['excludeTags'];
    return SubFeed(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      includeTags: include is List<dynamic>
          ? (include).map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList()
          : [],
      excludeTags: exclude is List<dynamic>
          ? (exclude).map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'includeTags': includeTags,
        'excludeTags': excludeTags,
      };

  SubFeed copyWith({
    String? id,
    String? name,
    List<String>? includeTags,
    List<String>? excludeTags,
  }) =>
      SubFeed(
        id: id ?? this.id,
        name: name ?? this.name,
        includeTags: includeTags ?? this.includeTags,
        excludeTags: excludeTags ?? this.excludeTags,
      );
}

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
  /// Host URLs to load from (e.g. e926, e621, e6ai). Empty = current host only.
  final List<String> hostUrls;
  /// Rating filter: null or 'all' = all, 's' = safe, 'q' = questionable, 'e' = explicit.
  final String? rating;
  /// Sort order: e.g. 'id_desc', 'id_asc', 'score', 'favcount'.
  final String order;
  /// When true, exclude posts the user has favorited from this feed.
  final bool excludeFavorites;
  /// Subfeeds: only one can be active at a time; each adds extra include/exclude tags.
  final List<SubFeed> subfeeds;

  const Feed({
    required this.id,
    required this.name,
    required this.mediaType,
    required this.includeTags,
    required this.orTags,
    required this.excludeTags,
    this.hostUrls = const [],
    this.rating,
    this.order = 'id_desc',
    this.excludeFavorites = false,
    this.subfeeds = const [],
  });

  /// True if this feed is video-only (for backward compatibility).
  bool get isVideo => mediaType == mediaTypeVideo;

  factory Feed.fromJson(Map<String, dynamic> json) {
    final include = json['includeTags'];
    final or = json['orTags'];
    final exclude = json['excludeTags'];
    final hostUrlsRaw = json['hostUrls'];
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
      hostUrls: hostUrlsRaw is List<dynamic>
          ? (hostUrlsRaw).map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList()
          : [],
      rating: json['rating'] as String?,
      order: json['order'] as String? ?? 'id_desc',
      excludeFavorites: json['excludeFavorites'] as bool? ?? false,
      subfeeds: _parseSubfeeds(json['subfeeds']),
    );
  }

  static List<SubFeed> _parseSubfeeds(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .map((e) => e is Map<String, dynamic> ? SubFeed.fromJson(e) : null)
        .whereType<SubFeed>()
        .toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mediaType': mediaType,
      'includeTags': includeTags,
      'orTags': orTags,
      'excludeTags': excludeTags,
      'hostUrls': hostUrls,
      if (rating != null) 'rating': rating,
      'order': order,
      'excludeFavorites': excludeFavorites,
      'subfeeds': subfeeds.map((s) => s.toJson()).toList(),
    };
  }

  Feed copyWith({
    String? id,
    String? name,
    String? mediaType,
    List<String>? includeTags,
    List<String>? orTags,
    List<String>? excludeTags,
    List<String>? hostUrls,
    String? rating,
    String? order,
    bool? excludeFavorites,
    List<SubFeed>? subfeeds,
  }) {
    return Feed(
      id: id ?? this.id,
      name: name ?? this.name,
      mediaType: mediaType ?? this.mediaType,
      includeTags: includeTags ?? this.includeTags,
      orTags: orTags ?? this.orTags,
      excludeTags: excludeTags ?? this.excludeTags,
      hostUrls: hostUrls ?? this.hostUrls,
      rating: rating ?? this.rating,
      order: order ?? this.order,
      excludeFavorites: excludeFavorites ?? this.excludeFavorites,
      subfeeds: subfeeds ?? this.subfeeds,
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

  /// Base query plus optional subfeed: when [subfeed] is non-null, appends its include/exclude tags.
  String toSearchQueryWithSubfeed(SubFeed? subfeed) {
    var q = toSearchQuery();
    if (subfeed == null) return q;
    final extra = <String>[];
    if (subfeed.includeTags.isNotEmpty) {
      extra.add(subfeed.includeTags.join(' '));
    }
    for (final t in subfeed.excludeTags) {
      if (t.trim().isEmpty) continue;
      extra.add('-${t.trim()}');
    }
    if (extra.isEmpty) return q;
    return '$q ${extra.join(' ')}'.trim();
  }
}
