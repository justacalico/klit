import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/shared/data/text.dart';

void main() {
  group('String.ellipse', () {
    test('truncates strings longer than limit', () {
      expect('hello world'.ellipse(5), 'hello...');
    });

    test('returns original when exactly at limit', () {
      expect('hello'.ellipse(5), 'hello');
    });

    test('returns original when shorter than limit', () {
      expect('hi'.ellipse(10), 'hi');
    });

    test('handles empty string', () {
      expect(''.ellipse(3), '');
    });

    test('handles limit of zero', () {
      expect('hello'.ellipse(0), '...');
    });

    test('handles limit of one', () {
      expect('hello'.ellipse(1), 'h...');
    });
  });

  group('String.nullWhenEmpty', () {
    test('returns null for empty string', () {
      expect(''.nullWhenEmpty, isNull);
    });

    test('returns null for whitespace-only string', () {
      expect('   '.nullWhenEmpty, isNull);
    });

    test('returns original for non-empty string', () {
      expect('hello'.nullWhenEmpty, 'hello');
    });

    test('returns original for string with surrounding whitespace', () {
      expect('  hello  '.nullWhenEmpty, '  hello  ');
    });
  });

  group('List<String>.trim', () {
    test('trims all strings and removes empty ones', () {
      expect(['  a  ', '', '  b  '].trim(), ['a', 'b']);
    });

    test('removes whitespace-only entries', () {
      expect(['  ', 'a', '\t'].trim(), ['a']);
    });

    test('returns empty list for all-empty input', () {
      expect(['', '  '].trim(), <String>[]);
    });

    test('handles already-trimmed strings', () {
      expect(['a', 'b', 'c'].trim(), ['a', 'b', 'c']);
    });

    test('handles empty list', () {
      expect(<String>[].trim(), <String>[]);
    });
  });

  group('String.infixRegex', () {
    test('wraps simple string in wildcard regex', () {
      expect('hello'.infixRegex, '.*hello.*');
    });

    test('escapes special regex characters', () {
      expect('a.b*c'.infixRegex, '.*a\\.b\\*c.*');
    });

    test('escapes parentheses', () {
      expect('(test)'.infixRegex, '.*\\(test\\).*');
    });

    test('produces a working regex', () {
      final regex = RegExp('hello'.infixRegex);
      expect(regex.hasMatch('say hello world'), isTrue);
      expect(regex.hasMatch('goodbye'), isFalse);
    });
  });

  group('linkToDisplay', () {
    test('strips protocol, www, and trailing slash', () {
      expect(linkToDisplay('https://www.example.com/page/'), 'example.com/page');
    });

    test('strips www only', () {
      expect(linkToDisplay('https://www.example.com/page'), 'example.com/page');
    });

    test('strips trailing slash only', () {
      expect(linkToDisplay('https://example.com/page/'), 'example.com/page');
    });

    test('strips protocol only', () {
      expect(linkToDisplay('https://example.com/page'), 'example.com/page');
    });

    test('handles root path with trailing slash', () {
      expect(linkToDisplay('https://example.com/'), 'example.com');
    });

    test('handles no path', () {
      expect(linkToDisplay('https://example.com'), 'example.com');
    });

    test('keeps only v query parameter', () {
      expect(
        linkToDisplay('https://example.com/watch?v=abc123&t=10'),
        'example.com/watch?v=abc123',
      );
    });

    test('removes all non-v query parameters', () {
      expect(
        linkToDisplay('https://example.com/watch?t=10&s=20'),
        'example.com/watch',
      );
    });

    test('preserves v parameter without other params', () {
      expect(
        linkToDisplay('https://example.com/watch?v=abc123'),
        'example.com/watch?v=abc123',
      );
    });

    test('removes default http port 80', () {
      expect(linkToDisplay('http://example.com:80/path'), 'example.com/path');
    });

    test('removes default https port 443', () {
      expect(linkToDisplay('https://example.com:443/path'), 'example.com/path');
    });

    test('keeps non-default port', () {
      expect(linkToDisplay('http://example.com:8080/path'), 'example.com:8080/path');
    });

    test('returns original link for invalid URL', () {
      expect(linkToDisplay('http://['), 'http://[');
    });

    test('returns original link for invalid port', () {
      expect(linkToDisplay('http://example.com:abc'), 'http://example.com:abc');
    });

    test('trims input before parsing', () {
      expect(linkToDisplay('  https://example.com/page  '), 'example.com/page');
    });
  });

  group('formatCompactNumber', () {
    test('formats zero', () {
      expect(formatCompactNumber(0), '0');
    });

    test('formats numbers below 1000 as-is', () {
      expect(formatCompactNumber(999), '999');
    });

    test('formats 1000 as 1k', () {
      expect(formatCompactNumber(1000), '1k');
    });

    test('formats 1500 as 1.5k', () {
      expect(formatCompactNumber(1500), '1.5k');
    });

    test('formats 10000 as 10k', () {
      expect(formatCompactNumber(10000), '10k');
    });

    test('formats 100000 as 100k', () {
      expect(formatCompactNumber(100000), '100k');
    });

    test('formats 999999 as 1000k', () {
      expect(formatCompactNumber(999999), '1000k');
    });

    test('formats 1000000 as 1m', () {
      expect(formatCompactNumber(1000000), '1m');
    });

    test('formats 1500000 as 1.5m', () {
      expect(formatCompactNumber(1500000), '1.5m');
    });

    test('formats 1000000000 as 1b', () {
      expect(formatCompactNumber(1000000000), '1b');
    });

    test('formats negative numbers', () {
      expect(formatCompactNumber(-5), '-5');
      expect(formatCompactNumber(-1500), '-1.5k');
      expect(formatCompactNumber(-1000000), '-1m');
    });

    test('boundary between raw and k', () {
      expect(formatCompactNumber(999), '999');
      expect(formatCompactNumber(1000), '1k');
    });

    test('boundary between k and m', () {
      expect(formatCompactNumber(999999), '1000k');
      expect(formatCompactNumber(1000000), '1m');
    });

    test('boundary between m and b', () {
      expect(formatCompactNumber(999999999), '1000m');
      expect(formatCompactNumber(1000000000), '1b');
    });
  });
}
