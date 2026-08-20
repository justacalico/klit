// SPDX-License-Identifier: AGPL-3.0

import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/post/post.dart';
import 'package:kilt/shared/shared.dart';
import 'package:kilt/ticket/ticket.dart';
import 'package:flutter/material.dart';

class SourcesEditDisplay extends StatelessWidget {
  const SourcesEditDisplay({
    super.key,
    required this.postId,
    required this.controller,
    this.enabled,
  });

  final int postId;
  final TextEditingController controller;
  final bool? enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
    padding: defaultFormPadding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(l10n.postSources, style: const TextStyle(fontSize: 16)),
            ),
            IconButton(
              onPressed: (enabled ?? true)
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => TextEditor(
                            title: Text(l10n.postEditSourcesTitle(postId)),
                            content: controller.text,
                            onSubmitted: (text) {
                              controller.text = text;
                              return null;
                            },
                            onClosed: Navigator.of(context).maybePop,
                          ),
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.edit),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder(
          valueListenable: controller,
          builder: (context, value, child) {
            final sources = value.text
                .split('\n')
                .where((s) => s.trim().isNotEmpty)
                .toList();

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(4),
              ),
              child: sources.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: sources
                          .map(
                            (source) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: SourceCard(url: source),
                            ),
                          )
                          .toList(),
                    )
                  : Text(
                      l10n.postEditNoSources,
                      style: TextStyle(
                        color: dimTextColor(context),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
            );
          },
        ),
      ],
    ),
  );
  }
}
