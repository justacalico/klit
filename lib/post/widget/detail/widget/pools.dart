// SPDX-License-Identifier: AGPL-3.0

import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/pool/pool.dart';
import 'package:kilt/post/post.dart';
import 'package:flutter/material.dart';

class PoolDisplay extends StatelessWidget {
  const PoolDisplay({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    if (post.pools?.isNotEmpty ?? false) {
      final l10n = AppLocalizations.of(context);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(l10n.postPools, style: const TextStyle(fontSize: 16)),
          ),
          ...post.pools!.map(
            (id) => ListTile(
              leading: const Icon(Icons.group),
              title: Text(id.toString()),
              trailing: const Icon(Icons.arrow_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => PoolLoadingPage(id)),
              ),
            ),
          ),
          const Divider(),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
