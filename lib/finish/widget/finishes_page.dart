import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:klit/app/routes/app_routes.dart';
import 'package:klit/shared/shared.dart';
import 'package:klit/client/client.dart';
import 'package:klit/finish/finish.dart';
import 'package:klit/post/post.dart';
import 'package:klit/settings/settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
              onTap: () => Get.toNamed(AppRoutes.settings),
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
    return ListView.builder(
      padding: defaultActionListPadding,
      itemCount: finishes.length,
      itemBuilder: (context, index) {
        final finish = finishes[index];
        return _FinishTile(
          finish: finish,
          onDelete: () => onDelete(finish.id),
        );
      },
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
        return ListTile(
          leading: _buildLeading(context),
          title: Text(
            post != null
                ? 'Post #${post.id}'
                : 'Post #${finish.postId}',
          ),
          subtitle: Text(
            _formatDate(finish.finishedAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => PostLoadingPage(finish.postId),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLeading(BuildContext context) {
    return FutureBuilder<Post?>(
      future: context.read<Client>().posts.get(id: finish.postId),
      builder: (context, snapshot) {
        final post = snapshot.data;
        final postThumb = post?.sample ?? post?.preview;
        return SizedBox(
          width: 56,
          height: 56,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (postThumb != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: context.read<Client>().withHost(postThumb),
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                )
              else
                const Icon(Icons.image_not_supported, size: 40),
              if (finish.photoPath != null && File(finish.photoPath!).existsSync()) ...[
                const SizedBox(width: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.file(
                    File(finish.photoPath!),
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
          ),
        );
      },
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
