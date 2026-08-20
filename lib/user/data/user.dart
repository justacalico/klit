// SPDX-License-Identifier: AGPL-3.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
abstract class User with _$User {
  const factory User({
    required int id,
    required String name,
    required int? avatarId,
    required UserAbout? about,
    required UserStats? stats,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

@freezed
abstract class UserAbout with _$UserAbout {
  const factory UserAbout({required String? bio, required String? comission}) =
      _UserAbout;

  factory UserAbout.fromJson(Map<String, dynamic> json) => _$UserAboutFromJson(json);
}

@freezed
abstract class UserStats with _$UserStats {
  const factory UserStats({
    required DateTime? createdAt,
    required String? levelString,
    required int? favoriteCount,
    required int? postUpdateCount,
    required int? postUploadCount,
    required int? forumPostCount,
    required int? commentCount,
  }) = _UserStats;

  factory UserStats.fromJson(Map<String, dynamic> json) => _$UserStatsFromJson(json);
}
