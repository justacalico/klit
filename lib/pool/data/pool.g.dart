// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pool.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Pool _$PoolFromJson(Map<String, dynamic> json) => _Pool(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  description: json['description'] as String,
  postIds: (json['postIds'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
  postCount: (json['postCount'] as num).toInt(),
  active: json['active'] as bool,
);

Map<String, dynamic> _$PoolToJson(_Pool instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'description': instance.description,
  'postIds': instance.postIds,
  'postCount': instance.postCount,
  'active': instance.active,
};
