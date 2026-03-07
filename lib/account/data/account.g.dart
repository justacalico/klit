// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Account _$AccountFromJson(Map<String, dynamic> json) => _Account(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  avatarId: (json['avatarId'] as num?)?.toInt(),
  blacklistedTags: json['blacklistedTags'] as String?,
  perPage: (json['perPage'] as num?)?.toInt(),
);

Map<String, dynamic> _$AccountToJson(_Account instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'avatarId': instance.avatarId,
  'blacklistedTags': instance.blacklistedTags,
  'perPage': instance.perPage,
};
