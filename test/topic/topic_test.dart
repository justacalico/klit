import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/topic/data/topic.dart';

void main() {
  final createdAt = DateTime.parse('2024-01-15T10:30:00.000Z');
  final updatedAt = DateTime.parse('2024-02-20T14:00:00.000Z');

  final topic = Topic(
    id: 1,
    creatorId: 5,
    creator: 'author',
    createdAt: createdAt,
    updaterId: 7,
    updater: 'editor',
    updatedAt: updatedAt,
    title: 'test topic',
    responseCount: 42,
    sticky: true,
    locked: false,
    hidden: false,
    categoryId: 3,
  );

  group('Topic JSON', () {
    test('toJson serializes all fields', () {
      final json = topic.toJson();
      expect(json['id'], 1);
      expect(json['creatorId'], 5);
      expect(json['creator'], 'author');
      expect(json['createdAt'], createdAt.toIso8601String());
      expect(json['updaterId'], 7);
      expect(json['updater'], 'editor');
      expect(json['updatedAt'], updatedAt.toIso8601String());
      expect(json['title'], 'test topic');
      expect(json['responseCount'], 42);
      expect(json['sticky'], true);
      expect(json['locked'], false);
      expect(json['hidden'], false);
      expect(json['categoryId'], 3);
    });

    test('fromJson parses all fields', () {
      final parsed = Topic.fromJson(topic.toJson());
      expect(parsed.id, 1);
      expect(parsed.creatorId, 5);
      expect(parsed.creator, 'author');
      expect(parsed.createdAt, createdAt);
      expect(parsed.updaterId, 7);
      expect(parsed.updater, 'editor');
      expect(parsed.updatedAt, updatedAt);
      expect(parsed.title, 'test topic');
      expect(parsed.responseCount, 42);
      expect(parsed.sticky, isTrue);
      expect(parsed.locked, isFalse);
      expect(parsed.hidden, isFalse);
      expect(parsed.categoryId, 3);
    });

    test('roundtrip preserves data', () {
      final restored = Topic.fromJson(topic.toJson());
      expect(restored.id, topic.id);
      expect(restored.creatorId, topic.creatorId);
      expect(restored.creator, topic.creator);
      expect(restored.createdAt, topic.createdAt);
      expect(restored.updaterId, topic.updaterId);
      expect(restored.updater, topic.updater);
      expect(restored.updatedAt, topic.updatedAt);
      expect(restored.title, topic.title);
      expect(restored.responseCount, topic.responseCount);
      expect(restored.sticky, topic.sticky);
      expect(restored.locked, topic.locked);
      expect(restored.hidden, topic.hidden);
      expect(restored.categoryId, topic.categoryId);
    });
  });

  group('Topic.copyWith', () {
    test('changes title and responseCount', () {
      final copied = topic.copyWith(
        title: 'updated title',
        responseCount: 99,
      );
      expect(copied.title, 'updated title');
      expect(copied.responseCount, 99);
      expect(copied.id, topic.id);
      expect(copied.creator, topic.creator);
    });

    test('changes sticky and locked', () {
      final copied = topic.copyWith(sticky: false, locked: true);
      expect(copied.sticky, isFalse);
      expect(copied.locked, isTrue);
      expect(copied.title, topic.title);
    });
  });
}
