import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/tag/tag.dart';

void main() {
  group('poolRegex', () {
    test('matches pool followed by numeric id', () {
      final match = poolRegex().firstMatch('pool:123');
      expect(match, isNotNull);
      expect(match!.namedGroup('id'), '123');
    });

    test('does not match non-numeric id', () {
      expect(poolRegex().firstMatch('pool:abc'), isNull);
    });

    test('does not match without pool prefix', () {
      expect(poolRegex().firstMatch('notpool:123'), isNull);
    });

    test('does not match bare string', () {
      expect(poolRegex().firstMatch('123'), isNull);
    });
  });

  group('favRegex', () {
    test('matches the given username', () {
      final match = favRegex('user1').firstMatch('fav:user1');
      expect(match, isNotNull);
    });

    test('does not match a different username', () {
      expect(favRegex('user1').firstMatch('fav:user2'), isNull);
    });

    test('does not match without fav prefix', () {
      expect(favRegex('user1').firstMatch('user1'), isNull);
    });
  });
}
