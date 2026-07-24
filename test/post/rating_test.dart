import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/post/post.dart';

void main() {
  group('ExtraRatingData.titleName', () {
    test('Rating.s is "Safe"', () {
      expect(Rating.s.titleName, 'Safe');
    });

    test('Rating.q is "Questionable"', () {
      expect(Rating.q.titleName, 'Questionable');
    });

    test('Rating.e is "Explicit"', () {
      expect(Rating.e.titleName, 'Explicit');
    });
  });

  group('Rating.values', () {
    test('has exactly three values', () {
      expect(Rating.values.length, 3);
    });

    test('contains s, q, and e in order', () {
      expect(Rating.values, [Rating.s, Rating.q, Rating.e]);
    });
  });

  group('Rating.values.asNameMap', () {
    test('maps "s" to Rating.s', () {
      expect(Rating.values.asNameMap()['s'], Rating.s);
    });

    test('maps "q" to Rating.q', () {
      expect(Rating.values.asNameMap()['q'], Rating.q);
    });

    test('maps "e" to Rating.e', () {
      expect(Rating.values.asNameMap()['e'], Rating.e);
    });

    test('returns null for an unknown name', () {
      expect(Rating.values.asNameMap()['x'], isNull);
    });
  });
}
