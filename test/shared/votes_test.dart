import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/shared/widget/votes.dart';

void main() {
  group('VoteStatus', () {
    test('has exactly three values', () {
      expect(VoteStatus.values, hasLength(3));
    });

    test('contains upvoted, unknown, and downvoted', () {
      expect(VoteStatus.values, contains(VoteStatus.upvoted));
      expect(VoteStatus.values, contains(VoteStatus.unknown));
      expect(VoteStatus.values, contains(VoteStatus.downvoted));
    });
  });

  group('VoteInfo.withVote', () {
    test('unknown status, upvote increments score and sets upvoted', () {
      const info = VoteInfo(score: 10, status: VoteStatus.unknown);
      final result = info.withVote(true);
      expect(result.score, 11);
      expect(result.status, VoteStatus.upvoted);
    });

    test('unknown status, downvote decrements score and sets downvoted', () {
      const info = VoteInfo(score: 10, status: VoteStatus.unknown);
      final result = info.withVote(false);
      expect(result.score, 9);
      expect(result.status, VoteStatus.downvoted);
    });

    test('upvoted status, upvote with replace=false toggles off', () {
      const info = VoteInfo(score: 10, status: VoteStatus.upvoted);
      final result = info.withVote(true);
      expect(result.score, 9);
      expect(result.status, VoteStatus.unknown);
    });

    test('upvoted status, upvote with replace=true stays unchanged', () {
      const info = VoteInfo(score: 10, status: VoteStatus.upvoted);
      final result = info.withVote(true, true);
      expect(result.score, 10);
      expect(result.status, VoteStatus.upvoted);
    });

    test('upvoted status, downvote subtracts 2 and sets downvoted', () {
      const info = VoteInfo(score: 10, status: VoteStatus.upvoted);
      final result = info.withVote(false);
      expect(result.score, 8);
      expect(result.status, VoteStatus.downvoted);
    });

    test('downvoted status, downvote with replace=false toggles off', () {
      const info = VoteInfo(score: 10, status: VoteStatus.downvoted);
      final result = info.withVote(false);
      expect(result.score, 11);
      expect(result.status, VoteStatus.unknown);
    });

    test('downvoted status, downvote with replace=true stays unchanged', () {
      const info = VoteInfo(score: 10, status: VoteStatus.downvoted);
      final result = info.withVote(false, true);
      expect(result.score, 10);
      expect(result.status, VoteStatus.downvoted);
    });

    test('downvoted status, upvote adds 2 and sets upvoted', () {
      const info = VoteInfo(score: 10, status: VoteStatus.downvoted);
      final result = info.withVote(true);
      expect(result.score, 12);
      expect(result.status, VoteStatus.upvoted);
    });
  });

  group('VoteResult.info', () {
    test('ourScore 1 maps to upvoted', () {
      const result = VoteResult(score: 10, ourScore: 1);
      expect(result.info.status, VoteStatus.upvoted);
      expect(result.info.score, 10);
    });

    test('ourScore -1 maps to downvoted', () {
      const result = VoteResult(score: 10, ourScore: -1);
      expect(result.info.status, VoteStatus.downvoted);
    });

    test('ourScore 0 maps to unknown', () {
      const result = VoteResult(score: 10, ourScore: 0);
      expect(result.info.status, VoteStatus.unknown);
    });

    test('ourScore 2 maps to unknown', () {
      const result = VoteResult(score: 10, ourScore: 2);
      expect(result.info.status, VoteStatus.unknown);
    });
  });

  group('VoteInfo JSON', () {
    test('fromJson parses score and status', () {
      final info = VoteInfo.fromJson({
        'score': 42,
        'status': 'upvoted',
      });
      expect(info.score, 42);
      expect(info.status, VoteStatus.upvoted);
    });

    test('fromJson defaults status to unknown when omitted', () {
      final info = VoteInfo.fromJson({'score': 5});
      expect(info.score, 5);
      expect(info.status, VoteStatus.unknown);
    });

    test('toJson serializes score and status', () {
      const info = VoteInfo(score: 42, status: VoteStatus.downvoted);
      final json = info.toJson();
      expect(json['score'], 42);
      expect(json['status'], 'downvoted');
    });

    test('roundtrip fromJson/toJson preserves data', () {
      const original = VoteInfo(score: 99, status: VoteStatus.upvoted);
      final json = original.toJson();
      final restored = VoteInfo.fromJson(json);
      expect(restored.score, original.score);
      expect(restored.status, original.status);
    });

    test('roundtrip with unknown status', () {
      const original = VoteInfo(score: 0, status: VoteStatus.unknown);
      final restored = VoteInfo.fromJson(original.toJson());
      expect(restored, original);
    });
  });

  group('VoteResult JSON', () {
    test('roundtrip fromJson/toJson preserves data', () {
      const original = VoteResult(score: 15, ourScore: -1);
      final restored = VoteResult.fromJson(original.toJson());
      expect(restored.score, 15);
      expect(restored.ourScore, -1);
    });
  });
}
