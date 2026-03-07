// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Comment _$CommentFromJson(Map<String, dynamic> json) => _Comment(
  id: (json['id'] as num).toInt(),
  postId: (json['postId'] as num).toInt(),
  body: json['body'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  creatorId: (json['creatorId'] as num).toInt(),
  creatorName: json['creatorName'] as String,
  vote: json['vote'] == null
      ? null
      : VoteInfo.fromJson(json['vote'] as Map<String, dynamic>),
  warning: $enumDecodeNullable(_$WarningTypeEnumMap, json['warning']),
  hidden: json['hidden'] as bool,
);

Map<String, dynamic> _$CommentToJson(_Comment instance) => <String, dynamic>{
  'id': instance.id,
  'postId': instance.postId,
  'body': instance.body,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'creatorId': instance.creatorId,
  'creatorName': instance.creatorName,
  'vote': instance.vote,
  'warning': _$WarningTypeEnumMap[instance.warning],
  'hidden': instance.hidden,
};

const _$WarningTypeEnumMap = {
  WarningType.warning: 'warning',
  WarningType.record: 'record',
  WarningType.ban: 'ban',
};
