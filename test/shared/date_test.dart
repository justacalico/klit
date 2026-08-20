import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:kilt/shared/data/date.dart';

void main() {
  setUpAll(DateFormatting.ensureInitialized);

  group('DateFormatting.date', () {
    test('formats date as yyyy/M/d', () {
      expect(DateFormatting.date(DateTime(2024, 1, 15)), '2024/1/15');
    });

    test('formats single-digit month and day without padding', () {
      expect(DateFormatting.date(DateTime(2024, 3, 7)), '2024/3/7');
    });

    test('formats double-digit month and day', () {
      expect(DateFormatting.date(DateTime(2024, 12, 31)), '2024/12/31');
    });
  });

  group('DateFormatting.dateTime', () {
    test('includes the date portion', () {
      final result = DateFormatting.dateTime(DateTime(2024, 1, 15, 14, 30));
      expect(result.startsWith('2024/1/15 '), isTrue);
    });

    test('is longer than just the date', () {
      final dt = DateTime(2024, 1, 15, 14, 30);
      final result = DateFormatting.dateTime(dt);
      expect(result.length, greaterThan(DateFormatting.date(dt).length));
    });
  });

  group('DateFormatting.time', () {
    test('returns a non-empty string', () {
      final result = DateFormatting.time(DateTime(2024, 1, 15, 14, 30));
      expect(result, isNotEmpty);
    });

    test('contains at least one digit', () {
      final result = DateFormatting.time(DateTime(2024, 1, 15, 14, 30));
      expect(RegExp(r'\d').hasMatch(result), isTrue);
    });
  });

  group('DateFormatting.named', () {
    test('returns "Today" for current date with null context', () {
      final now = DateTime.now();
      expect(DateFormatting.named(now), 'Today');
    });

    test('returns "Yesterday" for previous date with null context', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(DateFormatting.named(yesterday), 'Yesterday');
    });

    test('returns weekday name for date within 7 days', () {
      final date = DateTime.now().subtract(const Duration(days: 3));
      final expected = DateFormat.EEEE().format(date);
      expect(DateFormatting.named(date), expected);
    });

    test('returns date format for date older than 7 days', () {
      final date = DateTime.now().subtract(const Duration(days: 10));
      final expected = DateFormatting.date(date);
      expect(DateFormatting.named(date), expected);
    });

    test('returns date format for date far in the past', () {
      final date = DateTime(2020, 6, 15);
      expect(DateFormatting.named(date), '2020/6/15');
    });
  });
}
