import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/account/data/account.dart';

void main() {
  final account = Account(
    id: 1,
    name: 'testuser',
    avatarId: 42,
    blacklistedTags: 'tag1 tag2',
    perPage: 50,
  );

  group('Account JSON', () {
    test('toJson serializes all fields', () {
      final json = account.toJson();
      expect(json['id'], 1);
      expect(json['name'], 'testuser');
      expect(json['avatarId'], 42);
      expect(json['blacklistedTags'], 'tag1 tag2');
      expect(json['perPage'], 50);
    });

    test('fromJson parses all fields', () {
      final parsed = Account.fromJson(account.toJson());
      expect(parsed.id, 1);
      expect(parsed.name, 'testuser');
      expect(parsed.avatarId, 42);
      expect(parsed.blacklistedTags, 'tag1 tag2');
      expect(parsed.perPage, 50);
    });

    test('roundtrip preserves data', () {
      final restored = Account.fromJson(account.toJson());
      expect(restored.id, account.id);
      expect(restored.name, account.name);
      expect(restored.avatarId, account.avatarId);
      expect(restored.blacklistedTags, account.blacklistedTags);
      expect(restored.perPage, account.perPage);
    });

    test('handles null optional fields', () {
      final accountNull = Account(
        id: 2,
        name: 'minimal',
        avatarId: null,
        blacklistedTags: null,
        perPage: null,
      );
      final restored = Account.fromJson(accountNull.toJson());
      expect(restored.avatarId, isNull);
      expect(restored.blacklistedTags, isNull);
      expect(restored.perPage, isNull);
    });
  });

  group('Account.copyWith', () {
    test('changes name and avatarId', () {
      final copied = account.copyWith(name: 'newname', avatarId: 99);
      expect(copied.name, 'newname');
      expect(copied.avatarId, 99);
      expect(copied.id, account.id);
    });

    test('changes blacklistedTags and perPage', () {
      final copied = account.copyWith(
        blacklistedTags: 'new tags',
        perPage: 100,
      );
      expect(copied.blacklistedTags, 'new tags');
      expect(copied.perPage, 100);
    });
  });
}
