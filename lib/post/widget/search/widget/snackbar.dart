// SPDX-License-Identifier: AGPL-3.0

import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/logs/logs.dart';
import 'package:kilt/post/post.dart';
import 'package:kilt/settings/settings.dart';
import 'package:kilt/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

Future<void> postDownloadingNotification(
  BuildContext context,
  Set<Post> items,
) async {
  Settings settings = context.read<Settings>();
  BaseCacheManager cache = context.read<BaseCacheManager>();
  final l10n = AppLocalizations.of(context);
  final logger = Logger('Post Downloader');
  return loadingNotification<Post>(
    context: context,
    icon: const Icon(Icons.download),
    timeout: const Duration(milliseconds: 100),
    process: (item) async {
      try {
        await item.download(
          path: settings.downloadPath.value,
          onPathChanged: (path) => settings.downloadPath.value = path,
          folder: AppInfo.instance.appName,
          cache: cache,
        );
        return true;
      } on FileDownloadException catch (exception, stacktrace) {
        logger.severe('Failed to download post', exception, stacktrace);
        return false;
      }
    },
    items: items,
    onDone: (items) => items.length == 1
        ? l10n.postDownloadedOne(items.first.id)
        : l10n.postDownloadedMany(items.length),
    onProgress: (items, index) => items.length == 1
        ? l10n.postDownloadingOne(items.first.id)
        : l10n.postDownloadingProgress(items.elementAt(index).id, index + 1, items.length),
    onFailure: (items, index) =>
        l10n.postDownloadFailed(items.elementAt(index).id),
    onCancel: (items, index) => l10n.postDownloadCancelled,
  );
}

Future<void> postFavoritingNotification(
  BuildContext context,
  Set<Post> items,
  PostController controller,
  bool isLiked,
) {
  final l10n = AppLocalizations.of(context);
  PostController controller = context.read<PostController>();
  bool upvote = context.read<Settings>().upvoteFavs.value;
  return loadingNotification<Post>(
    context: context,
    icon: const Icon(Icons.favorite),
    items: items,
    timeout: const Duration(milliseconds: 300),
    process: (post) async {
      if (isLiked) {
        if (post.isFavorited) {
          return controller.unfav(post);
        } else {
          return true;
        }
      } else {
        if (!post.isFavorited) {
          return Future<bool>(() async {
            bool result = await controller.fav(post);
            if (result && upvote) {
              result = await controller.vote(
                post: controller.postById(post.id)!,
                upvote: true,
                replace: true,
              );
            }
            return result;
          });
        } else {
          return true;
        }
      }
    },
    onDone: isLiked
        ? (items) => items.length == 1
              ? l10n.postUnfavoritedOne(items.first.id)
              : l10n.postUnfavoritedMany(items.length)
        : (items) => items.length == 1
              ? l10n.postFavoritedOne(items.first.id)
              : l10n.postFavoritedMany(items.length),
    onProgress: isLiked
        ? (items, index) => items.length == 1
              ? l10n.postUnfavoritingOne(items.first.id)
              : l10n.postUnfavoritingProgress(items.elementAt(index).id, index + 1, items.length)
        : (items, index) => items.length == 1
              ? l10n.postFavoritingOne(items.first.id)
              : l10n.postFavoritingProgress(items.elementAt(index).id, index + 1, items.length),
    onFailure: isLiked
        ? (items, index) =>
              l10n.postUnfavoriteFailed(items.elementAt(index).id)
        : (items, index) =>
              l10n.postFavoriteFailed(items.elementAt(index).id),
    onCancel: isLiked
        ? (items, index) => l10n.postUnfavoritingCancelled
        : (items, index) => l10n.postFavoritingCancelled,
  );
}
