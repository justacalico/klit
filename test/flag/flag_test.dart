import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/flag/flag.dart';

void main() {
  group('PostFlag', () {
    test('fromJson with complete json', () {
      final json = {
        'id': 1,
        'createdAt': '2024-01-15T10:30:00.000',
        'postId': 12345,
        'reason': 'inferior version',
        'creatorId': 100,
        'isResolved': false,
        'updatedAt': '2024-01-16T12:00:00.000',
        'isDeletion': false,
        'type': 'flag',
      };
      final flag = PostFlag.fromJson(json);
      expect(flag.id, 1);
      expect(flag.createdAt, DateTime(2024, 1, 15, 10, 30));
      expect(flag.postId, 12345);
      expect(flag.reason, 'inferior version');
      expect(flag.creatorId, 100);
      expect(flag.isResolved, isFalse);
      expect(flag.updatedAt, DateTime(2024, 1, 16, 12, 0));
      expect(flag.isDeletion, isFalse);
      expect(flag.type, PostFlagType.flag);
    });

    test('fromJson with deletion type', () {
      final json = {
        'id': 2,
        'createdAt': '2024-02-01T08:00:00.000',
        'postId': 999,
        'reason': 'duplicate',
        'creatorId': 50,
        'isResolved': true,
        'updatedAt': '2024-02-02T09:00:00.000',
        'isDeletion': true,
        'type': 'deletion',
      };
      final flag = PostFlag.fromJson(json);
      expect(flag.type, PostFlagType.deletion);
      expect(flag.isDeletion, isTrue);
      expect(flag.isResolved, isTrue);
    });

    test('toJson roundtrip', () {
      final flag = PostFlag(
        id: 5,
        createdAt: DateTime(2024, 3, 1, 10, 0),
        postId: 777,
        reason: 'test reason',
        creatorId: 42,
        isResolved: true,
        updatedAt: DateTime(2024, 3, 2, 11, 0),
        isDeletion: false,
        type: PostFlagType.flag,
      );
      final json = flag.toJson();
      final restored = PostFlag.fromJson(json);
      expect(restored.id, flag.id);
      expect(restored.createdAt, flag.createdAt);
      expect(restored.postId, flag.postId);
      expect(restored.reason, flag.reason);
      expect(restored.creatorId, flag.creatorId);
      expect(restored.isResolved, flag.isResolved);
      expect(restored.updatedAt, flag.updatedAt);
      expect(restored.isDeletion, flag.isDeletion);
      expect(restored.type, flag.type);
    });
  });

  group('PostFlagType', () {
    test('has flag and deletion values', () {
      expect(PostFlagType.values.length, 2);
      expect(PostFlagType.values, contains(PostFlagType.flag));
      expect(PostFlagType.values, contains(PostFlagType.deletion));
    });
  });

  group('FlagType', () {
    test('all values have non-empty id', () {
      for (final type in FlagType.values) {
        expect(type.id, isNotEmpty);
      }
    });

    test('all values have non-empty title', () {
      for (final type in FlagType.values) {
        expect(type.title, isNotEmpty);
      }
    });

    test('all values have non-empty body', () {
      for (final type in FlagType.values) {
        expect(type.body, isNotEmpty);
      }
    });

    test('ids use snake_case', () {
      expect(FlagType.uploadingGuidelines.id, 'uploading_guidelines');
      expect(FlagType.youngHuman.id, 'young_human');
      expect(FlagType.dnpArtist.id, 'dnp_artist');
      expect(FlagType.payContent.id, 'pay_content');
      expect(FlagType.trace.id, 'trace');
      expect(FlagType.previouslyDeleted.id, 'previously_deleted');
      expect(FlagType.realPorn.id, 'real_porn');
      expect(FlagType.corrupt.id, 'corrupt');
      expect(FlagType.inferior.id, 'inferior');
    });

    test('has all expected values', () {
      expect(FlagType.values.length, 9);
      expect(FlagType.values, contains(FlagType.uploadingGuidelines));
      expect(FlagType.values, contains(FlagType.youngHuman));
      expect(FlagType.values, contains(FlagType.dnpArtist));
      expect(FlagType.values, contains(FlagType.payContent));
      expect(FlagType.values, contains(FlagType.trace));
      expect(FlagType.values, contains(FlagType.previouslyDeleted));
      expect(FlagType.values, contains(FlagType.realPorn));
      expect(FlagType.values, contains(FlagType.corrupt));
      expect(FlagType.values, contains(FlagType.inferior));
    });
  });
}
