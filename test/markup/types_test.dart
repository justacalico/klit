import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/markup/data/types.dart';

void main() {
  group('DTextId', () {
    test('contains returns true when span covers other', () {
      final outer = const DTextId(start: 0, end: 10);
      final inner = const DTextId(start: 2, end: 8);
      expect(outer.contains(inner), isTrue);
    });

    test('contains returns true for identical spans', () {
      final id = const DTextId(start: 5, end: 15);
      expect(id.contains(id), isTrue);
    });

    test('contains returns false when span does not cover other', () {
      final a = const DTextId(start: 0, end: 5);
      final b = const DTextId(start: 6, end: 10);
      expect(a.contains(b), isFalse);
    });

    test('contains returns false for partial overlap', () {
      final a = const DTextId(start: 0, end: 5);
      final b = const DTextId(start: 3, end: 10);
      expect(a.contains(b), isFalse);
    });

    test('isContainedBy is the inverse of contains', () {
      final outer = const DTextId(start: 0, end: 10);
      final inner = const DTextId(start: 2, end: 8);
      expect(inner.isContainedBy(outer), isTrue);
      expect(outer.isContainedBy(inner), isFalse);
    });

    test('equality compares start and end', () {
      final a = const DTextId(start: 1, end: 5);
      final b = const DTextId(start: 1, end: 5);
      final c = const DTextId(start: 1, end: 6);
      expect(a == b, isTrue);
      expect(a == c, isFalse);
    });

    test('hashCode is consistent with equality', () {
      final a = const DTextId(start: 1, end: 5);
      final b = const DTextId(start: 1, end: 5);
      expect(a.hashCode, b.hashCode);
    });

    test('toString contains start and end', () {
      final id = const DTextId(start: 3, end: 7);
      expect(id.toString(), contains('3'));
      expect(id.toString(), contains('7'));
    });
  });

  group('DTextContent', () {
    test('operator + concatenates content', () {
      final a = const DTextContent('hello ');
      final b = const DTextContent('world');
      final result = a + b;
      expect(result.content, 'hello world');
    });

    test('operator + with empty content', () {
      final a = const DTextContent('');
      final b = const DTextContent('text');
      expect((a + b).content, 'text');
    });

    test('operator + returns DTextContent', () {
      final a = const DTextContent('a');
      final b = const DTextContent('b');
      expect(a + b, isA<DTextContent>());
    });
  });

  group('LinkWord.toLink', () {
    test('post returns /posts/{id}', () {
      expect(LinkWord.post.toLink(42), '/posts/42');
    });

    test('thumb returns /posts/{id}', () {
      expect(LinkWord.thumb.toLink(99), '/posts/99');
    });

    test('pool returns /pools/{id}', () {
      expect(LinkWord.pool.toLink(7), '/pools/7');
    });

    test('user returns /users/{id}', () {
      expect(LinkWord.user.toLink(3), '/users/3');
    });

    test('forum returns /forum_posts/{id}', () {
      expect(LinkWord.forum.toLink(5), '/forum_posts/5');
    });

    test('topic returns /forum_topics/{id}', () {
      expect(LinkWord.topic.toLink(8), '/forum_topics/8');
    });

    test('comment returns /comments/{id}', () {
      expect(LinkWord.comment.toLink(12), '/comments/12');
    });

    test('set returns /post_sets/{id}', () {
      expect(LinkWord.set.toLink(15), '/post_sets/15');
    });

    test('record returns /user_feedbacks/{id}', () {
      expect(LinkWord.record.toLink(20), '/user_feedbacks/20');
    });

    test('blip returns /blips/{id}', () {
      expect(LinkWord.blip.toLink(25), '/blips/25');
    });

    test('ticket returns /tickets/{id}', () {
      expect(LinkWord.ticket.toLink(30), '/tickets/30');
    });

    test('takedown returns /takedowns/{id}', () {
      expect(LinkWord.takedown.toLink(35), '/takedowns/35');
    });
  });

  group('DTextElement types', () {
    test('DTextElements holds a list of elements', () {
      final elements = DTextElements([
        const DTextContent('a'),
        const DTextContent('b'),
      ]);
      expect(elements.elements.length, 2);
    });

    test('DTextBold holds children', () {
      const bold = DTextBold(DTextContent('text'));
      expect(bold.children, isA<DTextContent>());
    });

    test('DTextSpoiler holds id and children', () {
      const spoiler = DTextSpoiler(
        DTextId(start: 0, end: 10),
        DTextContent('hidden'),
      );
      expect(spoiler.id.start, 0);
      expect(spoiler.id.end, 10);
    });

    test('DTextSection holds title, expanded, and children', () {
      const section = DTextSection(
        null,
        'My Section',
        true,
        DTextContent('content'),
      );
      expect(section.title, 'My Section');
      expect(section.expanded, isTrue);
    });

    test('DTextLink holds optional name and link', () {
      const link = DTextLink(null, 'http://example.com');
      expect(link.name, isNull);
      expect(link.link, 'http://example.com');
    });

    test('DTextTagLink holds optional name and tag', () {
      const tagLink = DTextTagLink('display', 'tag_name');
      expect(tagLink.name, 'display');
      expect(tagLink.tag, 'tag_name');
    });

    test('DTextTagSearchLink holds tags', () {
      const searchLink = DTextTagSearchLink('some_tag');
      expect(searchLink.tags, 'some_tag');
    });

    test('DTextInlineCode holds content', () {
      const code = DTextInlineCode('print(1)');
      expect(code.content, 'print(1)');
    });

    test('DTextLinkWord holds type and id', () {
      const linkWord = DTextLinkWord(LinkWord.post, 100);
      expect(linkWord.type, LinkWord.post);
      expect(linkWord.id, 100);
    });
  });
}
