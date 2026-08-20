import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/shared/widget/range.dart';

void main() {
  group('NumberRange.has', () {
    test('exact match returns true', () {
      expect(const NumberRange(5).has(5), isTrue);
    });

    test('exact match returns false for different value', () {
      expect(const NumberRange(5).has(6), isFalse);
    });

    test('lessThan excludes the boundary', () {
      const range = NumberRange(5, comparison: NumberComparison.lessThan);
      expect(range.has(4), isTrue);
      expect(range.has(5), isFalse);
    });

    test('lessThanOrEqual includes the boundary', () {
      const range = NumberRange(5, comparison: NumberComparison.lessThanOrEqual);
      expect(range.has(5), isTrue);
      expect(range.has(6), isFalse);
    });

    test('greaterThan excludes the boundary', () {
      const range = NumberRange(5, comparison: NumberComparison.greaterThan);
      expect(range.has(6), isTrue);
      expect(range.has(5), isFalse);
    });

    test('greaterThanOrEqual includes the boundary', () {
      const range = NumberRange(
        5,
        comparison: NumberComparison.greaterThanOrEqual,
      );
      expect(range.has(5), isTrue);
      expect(range.has(4), isFalse);
    });

    test('range is exclusive on both ends', () {
      const range = NumberRange(5, endValue: 10);
      expect(range.has(7), isTrue);
      expect(range.has(5), isFalse);
      expect(range.has(10), isFalse);
    });
  });

  group('NumberRange.parse', () {
    test('parses a bare number as exact', () {
      final range = NumberRange.parse('5');
      expect(range.value, 5);
      expect(range.comparison, isNull);
      expect(range.endValue, isNull);
    });

    test('parses < as lessThan', () {
      final range = NumberRange.parse('<5');
      expect(range.value, 5);
      expect(range.comparison, NumberComparison.lessThan);
    });

    test('parses <= as lessThanOrEqual', () {
      final range = NumberRange.parse('<=5');
      expect(range.value, 5);
      expect(range.comparison, NumberComparison.lessThanOrEqual);
    });

    test('parses > as greaterThan', () {
      final range = NumberRange.parse('>5');
      expect(range.value, 5);
      expect(range.comparison, NumberComparison.greaterThan);
    });

    test('parses >= as greaterThanOrEqual', () {
      final range = NumberRange.parse('>=5');
      expect(range.value, 5);
      expect(range.comparison, NumberComparison.greaterThanOrEqual);
    });

    test('parses a..b as a range', () {
      final range = NumberRange.parse('5..10');
      expect(range.value, 5);
      expect(range.endValue, 10);
      expect(range.comparison, isNull);
    });

    test('throws FormatException on invalid input', () {
      expect(() => NumberRange.parse('invalid'), throwsFormatException);
    });

    test('throws FormatException when endValue is less than value', () {
      expect(() => NumberRange.parse('10..5'), throwsFormatException);
    });
  });

  group('NumberRange.tryParse', () {
    test('returns null for invalid input', () {
      expect(NumberRange.tryParse('invalid'), isNull);
    });

    test('returns a range for valid input', () {
      final range = NumberRange.tryParse('5');
      expect(range, isNotNull);
      expect(range!.value, 5);
    });
  });

  group('NumberRange.toString', () {
    test('exact value', () {
      expect(const NumberRange(5).toString(), '5');
    });

    test('lessThan', () {
      expect(
        const NumberRange(5, comparison: NumberComparison.lessThan).toString(),
        '<5',
      );
    });

    test('lessThanOrEqual', () {
      expect(
        const NumberRange(
          5,
          comparison: NumberComparison.lessThanOrEqual,
        ).toString(),
        '<=5',
      );
    });

    test('greaterThan', () {
      expect(
        const NumberRange(5, comparison: NumberComparison.greaterThan).toString(),
        '>5',
      );
    });

    test('greaterThanOrEqual', () {
      expect(
        const NumberRange(
          5,
          comparison: NumberComparison.greaterThanOrEqual,
        ).toString(),
        '>=5',
      );
    });

    test('range', () {
      expect(const NumberRange(5, endValue: 10).toString(), '5..10');
    });
  });

  group('NumberRange.clamp', () {
    test('value within bounds is unchanged', () {
      final clamped = const NumberRange(5).clamp(0, 10);
      expect(clamped.value, 5);
    });

    test('value above upper bound is clamped', () {
      final clamped = const NumberRange(15).clamp(0, 10);
      expect(clamped.value, 10);
    });

    test('value below lower bound is clamped', () {
      final clamped = const NumberRange(-5).clamp(0, 10);
      expect(clamped.value, 0);
    });

    test('endValue is clamped', () {
      final clamped = const NumberRange(5, endValue: 15).clamp(0, 10);
      expect(clamped.value, 5);
      expect(clamped.endValue, 10);
    });

    test('null bounds leave value unchanged', () {
      final clamped = const NumberRange(5).clamp(null, null);
      expect(clamped.value, 5);
    });

    test('comparison is preserved', () {
      final clamped = const NumberRange(
        5,
        comparison: NumberComparison.lessThan,
      ).clamp(0, 10);
      expect(clamped.comparison, NumberComparison.lessThan);
      expect(clamped.value, 5);
    });
  });
}
