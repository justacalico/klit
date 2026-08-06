import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/markup/data/grammar.dart';
import 'package:kilt/markup/data/types.dart';
import 'package:petitparser/petitparser.dart';

DTextElement parse(String input) {
  final result = DTextGrammar().build().parse(input);
  if (result is Failure) {
    fail('Failed to parse "$input": ${result.message}');
  }
  return result.value;
}

void main() {
  group('DTextGrammar', () {
    test('parses plain text', () {
      final ast = parse('hello world');
      expect(ast, isA<DTextContent>());
      expect((ast as DTextContent).content, 'hello world');
    });

    test('parses empty string', () {
      final ast = parse('');
      expect(ast, isA<DTextElement>());
    });

    test('parses bold', () {
      final ast = parse('[b]bold text[/b]');
      expect(ast, isA<DTextBold>());
      final bold = ast as DTextBold;
      expect(bold.children, isA<DTextContent>());
      expect((bold.children as DTextContent).content, 'bold text');
    });

    test('parses italic', () {
      final ast = parse('[i]italic[/i]');
      expect(ast, isA<DTextItalic>());
      final italic = ast as DTextItalic;
      expect((italic.children as DTextContent).content, 'italic');
    });

    test('parses code block', () {
      final ast = parse('[code]code block[/code]');
      expect(ast, isA<DTextCode>());
      final code = ast as DTextCode;
      expect((code.children as DTextContent).content, 'code block');
    });

    test('parses quote', () {
      final ast = parse('[quote]quoted[/quote]');
      expect(ast, isA<DTextQuote>());
      final quote = ast as DTextQuote;
      expect((quote.children as DTextContent).content, 'quoted');
    });

    test('parses section', () {
      final ast = parse('[section]title');
      expect(ast, isA<DTextSection>());
      final section = ast as DTextSection;
      expect(section.title, '');
      expect(section.expanded, isFalse);
    });

    test('parses expanded section', () {
      final ast = parse('[section,expanded]title[/section]');
      expect(ast, isA<DTextSection>());
      final section = ast as DTextSection;
      expect(section.expanded, isTrue);
    });

    test('parses spoiler', () {
      final ast = parse('[spoiler]hidden[/spoiler]');
      expect(ast, isA<DTextSpoiler>());
      final spoiler = ast as DTextSpoiler;
      expect(spoiler.id, isNotNull);
      expect((spoiler.children as DTextContent).content, 'hidden');
    });

    test('parses inline code', () {
      final ast = parse('some `code` text');
      expect(ast, isA<DTextElements>());
      final elements = (ast as DTextElements).elements;
      final inlineCode = elements.whereType<DTextInlineCode>().single;
      expect(inlineCode.content, 'code');
    });

    test('parses local link', () {
      final ast = parse('"link":/posts/123');
      expect(ast, isA<DTextLocalLink>());
      final link = ast as DTextLocalLink;
      expect(link.link, '/posts/123');
      expect(link.name, isA<DTextContent>());
      expect((link.name as DTextContent).content, 'link');
    });

    test('parses external link', () {
      final ast = parse('"example":http://example.com');
      expect(ast, isA<DTextLink>());
      final link = ast as DTextLink;
      expect(link.link, 'http://example.com');
    });

    test('parses bare external link', () {
      final ast = parse('http://example.com');
      expect(ast, isA<DTextLink>());
      final link = ast as DTextLink;
      expect(link.link, 'http://example.com');
      expect(link.name, isNull);
    });

    test('parses tag link', () {
      final ast = parse('[[tag_name]]');
      expect(ast, isA<DTextTagLink>());
      final tagLink = ast as DTextTagLink;
      expect(tagLink.tag, 'tag_name');
      expect(tagLink.name, isNull);
    });

    test('parses tag link with display name', () {
      final ast = parse('[[tag_name|display]]');
      expect(ast, isA<DTextTagLink>());
      final tagLink = ast as DTextTagLink;
      expect(tagLink.tag, 'tag_name');
      expect(tagLink.name, 'display');
    });

    test('parses tag search link', () {
      final ast = parse('{{tag_name}}');
      expect(ast, isA<DTextTagSearchLink>());
      expect((ast as DTextTagSearchLink).tags, 'tag_name');
    });

    test('parses link word', () {
      final ast = parse('post #123');
      expect(ast, isA<DTextLinkWord>());
      final linkWord = ast as DTextLinkWord;
      expect(linkWord.type, LinkWord.post);
      expect(linkWord.id, 123);
    });

    test('parses nested bold and italic', () {
      final ast = parse('[b]bold [i]and italic[/i][/b]');
      expect(ast, isA<DTextBold>());
      final bold = ast as DTextBold;
      expect(bold.children, isA<DTextElements>());
      final children = (bold.children as DTextElements).elements;
      expect(children.any((e) => e is DTextItalic), isTrue);
      final italic = children.whereType<DTextItalic>().single;
      expect((italic.children as DTextContent).content, 'and italic');
    });

    test('parses multiple elements in sequence', () {
      final ast = parse('[b]bold[/b] and [i]italic[/i]');
      expect(ast, isA<DTextElements>());
      final elements = (ast as DTextElements).elements;
      expect(elements.any((e) => e is DTextBold), isTrue);
      expect(elements.any((e) => e is DTextItalic), isTrue);
    });

    test('parses strikethrough', () {
      final ast = parse('[s]struck[/s]');
      expect(ast, isA<DTextStrikethrough>());
    });

    test('parses underline', () {
      final ast = parse('[u]underlined[/u]');
      expect(ast, isA<DTextUnderline>());
    });

    test('parses color block', () {
      final ast = parse('[color=red]colored text[/color]');
      expect(ast, isA<DTextColor>());
      final color = ast as DTextColor;
      expect(color.color, 'red');
      expect((color.children as DTextContent).content, 'colored text');
    });

    test('parses header', () {
      final ast = parse('h2. Header text');
      expect(ast, isA<DTextHeader>());
      final header = ast as DTextHeader;
      expect(header.level, 2);
    });

    test('parses list', () {
      final ast = parse('* item one\n* item two');
      expect(ast, isA<DTextList>());
      final list = ast as DTextList;
      expect(list.items.length, 2);
      expect(list.items.first.indent, 0);
    });

    test('parses nested list with indentation', () {
      final ast = parse('* top\n** nested');
      expect(ast, isA<DTextList>());
      final list = ast as DTextList;
      expect(list.items[0].indent, 0);
      expect(list.items[1].indent, 1);
    });
  });
}
