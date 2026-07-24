import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/comment/data/comment.dart';
import 'package:kilt/reply/data/reply.dart';

void main() {
  final createdAt = DateTime.parse('2024-01-15T10:30:00.000Z');
  final updatedAt = DateTime.parse('2024-02-20T14:00:00.000Z');

  final reply = Reply(
    id: 1,
    creatorId: 5,
    creator: 'author',
    createdAt: createdAt,
    updaterId: 7,
    updater: 'editor',
    updatedAt: updatedAt,
    body: 'reply body',
    topicId: 10,
    warning: WarningType.record,
    hidden: false,
  );

  group('Reply JSON', () {
    test('toJson serializes all fields', () {
      final json = reply.toJson();
      expect(json['id'], 1);
      expect(json['creatorId'], 5);
      expect(json['creator'], 'author');
      expect(json['createdAt'], createdAt.toIso8601String());
      expect(json['updaterId'], 7);
      expect(json['updater'], 'editor');
      expect(json['updatedAt'], updatedAt.toIso8601String());
      expect(json['body'], 'reply body');
      expect(json['topicId'], 10);
      expect(json['warning'], 'record');
      expect(json['hidden'], false);
    });

    test('fromJson parses all fields', () {
      final parsed = Reply.fromJson(reply.toJson());
      expect(parsed.id, 1);
      expect(parsed.creatorId, 5);
      expect(parsed.creator, 'author');
      expect(parsed.createdAt, createdAt);
      expect(parsed.updaterId, 7);
      expect(parsed.updater, 'editor');
      expect(parsed.updatedAt, updatedAt);
      expect(parsed.body, 'reply body');
      expect(parsed.topicId, 10);
      expect(parsed.warning, WarningType.record);
      expect(parsed.hidden, isFalse);
    });

    test('roundtrip preserves data', () {
      final restored = Reply.fromJson(reply.toJson());
      expect(restored.id, reply.id);
      expect(restored.creatorId, reply.creatorId);
      expect(restored.creator, reply.creator);
      expect(restored.createdAt, reply.createdAt);
      expect(restored.updaterId, reply.updaterId);
      expect(restored.updater, reply.updater);
      expect(restored.updatedAt, reply.updatedAt);
      expect(restored.body, reply.body);
      expect(restored.topicId, reply.topicId);
      expect(restored.warning, reply.warning);
      expect(restored.hidden, reply.hidden);
    });

    test('handles null updater and warning', () {
      final replyNull = Reply(
        id: 2,
        creatorId: 5,
        creator: 'author',
        createdAt: createdAt,
        updaterId: null,
        updater: null,
        updatedAt: updatedAt,
        body: 'no updater',
        topicId: 10,
        warning: null,
        hidden: false,
      );
      final restored = Reply.fromJson(replyNull.toJson());
      expect(restored.updaterId, isNull);
      expect(restored.updater, isNull);
      expect(restored.warning, isNull);
    });
  });

  group('Reply.copyWith', () {
    test('changes body and topicId', () {
      final copied = reply.copyWith(body: 'new body', topicId: 20);
      expect(copied.body, 'new body');
      expect(copied.topicId, 20);
      expect(copied.id, reply.id);
      expect(copied.creator, reply.creator);
    });

    test('changes warning and hidden', () {
      final copied = reply.copyWith(warning: WarningType.ban, hidden: true);
      expect(copied.warning, WarningType.ban);
      expect(copied.hidden, isTrue);
      expect(copied.body, reply.body);
    });
  });
}
