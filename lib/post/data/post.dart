import 'package:kilt/shared/shared.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'post.freezed.dart';
part 'post.g.dart';

@freezed
abstract class Post with _$Post {
  const factory Post({
    required int id,
    required String? file,
    required String? sample,
    required String? preview,
    required int width,
    required int height,
    required String ext,
    required int size,
    required Map<String, String?>? variants,
    required Map<String, List<String>> tags,
    required int uploaderId,
    String? uploaderName,
    required DateTime createdAt,
    required DateTime? updatedAt,
    int? changeSeq,
    int? approverId,
    required VoteInfo vote,
    required bool isDeleted,
    required Rating rating,
    required int favCount,
    required bool isFavorited,
    required int commentCount,
    required String description,
    required List<String> sources,
    required List<int>? pools,
    List<String>? lockedTags,
    required Relationships relationships,
  }) = _Post;

  factory Post.fromJson(dynamic json) => _$PostFromJson(json);
}

enum Rating { s, q, e }

@freezed
abstract class Relationships with _$Relationships {
  const factory Relationships({
    required int? parentId,
    @Default(false) bool hasChildren,
    required bool? hasActiveChildren,
    required List<int> children,
  }) = _Relationships;

  factory Relationships.fromJson(dynamic json) => _$RelationshipsFromJson(json);
}
