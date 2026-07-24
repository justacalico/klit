import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/client/data/status.dart';
import 'package:kilt/traits/traits.dart';

void main() {
  group('ClientSyncStatus', () {
    test('fromJson with denyList set', () {
      final json = {'denyList': 'loading'};
      final status = ClientSyncStatus.fromJson(json);
      expect(status.denyList, DenyListSyncStatus.loading);
    });

    test('fromJson with null denyList', () {
      final json = <String, dynamic>{};
      final status = ClientSyncStatus.fromJson(json);
      expect(status.denyList, isNull);
    });

    test('toJson roundtrip with denyList', () {
      const status = ClientSyncStatus(denyList: DenyListSyncStatus.error);
      final json = status.toJson();
      final restored = ClientSyncStatus.fromJson(json);
      expect(restored.denyList, DenyListSyncStatus.error);
    });

    test('toJson roundtrip with null denyList', () {
      const status = ClientSyncStatus();
      final json = status.toJson();
      final restored = ClientSyncStatus.fromJson(json);
      expect(restored.denyList, isNull);
    });

    test('default constructor has null denyList', () {
      const status = ClientSyncStatus();
      expect(status.denyList, isNull);
    });
  });

  group('DenyListSyncStatus', () {
    test('has idle, loading, error values', () {
      expect(DenyListSyncStatus.values.length, 3);
      expect(DenyListSyncStatus.values, contains(DenyListSyncStatus.idle));
      expect(DenyListSyncStatus.values, contains(DenyListSyncStatus.loading));
      expect(DenyListSyncStatus.values, contains(DenyListSyncStatus.error));
    });
  });
}
