// SPDX-License-Identifier: AGPL-3.0

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:go_router/go_router.dart';
import 'package:kilt/app/routing/app_routes.dart';
import 'package:kilt/client/client.dart';
import 'package:kilt/finish/finish.dart';
import 'package:kilt/post/post.dart';
import 'package:kilt/settings/settings.dart';
import 'package:kilt/shared/shared.dart';
import 'package:photo_view/photo_view.dart';

class FinishesPage extends StatelessWidget {
  const FinishesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final client = context.watch<Client>();
    final settings = context.watch<Settings>();
    final enabled = settings.iFinishedEnabled.value;
    return AdaptiveScaffold(
      appBar: AppBar(
        title: const Text('Finishes'),
      ),
      body: !enabled
          ? _EmptyState(
              message: 'Turn on I Finished in Settings',
              onTap: () => context.go(AppRoutes.settings),
            )
          : StreamBuilder<List<Finish>>(
              stream: client.finishes.watchForIdentity(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }
                final list = snapshot.data ?? [];
                if (list.isEmpty) {
                  return const _EmptyState(
                    message: 'No finished posts yet',
                  );
                }
                return _FinishesList(
                  finishes: list,
                  onDelete: (id) =>
                      client.finishes.deleteById(id),
                );
              },
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, this.onTap});

  final String message;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (onTap != null) ...[
              const SizedBox(height: 16),
              CupertinoButton.filled(
                onPressed: onTap,
                child: const Text('Open Settings'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FinishesList extends StatelessWidget {
  const _FinishesList({
    required this.finishes,
    required this.onDelete,
  });

  final List<Finish> finishes;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) {
    return TileLayout(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = TileLayout.of(context);
          final crossAxisCount = (layout.crossAxisCount * 0.5).round().clamp(1, 8);
          return GridView.builder(
            padding: defaultListPadding,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 0.9,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: finishes.length,
            itemBuilder: (context, index) {
              final finish = finishes[index];
              return _FinishTile(
                finish: finish,
                onDelete: () => onDelete(finish.id),
              );
            },
          );
        },
      ),
    );
  }
}

class _FinishTile extends StatelessWidget {
  const _FinishTile({
    required this.finish,
    required this.onDelete,
  });

  final Finish finish;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Post?>(
      future: context.read<Client>().posts.get(id: finish.postId),
      builder: (context, postSnapshot) {
        final post = postSnapshot.data;
        final postThumb = post?.sample ?? post?.preview;
        final hasFinishPhoto = finish.photoPath != null &&
            File(finish.photoPath!).existsSync();
        return Material(
          type: MaterialType.transparency,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildPostImage(context, postThumb),
                      ),
                      if (hasFinishPhoto) ...[
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildFinishPhoto(context, finish.photoPath!),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _openPost(context),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                post != null
                                    ? 'Post #${post.id}'
                                    : 'Post #${finish.postId}',
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              Text(
                                _formatDate(finish.finishedAt),
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: onDelete,
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openPost(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PostLoadingPage(finish.postId),
      ),
    );
  }

  void _openFinishPhoto(BuildContext context, String path) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _FinishPhotoViewer(path: path),
      ),
    );
  }

  Widget _buildPostImage(BuildContext context, String? postThumb) {
    void openPost() => _openPost(context);
    if (postThumb == null) {
      return GestureDetector(
        onTap: openPost,
        child: ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Center(
            child: Icon(Icons.image_not_supported, size: 40),
          ),
        ),
      );
    }
    final parsed = Uri.tryParse(postThumb);
    final imageUrl = (parsed?.hasScheme ?? false)
        ? postThumb
        : context.read<Client>().withHost(postThumb);
    return GestureDetector(
      onTap: openPost,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          cacheManager: context.read<BaseCacheManager>(),
          errorWidget: (context, url, error) => ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Center(
              child: Icon(Icons.image_not_supported, size: 40),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinishPhoto(BuildContext context, String path) {
    return GestureDetector(
      onTap: () => _openFinishPhoto(context, path),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.file(
          File(path),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    if (day == today) {
      return 'Today ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

class _FinishPhotoViewer extends StatelessWidget {
  const _FinishPhotoViewer({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: PhotoView.customChild(
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 4,
        initialScale: PhotoViewComputedScale.contained,
        child: Image.file(File(path)),
      ),
    );
  }
}
