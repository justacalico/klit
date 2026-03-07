// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'traits.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Traits _$TraitsFromJson(Map<String, dynamic> json) => _Traits(
  id: (json['id'] as num).toInt(),
  userId: (json['userId'] as num?)?.toInt(),
  denylist: (json['denylist'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  homeTags: json['homeTags'] as String,
  avatar: json['avatar'] as String?,
  perPage: (json['perPage'] as num?)?.toInt(),
  writeHistory: json['writeHistory'] as bool?,
  trimHistory: json['trimHistory'] as bool?,
);

Map<String, dynamic> _$TraitsToJson(_Traits instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'denylist': instance.denylist,
  'homeTags': instance.homeTags,
  'avatar': instance.avatar,
  'perPage': instance.perPage,
  'writeHistory': instance.writeHistory,
  'trimHistory': instance.trimHistory,
};

_TraitsRequest _$TraitsRequestFromJson(Map<String, dynamic> json) =>
    _TraitsRequest(
      identity: (json['identity'] as num).toInt(),
      userId: (json['userId'] as num?)?.toInt(),
      denylist:
          (json['denylist'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      homeTags: json['homeTags'] as String? ?? '',
      avatar: json['avatar'] as String?,
      perPage: (json['perPage'] as num?)?.toInt(),
      writeHistory: json['writeHistory'] as bool?,
      trimHistory: json['trimHistory'] as bool?,
    );

Map<String, dynamic> _$TraitsRequestToJson(_TraitsRequest instance) =>
    <String, dynamic>{
      'identity': instance.identity,
      'userId': instance.userId,
      'denylist': instance.denylist,
      'homeTags': instance.homeTags,
      'avatar': instance.avatar,
      'perPage': instance.perPage,
      'writeHistory': instance.writeHistory,
      'trimHistory': instance.trimHistory,
    };
