import 'package:deep_pick/deep_pick.dart';
import 'package:kilt/post/post.dart';
import 'package:kilt/shared/shared.dart';

String? _imageUrl(Pick pick) {
  return pick('webp').asStringOrNull() ?? pick('jpg').asStringOrNull();
}

abstract final class E621Post {
  static Post fromJson(dynamic json) => pick(json).letOrThrow(
    (post) => Post(
      id: post('id').asIntOrThrow(),
      file: post('files', 'original').letOrNull((original) => original('url').asStringOrNull()),
      sample: post('files', 'sample').letOrNull(_imageUrl),
      preview: post('files', 'preview').letOrNull(_imageUrl),
      width: post('files', 'original').letOrNull((original) => original('width').asIntOrNull()) ?? 0,
      height: post('files', 'original').letOrNull((original) => original('height').asIntOrNull()) ?? 0,
      ext: post('files', 'meta').letOrNull((meta) => meta('ext').asStringOrNull()) ?? '',
      size: post('files', 'meta').letOrNull((meta) => meta('size').asIntOrNull()) ?? 0,
      variants: post('files', 'video').letOrNull((video) {
        if (video('has').asBoolOrNull() != true) return null;
        final Map<String, String?> result = {};

        final origW = video('original', 'width').asIntOrNull();
        final origH = video('original', 'height').asIntOrNull();
        final origUrl = video('original', 'url').asStringOrNull();
        if (origW != null && origH != null && origUrl != null) {
          result['${origW}x${origH}'] = origUrl;
        }

        final mp4W = video('variants', 'mp4', 'width').asIntOrNull();
        final mp4H = video('variants', 'mp4', 'height').asIntOrNull();
        final mp4Url = video('variants', 'mp4', 'url').asStringOrNull();
        if (mp4W != null && mp4H != null && mp4Url != null) {
          result['${mp4W}x${mp4H}'] = mp4Url;
        }

        video('samples').asMapOrEmpty().forEach((_, value) {
          final w = pick(value, 'width').asIntOrNull();
          final h = pick(value, 'height').asIntOrNull();
          final url = pick(value, 'url').asStringOrNull();
          if (w != null && h != null && url != null) {
            result['${w}x${h}'] = url;
          }
        });

        return result.isEmpty ? null : result;
      }),
      tags: post('tags').letOrThrow(
        (tags) => tags.asMapOrThrow().map(
          (key, value) => MapEntry(
            key.toString(),
            pick(value).asListOrEmpty((tag) => tag.asStringOrThrow()),
          ),
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
        status: post('stats', 'vote').letOrNull((vote) => switch (vote.asIntOrNull()) {
          1 => VoteStatus.upvoted,
          -1 => VoteStatus.downvoted,
          _ => VoteStatus.unknown,
        }) ?? VoteStatus.unknown,
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
