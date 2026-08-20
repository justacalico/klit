import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/markup/data/color.dart';

void main() {
  group('parseColor', () {
    test('parses 6-digit uppercase hex', () {
      expect(parseColor('#FF0000'), const Color(0xFFFF0000));
    });

    test('expands 3-digit hex', () {
      expect(parseColor('#F00'), const Color(0xFFFF0000));
    });

    test('parses lowercase hex', () {
      expect(parseColor('#ff0000'), const Color(0xFFFF0000));
    });

    test('parses mixed-case hex', () {
      expect(parseColor('#FfAa00'), const Color(0xFFFFAA00));
    });

    test('returns null for invalid hex characters', () {
      expect(parseColor('#GGGGGG'), isNull);
    });

    test('returns null for wrong length', () {
      expect(parseColor('#12345'), isNull);
    });

    test('returns null for unrecognized string', () {
      expect(parseColor('invalid'), isNull);
    });

    test('parses named color "red"', () {
      expect(parseColor('red'), HtmlColors.red.value);
    });

    test('parses named color "blue"', () {
      expect(parseColor('blue'), HtmlColors.blue.value);
    });

    test('parses named color "green"', () {
      expect(parseColor('green'), HtmlColors.green.value);
    });

    test('parses named color "black"', () {
      expect(parseColor('black'), HtmlColors.black.value);
    });

    test('parses named color "ivory"', () {
      expect(parseColor('ivory'), HtmlColors.ivory.value);
    });

    test('parses named color "navy"', () {
      expect(parseColor('navy'), HtmlColors.navy.value);
    });

    test('parses camelCase named color "mediumVioletRed"', () {
      expect(parseColor('mediumVioletRed'), HtmlColors.mediumVioletRed.value);
    });

    test('parses camelCase named color "deepPink"', () {
      expect(parseColor('deepPink'), HtmlColors.deepPink.value);
    });

    test('returns null for empty string', () {
      expect(parseColor(''), isNull);
    });

    test('returns null for hex without hash', () {
      expect(parseColor('FF0000'), isNull);
    });
  });
}
