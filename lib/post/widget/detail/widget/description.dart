// SPDX-License-Identifier: AGPL-3.0

import 'package:flutter/material.dart';
import 'package:kilt/markup/markup.dart';
import 'package:kilt/post/post.dart';
import 'package:kilt/shared/shared.dart';

class DescriptionDisplay extends StatelessWidget {
  const DescriptionDisplay({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final desc = post.description.trim();
    if (desc.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: GlassCard(
              child: DText(desc),
            ),
          ),
        ],
      ),
    );
  }
}
