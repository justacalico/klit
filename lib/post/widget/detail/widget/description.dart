import 'package:klit/markup/markup.dart';
import 'package:klit/post/post.dart';
import 'package:klit/shared/shared.dart';
import 'package:flutter/material.dart';

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
              borderRadius: 16,
              padding: const EdgeInsets.all(16),
              child: DText(desc),
            ),
          ),
        ],
      ),
    );
  }
}
