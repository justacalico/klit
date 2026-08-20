// SPDX-License-Identifier: AGPL-3.0

import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/post/post.dart';
import 'package:kilt/shared/shared.dart';
import 'package:kilt/tag/tag.dart';

class FileDisplay extends StatelessWidget {
  const FileDisplay({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(l10n.postFile, style: const TextStyle(fontSize: 16)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TagGesture(
                tag: 'rating:${post.rating.name}',
                child: Text(post.rating.title(l10n)),
              ),
              Text('${post.width} x ${post.height}'),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(DateFormatting.dateTime(post.createdAt.toLocal())),
              Text(filesize(post.size, 1)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (post.updatedAt != null)
                Text(DateFormatting.dateTime(post.updatedAt!.toLocal())),
              TagGesture(tag: 'type:${post.ext}', child: Text(post.ext)),
            ],
          ),
        ),
        const Divider(),
      ],
    );
  }
}
