// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_User _$UserFromJson(Map<String, dynamic> json) => _User(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  avatarId: (json['avatarId'] as num?)?.toInt(),
  about: json['about'] == null ? null : UserAbout.fromJson(json['about']),
  stats: json['stats'] == null ? null : UserStats.fromJson(json['stats']),
);

Map<String, dynamic> _$UserToJson(_User instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'avatarId': instance.avatarId,
  'about': instance.about,
  'stats': instance.stats,
};

_UserAbout _$UserAboutFromJson(Map<String, dynamic> json) => _UserAbout(
  bio: json['bio'] as String?,
  comission: json['comission'] as String?,
);

Map<String, dynamic> _$UserAboutToJson(_UserAbout instance) =>
    <String, dynamic>{'bio': instance.bio, 'comission': instance.comission};

_UserStats _$UserStatsFromJson(Map<String, dynamic> json) => _UserStats(
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  levelString: json['levelString'] as String?,
  favoriteCount: (json['favoriteCount'] as num?)?.toInt(),
  postUpdateCount: (json['postUpdateCount'] as num?)?.toInt(),
  postUploadCount: (json['postUploadCount'] as num?)?.toInt(),
  forumPostCount: (json['forumPostCount'] as num?)?.toInt(),
  commentCount: (json['commentCount'] as num?)?.toInt(),
);

Map<String, dynamic> _$UserStatsToJson(_UserStats instance) =>
    <String, dynamic>{
      'createdAt': instance.createdAt?.toIso8601String(),
      'levelString': instance.levelString,
      'favoriteCount': instance.favoriteCount,
      'postUpdateCount': instance.postUpdateCount,
      'postUploadCount': instance.postUploadCount,
      'forumPostCount': instance.forumPostCount,
      'commentCount': instance.commentCount,
    };
