// SPDX-License-Identifier: AGPL-3.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kilt/client/client.dart';
import 'package:kilt/shared/shared.dart';
import 'package:kilt/tag/tag.dart';

class TagGesture extends StatelessWidget {
  const TagGesture({
    super.key,
    required this.child,
    required this.tag,
    this.safe = true,
    this.wiki = false,
  });

  final bool safe;
  final bool wiki;
  final String tag;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    void sheet() => showTagSearchPrompt(context: context, tag: tag);

    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () async {
        final traits = context.read<Client>().traits.value;
        if (wiki || (safe && traits.denylist.contains(tag))) {
          sheet();
        } else {
          context.go('/search?tags=${Uri.encodeComponent(tag)}');
        }
      },
      onLongPress: sheet,
      onSecondaryTap: sheet,
      child: child,
    );
  }
}
