import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/client/data/credentials.dart';

void main() {
  group('Credentials.basicAuth', () {
    test('returns Basic prefix with base64 encoded user:pass', () {
      const creds = Credentials(username: 'user', password: 'pass');
      final expected = 'Basic ${base64Encode(utf8.encode('user:pass'))}';
      expect(creds.basicAuth, expected);
    });

    test('format starts with Basic ', () {
      const creds = Credentials(username: 'admin', password: 'secret');
      expect(creds.basicAuth.startsWith('Basic '), isTrue);
    });

    test('decodes back to original credentials', () {
      const creds = Credentials(username: 'testuser', password: 'testpass');
      final encoded = creds.basicAuth.substring('Basic '.length);
      final decoded = utf8.decode(base64Decode(encoded));
      expect(decoded, 'testuser:testpass');
    });
  });

  group('Credentials.parse', () {
    test('parses valid Basic auth header', () {
      final encoded = base64Encode(utf8.encode('user:pass'));
      final creds = Credentials.parse('Basic $encoded');
      expect(creds, isNotNull);
      expect(creds!.username, 'user');
      expect(creds.password, 'pass');
    });

    test('returns null for invalid format', () {
      expect(Credentials.parse('invalid'), isNull);
    });

    test('returns null when no colon in decoded credentials', () {
      final encoded = base64Encode(utf8.encode('usersonly'));
      expect(Credentials.parse('Basic $encoded'), isNull);
    });

    test('returns null for non-Basic scheme', () {
      final encoded = base64Encode(utf8.encode('user:pass'));
      expect(Credentials.parse('Bearer $encoded'), isNull);
    });

    test('handles credentials with special characters', () {
      final encoded = base64Encode(utf8.encode('user:p@ssw0rd!'));
      final creds = Credentials.parse('Basic $encoded');
      expect(creds, isNotNull);
      expect(creds!.username, 'user');
      expect(creds.password, 'p@ssw0rd!');
    });

    test('roundtrips with basicAuth', () {
      const original = Credentials(username: 'roundtrip', password: 'test');
      final parsed = Credentials.parse(original.basicAuth);
      expect(parsed, isNotNull);
      expect(parsed!.username, 'roundtrip');
      expect(parsed.password, 'test');
    });
  });

  group('Credentials.fromJson', () {
    test('fromJson with complete json', () {
      final json = {'username': 'user', 'password': 'pass'};
      final creds = Credentials.fromJson(json);
      expect(creds.username, 'user');
      expect(creds.password, 'pass');
    });

    test('toJson roundtrip', () {
      const creds = Credentials(username: 'rt_user', password: 'rt_pass');
      final json = creds.toJson();
      final restored = Credentials.fromJson(json);
      expect(restored.username, 'rt_user');
      expect(restored.password, 'rt_pass');
    });
  });
}
