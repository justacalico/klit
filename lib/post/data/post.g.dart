// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Post _$PostFromJson(Map<String, dynamic> json) => _Post(
  id: (json['id'] as num).toInt(),
  file: json['file'] as String?,
  sample: json['sample'] as String?,
  preview: json['preview'] as String?,
  width: (json['width'] as num).toInt(),
  height: (json['height'] as num).toInt(),
  ext: json['ext'] as String,
  size: (json['size'] as num).toInt(),
  variants: (json['variants'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as String?),
  ),
  tags: (json['tags'] as Map<String, dynamic>).map(
    (k, e) =>
        MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
  ),
  uploaderId: (json['uploaderId'] as num).toInt(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  vote: VoteInfo.fromJson(json['vote'] as Map<String, dynamic>),
  isDeleted: json['isDeleted'] as bool,
  rating: $enumDecode(_$RatingEnumMap, json['rating']),
  favCount: (json['favCount'] as num).toInt(),
  isFavorited: json['isFavorited'] as bool,
  commentCount: (json['commentCount'] as num).toInt(),
  description: json['description'] as String,
  sources: (json['sources'] as List<dynamic>).map((e) => e as String).toList(),
  pools: (json['pools'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  relationships: Relationships.fromJson(json['relationships']),
);

Map<String, dynamic> _$PostToJson(_Post instance) => <String, dynamic>{
  'id': instance.id,
  'file': instance.file,
  'sample': instance.sample,
  'preview': instance.preview,
  'width': instance.width,
  'height': instance.height,
  'ext': instance.ext,
  'size': instance.size,
  'variants': instance.variants,
  'tags': instance.tags,
  'uploaderId': instance.uploaderId,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'vote': instance.vote,
  'isDeleted': instance.isDeleted,
  'rating': _$RatingEnumMap[instance.rating]!,
  'favCount': instance.favCount,
  'isFavorited': instance.isFavorited,
  'commentCount': instance.commentCount,
  'description': instance.description,
  'sources': instance.sources,
  'pools': instance.pools,
  'relationships': instance.relationships,
};

const _$RatingEnumMap = {Rating.s: 's', Rating.q: 'q', Rating.e: 'e'};

_Relationships _$RelationshipsFromJson(Map<String, dynamic> json) =>
    _Relationships(
      parentId: (json['parentId'] as num?)?.toInt(),
      hasChildren: json['hasChildren'] as bool,
      hasActiveChildren: json['hasActiveChildren'] as bool?,
      children: (json['children'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$RelationshipsToJson(_Relationships instance) =>
    <String, dynamic>{
      'parentId': instance.parentId,
      'hasChildren': instance.hasChildren,
      'hasActiveChildren': instance.hasActiveChildren,
      'children': instance.children,
    };
