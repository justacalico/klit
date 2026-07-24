import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/tag/tag.dart';
import 'package:petitparser/petitparser.dart';

void main() {
 late Parser<List<TagNode>> parser;

  setUp(() {
    parser = TagMapParserDefinition().build();
  });

  List<TagNode> parse(String input) {
    final result = parser.parse(input);
    expect(result is Success, isTrue, reason: result is Failure ? result.message : '');
    return result.value;
  }

  group('simple tags', () {
    test('parses a single tag', () {
      final nodes = parse('tag1');
      expect(nodes.length, 1);
      expect(nodes[0], TagValue('tag1'));
    });

    test('parses multiple tags', () {
      final nodes = parse('tag1 tag2');
      expect(nodes.length, 2);
      expect(nodes[0], TagValue('tag1'));
      expect(nodes[1], TagValue('tag2'));
    });
  });

  group('namespaced tags', () {
    test('parses key:value', () {
      final nodes = parse('key:value');
      expect(nodes.length, 1);
      expect(nodes[0], TagValue('key', 'value'));
    });

    test('parses mixed simple and namespaced', () {
      final nodes = parse('tag key:value');
      expect(nodes[0], TagValue('tag'));
      expect(nodes[1], TagValue('key', 'value'));
    });
  });

  group('groups', () {
    test('parses a group with children', () {
      final nodes = parse('( a b )');
      expect(nodes.length, 1);
      final group = nodes[0] as TagGroup;
      expect(group.prefix, '');
      expect(group.children, [TagValue('a'), TagValue('b')]);
    });

    test('parses a prefixed group with dash', () {
      final nodes = parse('-( a b )');
      final group = nodes[0] as TagGroup;
      expect(group.prefix, '-');
      expect(group.children, [TagValue('a'), TagValue('b')]);
    });

    test('parses a prefixed group with tilde', () {
      final nodes = parse('~( a b )');
      final group = nodes[0] as TagGroup;
      expect(group.prefix, '~');
    });
  });

  group('comments', () {
    test('parses a comment', () {
      final nodes = parse('#comment');
      expect(nodes.length, 1);
      expect(nodes[0], TagComment('comment'));
    });

    test('parses a comment with spaces', () {
      final nodes = parse('#this is a comment');
      expect(nodes[0], TagComment('this is a comment'));
    });
  });

  group('quoted values', () {
    test('parses a quoted value with spaces', () {
      final nodes = parse('key:"value with spaces"');
      expect(nodes[0], TagValue('key', 'value with spaces'));
    });

    test('parses escaped quotes inside value', () {
      final nodes = parse(r'key:"value with \"quotes\""');
      expect(nodes[0], TagValue('key', 'value with "quotes"'));
    });
  });

  group('mixed input', () {
    test('parses tags, group, namespaced, and comment together', () {
      final nodes = parse('tag1 ( group1 group2 ) key:value #comment');
      expect(nodes.length, 4);
      expect(nodes[0], TagValue('tag1'));
      expect(nodes[1], isA<TagGroup>());
      expect(nodes[2], TagValue('key', 'value'));
      expect(nodes[3], TagComment('comment'));
    });
  });

  group('edge cases', () {
    test('empty string parses to empty list', () {
      final nodes = parse('');
      expect(nodes, isEmpty);
    });

    test('whitespace only parses to empty list', () {
      final nodes = parse('   ');
      expect(nodes, isEmpty);
    });
  });
}
