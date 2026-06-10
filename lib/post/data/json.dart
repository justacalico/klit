import 'package:deep_pick/deep_pick.dart';
import 'package:kilt/post/post.dart';
import 'package:kilt/shared/shared.dart';

abstract final class E621Post {
  static Post fromJson(dynamic json) => pick(json).letOrThrow(
    (post) => Post(
      id: post('id').asIntOrThrow(),
      file: post('files', 'original').letOrNull((original) => original('url').asStringOrNull()),
      sample: post('files', 'sample').letOrNull((sample) => sample('url').asStringOrNull()),
      preview: post('files', 'preview').letOrNull((preview) => preview('url').asStringOrNull()),
      width: post('files', 'original').letOrNull((original) => original('width').asIntOrNull()) ?? 0,
      height: post('files', 'original').letOrNull((original) => original('height').asIntOrNull()) ?? 0,
      ext: post('files', 'meta').letOrNull((meta) => meta('ext').asStringOrNull()) ?? '',
      size: post('files', 'meta').letOrNull((meta) => meta('size').asIntOrNull()) ?? 0,
      variants: post('sample', 'alternates').letOrNull((alternates) {
        if (alternates.asMapOrNull()?.isEmpty ?? true) return null;
        return {
          '${alternates('original', 'width').asIntOrThrow()}x${alternates('original', 'height').asIntOrThrow()}':
              alternates('original', 'url').asStringOrNull(),
          ...alternates(
            'samples',
          ).asMapOrEmpty().values.fold<Map<String, String?>>({}, (acc, e) {
            final w = pick(e, 'width').asIntOrNull();
            final h = pick(e, 'height').asIntOrNull();
            final url = pick(e, 'url').asStringOrNull();
            if (w != null && h != null && url != null) {
              acc['${w}x$h'] = url;
            }
            return acc;
          }),
        };
      }),
      tags: post('tags').letOrThrow(
        (pick) => pick.asListOrEmpty((tag) => tag.asStringOrThrow()).fold<Map<String, List<String>>>(
          {},
          (acc, tag) {
            acc['general'] = [...(acc['general'] ?? []), tag];
            return acc;
          },
        ),
      ),
      uploaderId: post('uploader_id').asIntOrThrow(),
      uploaderName: post('uploader_name').asStringOrNull(),
      approverId: post('approver_id').asIntOrNull(),
      createdAt: post('created_at').asDateTimeOrThrow(),
      updatedAt: post('updated_at').asDateTimeOrNull(),
      changeSeq: post('change_seq').asIntOrNull(),
      vote: VoteInfo(
        score: post('stats', 'score').letOrNull((score) => score('total').asIntOrNull()) ?? 0,
      ),
      isDeleted: post('flags').letOrNull((flags) => flags('deleted').asBoolOrNull()) ?? false,
      rating: post('rating').letOrNull((pick) => Rating.values.asNameMap()[pick.asString()]) ?? Rating.s,
      favCount: post('stats').letOrNull((stats) => stats('fav_count').asIntOrNull()) ?? 0,
      isFavorited: post('stats').letOrNull((stats) => stats('is_favorited').asBoolOrNull()) ?? false,
      commentCount: post('stats').letOrNull((stats) => stats('comment_count').asIntOrNull()) ?? 0,
      description: post('description').asStringOrThrow(),
      sources: post('sources').asListOrThrow((pick) => pick.asStringOrThrow()),
      lockedTags: post('locked_tags').asListOrNull((pick) => pick.asStringOrThrow()),
      pools: post('pools').asListOrThrow((pick) => pick.asIntOrThrow()),
      relationships: post('relationships').letOrThrow(
        (relationships) => Relationships(
          parentId: relationships('parent_id').asIntOrNull(),
          hasChildren: post('has').letOrNull((has) => has('children').asBoolOrNull()) ?? false,
          hasActiveChildren: post('has').letOrNull((has) => has('active_children').asBoolOrNull()),
          children: relationships('children').asListOrEmpty((pick) => pick.asIntOrThrow()),
        ),
      ),
    ),
  );
}
