// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reply.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Reply _$ReplyFromJson(Map<String, dynamic> json) => _Reply(
  id: (json['id'] as num).toInt(),
  creatorId: (json['creatorId'] as num).toInt(),
  creator: json['creator'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updaterId: (json['updaterId'] as num?)?.toInt(),
  updater: json['updater'] as String?,
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  body: json['body'] as String,
  topicId: (json['topicId'] as num).toInt(),
  warning: $enumDecodeNullable(_$WarningTypeEnumMap, json['warning']),
  hidden: json['hidden'] as bool,
);

Map<String, dynamic> _$ReplyToJson(_Reply instance) => <String, dynamic>{
  'id': instance.id,
  'creatorId': instance.creatorId,
  'creator': instance.creator,
  'createdAt': instance.createdAt.toIso8601String(),
  'updaterId': instance.updaterId,
  'updater': instance.updater,
  'updatedAt': instance.updatedAt.toIso8601String(),
  'body': instance.body,
  'topicId': instance.topicId,
  'warning': _$WarningTypeEnumMap[instance.warning],
  'hidden': instance.hidden,
};

const _$WarningTypeEnumMap = {
  WarningType.warning: 'warning',
  WarningType.record: 'record',
  WarningType.ban: 'ban',
};
