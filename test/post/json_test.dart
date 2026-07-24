import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/post/post.dart';
import 'package:kilt/shared/shared.dart';

void main() {
  group('E621Post.fromJson', () {
    test('parses a complete post with all fields', () {
      final json = <String, dynamic>{
        'id': 12345,
        'files': {
          'original': {
            'url': 'https://example.com/image.jpg',
            'width': 1920,
            'height': 1080,
          },
          'sample': {
            'webp': 'https://example.com/sample.webp',
            'jpg': 'https://example.com/sample.jpg',
          },
          'preview': {
            'webp': 'https://example.com/preview.webp',
          },
          'meta': {
            'ext': 'jpg',
            'size': 500000,
          },
        },
        'tags': {
          'general': ['fox', 'canine'],
          'species': ['dog'],
          'artist': ['test_artist'],
        },
        'uploader_id': 100,
        'uploader_name': 'testuser',
        'approver_id': 200,
        'created_at': '2024-01-15T12:00:00.000Z',
        'updated_at': '2024-02-20T08:30:00.000Z',
        'change_seq': 999,
        'stats': {
          'score': {'total': 50},
          'vote': 1,
          'fav_count': 10,
          'is_favorited': true,
          'comment_count': 5,
        },
        'flags': {'deleted': false},
        'rating': 's',
        'description': 'A test post description',
        'sources': ['https://example.com/source1', 'https://example.com/source2'],
        'locked_tags': ['tag1'],
        'pools': [1, 2],
        'has': {'children': true, 'active_children': true},
        'relationships': {
          'parent_id': 42,
          'children': [100, 200],
        },
      };

      final post = E621Post.fromJson(json);

      expect(post.id, 12345);
      expect(post.file, 'https://example.com/image.jpg');
      expect(post.sample, 'https://example.com/sample.webp');
      expect(post.preview, 'https://example.com/preview.webp');
      expect(post.width, 1920);
      expect(post.height, 1080);
      expect(post.ext, 'jpg');
      expect(post.size, 500000);
      expect(post.variants, isNull);
      expect(post.tags['general'], ['fox', 'canine']);
      expect(post.tags['species'], ['dog']);
      expect(post.tags['artist'], ['test_artist']);
      expect(post.uploaderId, 100);
      expect(post.uploaderName, 'testuser');
      expect(post.approverId, 200);
      expect(post.createdAt, DateTime.utc(2024, 1, 15, 12, 0, 0));
      expect(post.updatedAt, DateTime.utc(2024, 2, 20, 8, 30, 0));
      expect(post.changeSeq, 999);
      expect(post.vote.score, 50);
      expect(post.vote.status, VoteStatus.upvoted);
      expect(post.isDeleted, isFalse);
      expect(post.rating, Rating.s);
      expect(post.favCount, 10);
      expect(post.isFavorited, isTrue);
      expect(post.commentCount, 5);
      expect(post.description, 'A test post description');
      expect(post.sources, ['https://example.com/source1', 'https://example.com/source2']);
      expect(post.lockedTags, ['tag1']);
      expect(post.pools, [1, 2]);
      expect(post.relationships.parentId, 42);
      expect(post.relationships.hasChildren, isTrue);
      expect(post.relationships.hasActiveChildren, isTrue);
      expect(post.relationships.children, [100, 200]);
    });

    test('parses a post with missing optional fields', () {
      final json = <String, dynamic>{
        'id': 1,
        'tags': {},
        'uploader_id': 100,
        'created_at': '2024-01-15T12:00:00.000Z',
        'description': '',
        'sources': [],
        'pools': [],
        'relationships': {},
      };

      final post = E621Post.fromJson(json);

      expect(post.id, 1);
      expect(post.file, isNull);
      expect(post.sample, isNull);
      expect(post.preview, isNull);
      expect(post.width, 0);
      expect(post.height, 0);
      expect(post.ext, '');
      expect(post.size, 0);
      expect(post.variants, isNull);
      expect(post.tags, isEmpty);
      expect(post.uploaderId, 100);
      expect(post.uploaderName, isNull);
      expect(post.approverId, isNull);
      expect(post.createdAt, DateTime.utc(2024, 1, 15, 12, 0, 0));
      expect(post.updatedAt, isNull);
      expect(post.changeSeq, isNull);
      expect(post.vote.score, 0);
      expect(post.vote.status, VoteStatus.unknown);
      expect(post.isDeleted, isFalse);
      expect(post.rating, Rating.s);
      expect(post.favCount, 0);
      expect(post.isFavorited, isFalse);
      expect(post.commentCount, 0);
      expect(post.description, '');
      expect(post.sources, isEmpty);
      expect(post.lockedTags, isNull);
      expect(post.pools, isEmpty);
      expect(post.relationships.parentId, isNull);
      expect(post.relationships.hasChildren, isFalse);
      expect(post.relationships.hasActiveChildren, isNull);
      expect(post.relationships.children, isEmpty);
    });

    test('parses a post with video variants', () {
      final json = <String, dynamic>{
        'id': 2,
        'files': {
          'original': {
            'url': 'https://example.com/video.mp4',
            'width': 1920,
            'height': 1080,
          },
          'meta': {
            'ext': 'mp4',
            'size': 1000000,
          },
          'video': {
            'has': true,
            'original': {
              'width': 1920,
              'height': 1080,
              'url': 'https://example.com/video_original.mp4',
            },
            'variants': {
              'mp4': {
                'width': 1280,
                'height': 720,
                'url': 'https://example.com/video_720p.mp4',
              },
            },
            'samples': {
              '480p': {
                'width': 854,
                'height': 480,
                'url': 'https://example.com/video_480p.mp4',
              },
            },
          },
        },
        'tags': {},
        'uploader_id': 100,
        'created_at': '2024-01-15T12:00:00.000Z',
        'description': '',
        'sources': [],
        'pools': [],
        'relationships': {},
      };

      final post = E621Post.fromJson(json);

      expect(post.id, 2);
      expect(post.file, 'https://example.com/video.mp4');
      expect(post.width, 1920);
      expect(post.height, 1080);
      expect(post.ext, 'mp4');
      expect(post.size, 1000000);
      expect(post.variants, isNotNull);
      expect(post.variants!['1920x1080'], 'https://example.com/video_original.mp4');
      expect(post.variants!['1280x720'], 'https://example.com/video_720p.mp4');
      expect(post.variants!['854x480'], 'https://example.com/video_480p.mp4');
    });

    test('parses a post where video has=false yields null variants', () {
      final json = <String, dynamic>{
        'id': 3,
        'files': {
          'video': {'has': false},
        },
        'tags': {},
        'uploader_id': 100,
        'created_at': '2024-01-15T12:00:00.000Z',
        'description': '',
        'sources': [],
        'pools': [],
        'relationships': {},
      };

      final post = E621Post.fromJson(json);
      expect(post.variants, isNull);
    });

    test('parses a post with empty tags map', () {
      final json = <String, dynamic>{
        'id': 4,
        'tags': {},
        'uploader_id': 100,
        'created_at': '2024-01-15T12:00:00.000Z',
        'description': '',
        'sources': [],
        'pools': [],
        'relationships': {},
      };

      final post = E621Post.fromJson(json);
      expect(post.tags, isEmpty);
    });

    test('parses vote status as downvoted when vote is -1', () {
      final json = <String, dynamic>{
        'id': 5,
        'tags': {},
        'uploader_id': 100,
        'created_at': '2024-01-15T12:00:00.000Z',
        'description': '',
        'sources': [],
        'pools': [],
        'relationships': {},
        'stats': {'vote': -1},
      };

      final post = E621Post.fromJson(json);
      expect(post.vote.status, VoteStatus.downvoted);
    });

    test('parses rating from string', () {
      final base = <String, dynamic>{
        'id': 6,
        'tags': {},
        'uploader_id': 100,
        'created_at': '2024-01-15T12:00:00.000Z',
        'description': '',
        'sources': [],
        'pools': [],
        'relationships': {},
      };

      expect(E621Post.fromJson({...base, 'rating': 'q'}).rating, Rating.q);
      expect(E621Post.fromJson({...base, 'rating': 'e'}).rating, Rating.e);
      expect(E621Post.fromJson({...base, 'rating': 's'}).rating, Rating.s);
    });

    test('defaults to Rating.s when rating is missing', () {
      final json = <String, dynamic>{
        'id': 7,
        'tags': {},
        'uploader_id': 100,
        'created_at': '2024-01-15T12:00:00.000Z',
        'description': '',
        'sources': [],
        'pools': [],
        'relationships': {},
      };

      final post = E621Post.fromJson(json);
      expect(post.rating, Rating.s);
    });

    test('parses isDeleted from flags', () {
      final base = <String, dynamic>{
        'id': 8,
        'tags': {},
        'uploader_id': 100,
        'created_at': '2024-01-15T12:00:00.000Z',
        'description': '',
        'sources': [],
        'pools': [],
        'relationships': {},
      };

      expect(
        E621Post.fromJson({...base, 'flags': {'deleted': true}}).isDeleted,
        isTrue,
      );
      expect(
        E621Post.fromJson({...base, 'flags': {'deleted': false}}).isDeleted,
        isFalse,
      );
    });
  });
}
