// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flag.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PostFlag _$PostFlagFromJson(Map<String, dynamic> json) => _PostFlag(
  id: (json['id'] as num).toInt(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  postId: (json['postId'] as num).toInt(),
  reason: json['reason'] as String,
  creatorId: (json['creatorId'] as num).toInt(),
  isResolved: json['isResolved'] as bool,
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  isDeletion: json['isDeletion'] as bool,
  type: $enumDecode(_$PostFlagTypeEnumMap, json['type']),
);

Map<String, dynamic> _$PostFlagToJson(_PostFlag instance) => <String, dynamic>{
  'id': instance.id,
  'createdAt': instance.createdAt.toIso8601String(),
  'postId': instance.postId,
  'reason': instance.reason,
  'creatorId': instance.creatorId,
  'isResolved': instance.isResolved,
  'updatedAt': instance.updatedAt.toIso8601String(),
  'isDeletion': instance.isDeletion,
  'type': _$PostFlagTypeEnumMap[instance.type]!,
};

const _$PostFlagTypeEnumMap = {
  PostFlagType.flag: 'flag',
  PostFlagType.deletion: 'deletion',
};
