// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wiki.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Wiki _$WikiFromJson(Map<String, dynamic> json) => _Wiki(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  body: json['body'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  otherNames: (json['otherNames'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  isLocked: json['isLocked'] as bool?,
);

Map<String, dynamic> _$WikiToJson(_Wiki instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'body': instance.body,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'otherNames': instance.otherNames,
  'isLocked': instance.isLocked,
};
