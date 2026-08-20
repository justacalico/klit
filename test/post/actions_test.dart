import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/post/post.dart';
import 'package:kilt/shared/shared.dart';

import '../helpers/test_posts.dart';

void main() {
  group('PostTagging.hasTag', () {
    test('matches a regular tag that exists', () {
      final post = makePost();
      expect(post.hasTag('fox'), isTrue);
    });

    test('does not match a regular tag that is absent', () {
      final post = makePost();
      expect(post.hasTag('cat'), isFalse);
    });

    test('is case insensitive', () {
      final post = makePost();
      expect(post.hasTag('FOX'), isTrue);
      expect(post.hasTag('CaNiNe'), isTrue);
    });

    test('returns false for an empty tag', () {
      final post = makePost();
      expect(post.hasTag(''), isFalse);
      expect(post.hasTag('   '), isFalse);
    });

    group('meta tags', () {
      test('id matches the post id', () {
        final post = makePost(id: 42);
        expect(post.hasTag('id:42'), isTrue);
      });

      test('id does not match a different id', () {
        final post = makePost();
        expect(post.hasTag('id:99'), isFalse);
      });

      test('rating matches by short name', () {
        expect(makePost().hasTag('rating:s'), isTrue);
        expect(makePost(rating: Rating.q).hasTag('rating:q'), isTrue);
        expect(makePost(rating: Rating.e).hasTag('rating:e'), isTrue);
      });

      test('rating matches by title name', () {
        expect(makePost().hasTag('rating:safe'), isTrue);
        expect(
          makePost(rating: Rating.q).hasTag('rating:questionable'),
          isTrue,
        );
        expect(makePost(rating: Rating.e).hasTag('rating:explicit'), isTrue);
      });

      test('rating does not match a different rating', () {
        expect(makePost().hasTag('rating:e'), isFalse);
      });

      test('type matches the file extension', () {
        final post = makePost();
        expect(post.hasTag('type:jpg'), isTrue);
      });

      test('type is case insensitive', () {
        final post = makePost();
        expect(post.hasTag('type:JPG'), isTrue);
      });

      test('type does not match a different extension', () {
        final post = makePost();
        expect(post.hasTag('type:png'), isFalse);
      });

      test('width matches an exact value', () {
        final post = makePost();
        expect(post.hasTag('width:1000'), isTrue);
      });

      test('width matches a less-than range', () {
        final post = makePost();
        expect(post.hasTag('width:<2000'), isTrue);
        expect(post.hasTag('width:<500'), isFalse);
      });

      test('width matches a greater-than range', () {
        final post = makePost();
        expect(post.hasTag('width:>500'), isTrue);
        expect(post.hasTag('width:>2000'), isFalse);
      });

      test('width matches a bounded range', () {
        final post = makePost();
        expect(post.hasTag('width:500..2000'), isTrue);
        expect(post.hasTag('width:100..500'), isFalse);
      });

      test('height matches an exact value', () {
        final post = makePost();
        expect(post.hasTag('height:800'), isTrue);
      });

      test('filesize matches an exact value', () {
        final post = makePost();
        expect(post.hasTag('filesize:500000'), isTrue);
      });

      test('score matches an exact value', () {
        final post = makePost(vote: const VoteInfo(score: 50));
        expect(post.hasTag('score:50'), isTrue);
      });

      test('favcount matches an exact value', () {
        final post = makePost();
        expect(post.hasTag('favcount:10'), isTrue);
      });

      test('fav matches when the post is favorited', () {
        expect(makePost(isFavorited: true).hasTag('fav:'), isTrue);
        expect(makePost().hasTag('fav:'), isFalse);
      });

      test('uploader matches the uploader id', () {
        final post = makePost();
        expect(post.hasTag('uploader:100'), isTrue);
      });

      test('userid matches the uploader id', () {
        final post = makePost();
        expect(post.hasTag('userid:100'), isTrue);
      });

      test('pool matches when the post belongs to the pool', () {
        final post = makePost(pools: [1, 2]);
        expect(post.hasTag('pool:1'), isTrue);
        expect(post.hasTag('pool:2'), isTrue);
      });

      test('pool does not match when the post has no pools', () {
        final post = makePost();
        expect(post.hasTag('pool:1'), isFalse);
      });

      test('pool does not match a missing pool', () {
        final post = makePost(pools: [1]);
        expect(post.hasTag('pool:99'), isFalse);
      });

      test('tagcount matches the total number of tags', () {
        final post = makePost();
        expect(post.hasTag('tagcount:3'), isTrue);
        expect(post.hasTag('tagcount:2'), isFalse);
      });
    });

    test('does not handle inverted meta tags', () {
      final post = makePost();
      expect(post.hasTag('-fox'), isFalse);
    });
  });

  group('PostDenying.getDeniers', () {
    test('empty denylist yields nothing', () {
      final post = makePost();
      expect(post.getDeniers([]), isEmpty);
    });

    test('simple tag match yields the line', () {
      final post = makePost();
      expect(post.getDeniers(['fox']), ['fox']);
    });

    test('no match yields nothing', () {
      final post = makePost();
      expect(post.getDeniers(['cat']), isEmpty);
    });

    test('strips trailing comments', () {
      final post = makePost();
      expect(post.getDeniers(['fox #this is a comment']), ['fox']);
    });

    test('pure comment yields nothing', () {
      final post = makePost();
      expect(post.getDeniers(['#just a comment']), isEmpty);
    });

    test('optional tags match when any one matches', () {
      final post = makePost();
      expect(post.getDeniers(['~fox ~cat']), ['~fox ~cat']);
    });

    test('optional tags yield nothing when none match', () {
      final post = makePost();
      expect(post.getDeniers(['~cat ~bird']), isEmpty);
    });

    test('inverted tag matches when the post does not have the tag', () {
      final post = makePost();
      expect(post.getDeniers(['-cat']), ['-cat']);
    });

    test('inverted tag does not match when the post has the tag', () {
      final post = makePost();
      expect(post.getDeniers(['-fox']), isEmpty);
    });

    test('mixed required and inverted tags match', () {
      final post = makePost();
      expect(post.getDeniers(['fox -cat']), ['fox -cat']);
    });

    test('mixed tags fail when required tag is missing', () {
      final post = makePost();
      expect(post.getDeniers(['cat -fox']), isEmpty);
    });

    test('multiple denylist lines yield only matching lines', () {
      final post = makePost();
      expect(post.getDeniers(['fox', 'cat']), ['fox']);
    });
  });

  group('PostDenying.isDeniedBy', () {
    test('returns true when there are deniers', () {
      final post = makePost();
      expect(post.isDeniedBy(['fox']), isTrue);
    });

    test('returns false when there are no deniers', () {
      final post = makePost();
      expect(post.isDeniedBy(['cat']), isFalse);
    });

    test('returns false for an empty denylist', () {
      final post = makePost();
      expect(post.isDeniedBy([]), isFalse);
    });
  });

  group('PostLinking', () {
    test('getPostLink returns the post route', () {
      expect(PostLinking.getPostLink(5), '/posts/5');
      expect(PostLinking.getPostLink(0), '/posts/0');
    });

    test('link returns the route for the post id', () {
      final post = makePost(id: 42);
      expect(post.link, '/posts/42');
    });
  });
}
