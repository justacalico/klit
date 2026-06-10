import 'package:kilt/client/client.dart';
import 'package:kilt/flag/flag.dart';
import 'package:kilt/markup/markup.dart';
import 'package:kilt/post/post.dart';
import 'package:kilt/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sub/flutter_sub.dart';

class DeletionDisplay extends StatelessWidget {
  const DeletionDisplay({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    if (!post.isDeleted) return const SizedBox.shrink();
    return SubFuture<PostFlag>(
      create: () => context
          .read<Client>()
          .flags
          .list(
            limit: 1,
            query: {
              'type': 'deletion',
              'search[post_id]': post.id,
              'search[is_resolved]': false,
            }.toQuery(),
          )
          .then((e) => e.first),
      builder: (context, value) => HiddenWidget(
        show: value.data != null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text('Deletion', style: TextStyle(fontSize: 16)),
            ),
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Theme.of(
                      context,
                    ).colorScheme.errorContainer.withAlpha(150),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: DText(value.data?.reason ?? ''),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }
}
