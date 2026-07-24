import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/comment/data/comment.dart';
import 'package:kilt/shared/widget/votes.dart';

void main() {
  final createdAt = DateTime.parse('2024-01-15T10:30:00.000Z');
  final updatedAt = DateTime.parse('2024-02-20T14:00:00.000Z');

  group('WarningType', () {
    test('has three values', () {
      expect(WarningType.values, hasLength(3));
    });

    test('warning has a message', () {
      expect(
        WarningType.warning.message,
        'User received a warning for this message',
      );
    });

    test('record has a message', () {
      expect(
        WarningType.record.message,
        'User received a record for this message',
      );
    });

    test('ban has a message', () {
      expect(
        WarningType.ban.message,
        'User was banned for this message',
      );
    });
  });

  group('Comment JSON', () {
    final comment = Comment(
      id: 1,
      postId: 100,
      body: 'test comment',
      createdAt: createdAt,
      updatedAt: updatedAt,
      creatorId: 5,
      creatorName: 'tester',
      vote: const VoteInfo(score: 10, status: VoteStatus.upvoted),
      warning: WarningType.warning,
      hidden: false,
    );

    test('toJson serializes scalar fields', () {
      final json = comment.toJson();
      expect(json['id'], 1);
      expect(json['postId'], 100);
      expect(json['body'], 'test comment');
      expect(json['createdAt'], createdAt.toIso8601String());
      expect(json['updatedAt'], updatedAt.toIso8601String());
      expect(json['creatorId'], 5);
      expect(json['creatorName'], 'tester');
      expect(json['warning'], 'warning');
      expect(json['hidden'], false);
    });

    test('fromJson parses all fields with vote as map', () {
      final json = {
        'id': 1,
        'postId': 100,
        'body': 'test comment',
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'creatorId': 5,
        'creatorName': 'tester',
        'vote': {'score': 10, 'status': 'upvoted'},
        'warning': 'warning',
        'hidden': false,
      };
      final parsed = Comment.fromJson(json);
      expect(parsed.id, 1);
      expect(parsed.postId, 100);
      expect(parsed.body, 'test comment');
      expect(parsed.createdAt, createdAt);
      expect(parsed.updatedAt, updatedAt);
      expect(parsed.creatorId, 5);
      expect(parsed.creatorName, 'tester');
      expect(parsed.vote?.score, 10);
      expect(parsed.vote?.status, VoteStatus.upvoted);
      expect(parsed.warning, WarningType.warning);
      expect(parsed.hidden, false);
    });

    test('roundtrip preserves data with null vote and warning', () {
      final commentNull = Comment(
        id: 2,
        postId: 200,
        body: 'no vote',
        createdAt: createdAt,
        updatedAt: updatedAt,
        creatorId: 7,
        creatorName: 'guest',
        vote: null,
        warning: null,
        hidden: true,
      );
      final restored = Comment.fromJson(commentNull.toJson());
      expect(restored.id, commentNull.id);
      expect(restored.body, commentNull.body);
      expect(restored.vote, isNull);
      expect(restored.warning, isNull);
      expect(restored.hidden, isTrue);
    });

    test('fromJson handles null vote and warning', () {
      final json = {
        'id': 3,
        'postId': 300,
        'body': 'minimal',
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'creatorId': 9,
        'creatorName': 'anon',
        'vote': null,
        'warning': null,
        'hidden': false,
      };
      final parsed = Comment.fromJson(json);
      expect(parsed.vote, isNull);
      expect(parsed.warning, isNull);
    });
  });

  group('Comment.copyWith', () {
    test('changes a single field', () {
      final comment = Comment(
        id: 1,
        postId: 100,
        body: 'original',
        createdAt: createdAt,
        updatedAt: updatedAt,
        creatorId: 5,
        creatorName: 'tester',
        vote: null,
        warning: null,
        hidden: false,
      );
      final copied = comment.copyWith(body: 'edited');
      expect(copied.body, 'edited');
      expect(copied.id, comment.id);
      expect(copied.postId, comment.postId);
      expect(copied.creatorName, comment.creatorName);
    });

    test('changes vote and warning', () {
      final comment = Comment(
        id: 1,
        postId: 100,
        body: 'text',
        createdAt: createdAt,
        updatedAt: updatedAt,
        creatorId: 5,
        creatorName: 'tester',
        vote: null,
        warning: null,
        hidden: false,
      );
      final copied = comment.copyWith(
        vote: const VoteInfo(score: 5, status: VoteStatus.downvoted),
        warning: WarningType.ban,
      );
      expect(copied.vote?.score, 5);
      expect(copied.vote?.status, VoteStatus.downvoted);
      expect(copied.warning, WarningType.ban);
    });
  });
}
