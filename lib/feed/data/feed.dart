/// Optional subfeed: adds extra include/exclude tags when active. Can have nested subfeeds.
class SubFeed {
  const SubFeed({
    required this.id,
    required this.name,
    this.includeTags = const [],
    this.excludeTags = const [],
    this.subfeeds = const [],
  });

  final String id;
  final String name;
  final List<String> includeTags;
  final List<String> excludeTags;
  final List<SubFeed> subfeeds;

  factory SubFeed.fromJson(Map<String, dynamic> json) => SubFeed(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        includeTags: Feed._parseStringList(json['includeTags']),
        excludeTags: Feed._parseStringList(json['excludeTags']),
        subfeeds: _parseSubfeeds(json['subfeeds']),
      );

  static List<SubFeed> _parseSubfeeds(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .map((e) => e is Map<String, dynamic> ? SubFeed.fromJson(e) : null)
        .whereType<SubFeed>()
        .toList();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'includeTags': includeTags,
        'excludeTags': excludeTags,
        'subfeeds': subfeeds.map((s) => s.toJson()).toList(),
      };

  SubFeed copyWith({
    String? id,
    String? name,
    List<String>? includeTags,
    List<String>? excludeTags,
    List<SubFeed>? subfeeds,
  }) =>
      SubFeed(
        id: id ?? this.id,
        name: name ?? this.name,
        includeTags: includeTags ?? this.includeTags,
        excludeTags: excludeTags ?? this.excludeTags,
        subfeeds: subfeeds ?? this.subfeeds,
      );

  /// Appends this subfeed's include/exclude tags to [parts], then returns parts for further chaining.
  void appendTagParts(List<String> parts) {
    if (includeTags.isNotEmpty) parts.add(includeTags.join(' '));
    for (final t in excludeTags) {
      if (t.trim().isEmpty) continue;
      parts.add('-${t.trim()}');
    }
  }

  /// Collects this subfeed's plain include and exclude tags into the given sets.
  void collectTags(Set<String> includes, Set<String> excludes) {
    for (final t in includeTags) {
      final s = t.trim();
      if (s.isNotEmpty) includes.add(s);
    }
    for (final t in excludeTags) {
      final s = t.trim();
      if (s.isNotEmpty) excludes.add(s);
    }
  }
}

/// User-defined feed: saved tag filters and media type (image, video, or both).
/// Open a feed to browse posts matching include/or/exclude tags and type.
/// Subfeeds add extra include/exclude when selected; only one subfeed is active at a time.
class Feed {
  static const String mediaTypeImage = 'image';
  static const String mediaTypeVideo = 'video';
  static const String mediaTypeAll = 'all';

  const Feed({
    required this.id,
    required this.name,
    required this.mediaType,
    this.includeTags = const [],
    this.orTags = const [],
    this.excludeTags = const [],
    this.rating,
    this.order = 'id_desc',
    this.excludeFavorites = false,
    this.subfeeds = const [],
  });

