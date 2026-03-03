import 'package:klit/markup/markup.dart';
import 'package:klit/shared/shared.dart';
import 'package:klit/tag/tag.dart';
import 'package:klit/wiki/wiki.dart';
import 'package:flutter/material.dart';

class WikiPage extends StatelessWidget {
  const WikiPage({super.key, required this.wiki});

  final Wiki wiki;

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      appBar: DefaultAppBar(
        title: Text(tagToName(wiki.title)),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Info',
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
