// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'topic.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Topic _$TopicFromJson(Map<String, dynamic> json) => _Topic(
  id: (json['id'] as num).toInt(),
  creatorId: (json['creatorId'] as num).toInt(),
  creator: json['creator'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updaterId: (json['updaterId'] as num).toInt(),
  updater: json['updater'] as String,
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  title: json['title'] as String,
  responseCount: (json['responseCount'] as num).toInt(),
  sticky: json['sticky'] as bool,
  locked: json['locked'] as bool,
  hidden: json['hidden'] as bool,
  categoryId: (json['categoryId'] as num).toInt(),
);

Map<String, dynamic> _$TopicToJson(_Topic instance) => <String, dynamic>{
  'id': instance.id,
  'creatorId': instance.creatorId,
  'creator': instance.creator,
  'createdAt': instance.createdAt.toIso8601String(),
  'updaterId': instance.updaterId,
  'updater': instance.updater,
  'updatedAt': instance.updatedAt.toIso8601String(),
  'title': instance.title,
  'responseCount': instance.responseCount,
  'sticky': instance.sticky,
  'locked': instance.locked,
  'hidden': instance.hidden,
  'categoryId': instance.categoryId,
};
