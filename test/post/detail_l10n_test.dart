// SPDX-License-Identifier: AGPL-3.0

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';

void main() {
  group('post detail l10n', () {
    test('postDetailTitle formats with id in English', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(l10n.postDetailTitle(42), 'Post #42');
    });

    test('postFailedLoadPost exists in English', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(l10n.postFailedLoadPost, 'Failed to load post');
    });

    test('postNotFound exists in English', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(l10n.postNotFound, 'Post not found');
    });

    test('postHide and postShow exist in English', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(l10n.postHide, 'Hide');
      expect(l10n.postShow, 'Show');
    });

    test('fullscreen action labels exist in English', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(l10n.postFavorited, 'Favorited');
      expect(l10n.postUnfavorited, 'Unfavorited');
      expect(l10n.postUpvoted, 'Upvoted');
      expect(l10n.postUpvoteRemoved, 'Upvote removed');
      expect(l10n.postDownvoted, 'Downvoted');
      expect(l10n.postDownvoteRemoved, 'Downvote removed');
    });

    test('postDetailTitle formats with id in Chinese', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('zh'));
      expect(l10n.postDetailTitle(42), '帖子 #42');
    });

    test('fullscreen action labels exist in Chinese', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('zh'));
      expect(l10n.postFavorited, '已收藏');
      expect(l10n.postUnfavorited, '已取消收藏');
      expect(l10n.postUpvoted, '已点赞');
      expect(l10n.postUpvoteRemoved, '已取消点赞');
      expect(l10n.postDownvoted, '已踩');
      expect(l10n.postDownvoteRemoved, '已取消踩');
    });
  });
}
