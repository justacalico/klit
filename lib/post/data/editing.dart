// SPDX-License-Identifier: AGPL-3.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kilt/post/post.dart';

part 'editing.freezed.dart';

@freezed
abstract class PostEdit with _$PostEdit {
  const factory PostEdit({
    required Post post,
    String? editReason,
    required Rating rating,
    required String description,
    int? parentId,
    required List<String> sources,
    required List<String> tags,
  }) = _PostEdit;

  const PostEdit._();

  factory PostEdit.fromPost(Post post) => PostEdit(
    post: post,
    rating: post.rating,
    description: post.description,
    parentId: post.relationships.parentId,
    sources: post.sources,
    tags: post.tags.values.expand((tagList) => tagList).toList(),
  );

  Map<String, String?>? toForm() {
    final body = <String, String?>{};

    final oldTags = post.tags.values
        .expand((category) => category)
        .toList();
    final newTags = tags;
    var removedTags = oldTags
        .where((element) => !newTags.contains(element))
        .toList();
    removedTags = removedTags.map((t) => '-$t').toList();
    final addedTags = newTags
        .where((element) => !oldTags.contains(element))
        .toList();
    final tagDiff = <String>[];
    tagDiff.addAll(removedTags);
    tagDiff.addAll(addedTags);

    if (tagDiff.isNotEmpty) {
      body.addEntries([MapEntry('post[tag_string_diff]', tagDiff.join(' '))]);
    }

    var removedSource = post.sources
        .where((element) => !sources.contains(element))
        .toList();
    removedSource = removedSource.map((s) => '-$s').toList();
    final addedSource = sources
        .where((element) => !post.sources.contains(element))
        .toList();
    final sourceDiff = <String>[];
    sourceDiff.addAll(removedSource);
    sourceDiff.addAll(addedSource);

    if (sourceDiff.isNotEmpty) {
      body.addEntries([MapEntry('post[source_diff]', sourceDiff.join('\n'))]);
    }

    if (post.relationships.parentId != parentId) {
      body.addEntries([MapEntry('post[parent_id]', parentId?.toString())]);
    }

    if (post.description != description) {
      body.addEntries([MapEntry('post[description]', description)]);
    }

    if (post.rating != rating) {
      body.addEntries([MapEntry('post[rating]', rating.name)]);
    }

    if (body.isNotEmpty) {
      if (editReason?.trim().isNotEmpty ?? false) {
        body.addEntries([MapEntry('post[edit_reason]', editReason!.trim())]);
      }
      return body;
    } else {
      return null;
    }
  }
}
