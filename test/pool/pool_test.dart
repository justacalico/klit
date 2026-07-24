import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/pool/data/pool.dart';

void main() {
  final createdAt = DateTime.parse('2024-01-15T10:30:00.000Z');
  final updatedAt = DateTime.parse('2024-02-20T14:00:00.000Z');

  final pool = Pool(
    id: 1,
    name: 'test pool',
    createdAt: createdAt,
    updatedAt: updatedAt,
    description: 'a description',
    postIds: const [1, 2, 3, 4, 5],
    postCount: 5,
    active: true,
  );

  group('Pool JSON', () {
    test('toJson serializes all fields', () {
      final json = pool.toJson();
      expect(json['id'], 1);
      expect(json['name'], 'test pool');
      expect(json['createdAt'], createdAt.toIso8601String());
      expect(json['updatedAt'], updatedAt.toIso8601String());
      expect(json['description'], 'a description');
      expect(json['postIds'], [1, 2, 3, 4, 5]);
      expect(json['postCount'], 5);
      expect(json['active'], true);
    });

    test('fromJson parses all fields', () {
      final parsed = Pool.fromJson(pool.toJson());
      expect(parsed.id, 1);
      expect(parsed.name, 'test pool');
      expect(parsed.createdAt, createdAt);
      expect(parsed.updatedAt, updatedAt);
      expect(parsed.description, 'a description');
      expect(parsed.postIds, [1, 2, 3, 4, 5]);
      expect(parsed.postCount, 5);
      expect(parsed.active, isTrue);
    });

    test('roundtrip preserves data', () {
      final restored = Pool.fromJson(pool.toJson());
      expect(restored.id, pool.id);
      expect(restored.name, pool.name);
      expect(restored.createdAt, pool.createdAt);
      expect(restored.updatedAt, pool.updatedAt);
      expect(restored.description, pool.description);
      expect(restored.postIds, pool.postIds);
      expect(restored.postCount, pool.postCount);
      expect(restored.active, pool.active);
    });

    test('handles empty postIds list', () {
      final emptyPool = Pool(
        id: 2,
        name: 'empty',
        createdAt: createdAt,
        updatedAt: updatedAt,
        description: '',
        postIds: const [],
        postCount: 0,
        active: false,
      );
      final restored = Pool.fromJson(emptyPool.toJson());
      expect(restored.postIds, isEmpty);
      expect(restored.postCount, 0);
      expect(restored.active, isFalse);
    });
  });

  group('Pool.copyWith', () {
    test('changes name and description', () {
      final copied = pool.copyWith(name: 'new name', description: 'new desc');
      expect(copied.name, 'new name');
      expect(copied.description, 'new desc');
      expect(copied.id, pool.id);
      expect(copied.postIds, pool.postIds);
    });

    test('changes postIds and postCount', () {
      final copied = pool.copyWith(
        postIds: const [10, 20],
        postCount: 2,
      );
      expect(copied.postIds, [10, 20]);
      expect(copied.postCount, 2);
    });
  });
}