  final String id;
  final String name;
  final String mediaType;
  final List<String> includeTags;
  final List<String> orTags;
  final List<String> excludeTags;
  final String? rating;
  final String order;
  final bool excludeFavorites;
  final List<SubFeed> subfeeds;

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
      includeTags: _parseStringList(include),
      orTags: _parseStringList(or),
      excludeTags: _parseStringList(exclude),
      rating: json['rating'] as String?,
      order: json['order'] as String? ?? 'id_desc',
      excludeFavorites: json['excludeFavorites'] as bool? ?? false,
      subfeeds: _parseSubfeeds(json['subfeeds']),
    );
  }

  static List<String> _parseStringList(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static List<SubFeed> _parseSubfeeds(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .map((e) => e is Map<String, dynamic> ? SubFeed.fromJson(e) : null)
        .whereType<SubFeed>()
        .toList();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'mediaType': mediaType,
        'includeTags': includeTags,
        'orTags': orTags,
        'excludeTags': excludeTags,
        if (rating != null) 'rating': rating,
        'order': order,
        'excludeFavorites': excludeFavorites,
        'subfeeds': subfeeds.map((s) => s.toJson()).toList(),
      };

  Feed copyWith({
    String? id,
    String? name,
    String? mediaType,
    List<String>? includeTags,
    List<String>? orTags,
    List<String>? excludeTags,
    String? rating,
    String? order,
    bool? excludeFavorites,
    List<SubFeed>? subfeeds,
  }) =>
      Feed(
        id: id ?? this.id,
        name: name ?? this.name,
        mediaType: mediaType ?? this.mediaType,
        includeTags: includeTags ?? this.includeTags,
        orTags: orTags ?? this.orTags,
        excludeTags: excludeTags ?? this.excludeTags,
        rating: rating ?? this.rating,
        order: order ?? this.order,
        excludeFavorites: excludeFavorites ?? this.excludeFavorites,
        subfeeds: subfeeds ?? this.subfeeds,
      );

  /// Build the search tag string for this feed (e621: space = AND, ~ = OR, - = exclude).
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
    parts.add(_mediaTypeClause());
    return parts.join(' ').trim();
  }

  String _mediaTypeClause() {
    return switch (mediaType) {
      mediaTypeVideo => '( ~type:mp4 ~type:webm )',
      mediaTypeAll => '( ~type:jpg ~type:png ~type:gif ~type:webp ~type:mp4 ~type:webm )',
      _ => '( ~type:jpg ~type:png ~type:gif ~type:webp )',
    };
  }

  /// Base query plus optional subfeed chain. Path [0] = first subfeed, [0,1] = first's second sub-subfeed, etc.
  ///
  /// Tags that appear as both include and exclude across the feed and subfeed chain
  /// are silently cancelled out so conflicting filters don't produce zero results.
  String toSearchQueryWithPath(List<int> path) {
    final includes = <String>{};
    final excludes = <String>{};

    for (final t in includeTags) {
      final s = t.trim();
      if (s.isNotEmpty) includes.add(s);
    }
    for (final t in excludeTags) {
      final s = t.trim();
      if (s.isNotEmpty) excludes.add(s);
    }

    List<SubFeed> level = subfeeds;
    for (final index in path) {
      if (index < 0 || index >= level.length) break;
      final sub = level[index];
      sub.collectTags(includes, excludes);
      level = sub.subfeeds;
    }

    final cancelledIncludes = includes.difference(excludes);
    final cancelledExcludes = excludes.difference(includes);

    final parts = <String>[];

    if (orTags.isNotEmpty) {
      final orClause = orTags.map((t) => '~${t.trim()}').where((s) => s.length > 1).join(' ');
      if (orClause.isNotEmpty) {
        parts.add('( $orClause )');
      }
    }

    if (cancelledIncludes.isNotEmpty) {
      parts.add(cancelledIncludes.join(' '));
    }
    for (final t in cancelledExcludes) {
      parts.add('-$t');
    }

    parts.add(_mediaTypeClause());

    return parts.join(' ').trim();
  }

  /// Single subfeed (no nesting). Kept for backward compatibility.
  String toSearchQueryWithSubfeed(SubFeed? subfeed) {
    if (subfeed == null) return toSearchQuery();
    final includes = <String>{};
    final excludes = <String>{};
    for (final t in includeTags) {
      final s = t.trim();
      if (s.isNotEmpty) includes.add(s);
    }
    for (final t in excludeTags) {
      final s = t.trim();
      if (s.isNotEmpty) excludes.add(s);
    }
    subfeed.collectTags(includes, excludes);
    final cancelledIncludes = includes.difference(excludes);
    final cancelledExcludes = excludes.difference(includes);
    final parts = <String>[];
    if (orTags.isNotEmpty) {
      final orClause = orTags.map((t) => '~${t.trim()}').where((s) => s.length > 1).join(' ');
      if (orClause.isNotEmpty) {
        parts.add('( $orClause )');
      }
    }
    if (cancelledIncludes.isNotEmpty) {
      parts.add(cancelledIncludes.join(' '));
    }
    for (final t in cancelledExcludes) {
      parts.add('-$t');
    }
    parts.add(_mediaTypeClause());
    return parts.join(' ').trim();
  }
}
