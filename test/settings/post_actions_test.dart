import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/settings/data/post_actions.dart';

void main() {
  group('PostActionId', () {
    test('fromKey returns correct enum for valid key', () {
      expect(PostActionId.fromKey('upvote'), PostActionId.upvote);
    });

    test('fromKey returns correct enum for each key', () {
      expect(PostActionId.fromKey('downvote'), PostActionId.downvote);
      expect(PostActionId.fromKey('favorite'), PostActionId.favorite);
      expect(PostActionId.fromKey('share'), PostActionId.share);
      expect(PostActionId.fromKey('download'), PostActionId.download);
      expect(PostActionId.fromKey('browse'), PostActionId.browse);
      expect(PostActionId.fromKey('iFinished'), PostActionId.iFinished);
    });

    test('fromKey returns null for invalid key', () {
      expect(PostActionId.fromKey('invalid'), isNull);
    });

    test('fromKey returns null for empty string', () {
      expect(PostActionId.fromKey(''), isNull);
    });

    test('all values have key, label, and icon', () {
      for (final action in PostActionId.values) {
        expect(action.key, isNotEmpty);
        expect(action.label, isNotEmpty);
        expect(action.icon, isA<IconData>());
      }
    });
  });

  group('PostActionPreferences.decode', () {
    test('empty string returns default actions', () {
      expect(PostActionPreferences.decode(''), PostActionPreferences.defaultActions);
    });

    test('decodes single action', () {
      expect(PostActionPreferences.decode('upvote'), [PostActionId.upvote]);
    });

    test('decodes comma-separated actions', () {
      expect(
        PostActionPreferences.decode('upvote,downvote'),
        [PostActionId.upvote, PostActionId.downvote],
      );
    });

    test('deduplicates repeated actions', () {
      expect(
        PostActionPreferences.decode('upvote,upvote'),
        [PostActionId.upvote],
      );
    });

    test('skips invalid keys', () {
      expect(
        PostActionPreferences.decode('invalid,upvote'),
        [PostActionId.upvote],
      );
    });

    test('trims whitespace around keys', () {
      expect(
        PostActionPreferences.decode(' upvote , downvote '),
        [PostActionId.upvote, PostActionId.downvote],
      );
    });

    test('returns default when all keys are invalid', () {
      expect(
        PostActionPreferences.decode('invalid,alsoinvalid'),
        PostActionPreferences.defaultActions,
      );
    });

    test('preserves order of first occurrence when deduplicating', () {
      expect(
        PostActionPreferences.decode('downvote,upvote,downvote'),
        [PostActionId.downvote, PostActionId.upvote],
      );
    });
  });

  group('PostActionPreferences.encode', () {
    test('empty list returns default keys joined', () {
      expect(
        PostActionPreferences.encode([]),
        PostActionPreferences.defaultActions.map((e) => e.key).join(','),
      );
    });

    test('encodes single action', () {
      expect(PostActionPreferences.encode([PostActionId.upvote]), 'upvote');
    });

    test('encodes multiple actions', () {
      expect(
        PostActionPreferences.encode([PostActionId.upvote, PostActionId.downvote]),
        'upvote,downvote',
      );
    });

    test('deduplicates repeated actions', () {
      expect(
        PostActionPreferences.encode([PostActionId.upvote, PostActionId.upvote]),
        'upvote',
      );
    });

    test('preserves order when deduplicating', () {
      expect(
        PostActionPreferences.encode([
          PostActionId.downvote,
          PostActionId.upvote,
          PostActionId.downvote,
        ]),
        'downvote,upvote',
      );
    });
  });

  group('PostActionPreferences.defaultActions', () {
    test('contains expected actions', () {
      expect(PostActionPreferences.defaultActions, [
        PostActionId.favorite,
        PostActionId.upvote,
        PostActionId.downvote,
        PostActionId.download,
      ]);
    });

    test('is not empty', () {
      expect(PostActionPreferences.defaultActions, isNotEmpty);
    });
  });

  group('PostActionPreferences.menuActions', () {
    test('contains expected actions', () {
      expect(PostActionPreferences.menuActions, [
        PostActionId.share,
        PostActionId.download,
        PostActionId.browse,
      ]);
    });

    test('is not empty', () {
      expect(PostActionPreferences.menuActions, isNotEmpty);
    });
  });

  group('encode/decode roundtrip', () {
    test('roundtrip preserves actions', () {
      final actions = [PostActionId.upvote, PostActionId.downvote];
      final encoded = PostActionPreferences.encode(actions);
      final decoded = PostActionPreferences.decode(encoded);
      expect(decoded, actions);
    });

    test('roundtrip with all actions', () {
      final actions = PostActionId.values.toList();
      final encoded = PostActionPreferences.encode(actions);
      final decoded = PostActionPreferences.decode(encoded);
      expect(decoded, PostActionId.values.toList());
    });
  });
}
