// SPDX-License-Identifier: AGPL-3.0

import 'package:flutter/material.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/markup/markup.dart';
import 'package:kilt/shared/shared.dart';
import 'package:kilt/tag/tag.dart';
import 'package:kilt/wiki/wiki.dart';

class WikiPage extends StatelessWidget {
  const WikiPage({super.key, required this.wiki});

  final Wiki wiki;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AdaptiveScaffold(
      appBar: DefaultAppBar(
        title: Text(tagToName(wiki.title)),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: l10n.commonInfo,
            onPressed: () => wikiPrompt(context, wiki),
          ),
        ],
      ),
      body: ListView(
        primary: true,
        padding: defaultActionListPadding.add(
          const EdgeInsets.symmetric(horizontal: 12),
        ),
        children: [DText(wiki.body)],
      ),
    );
  }
}
