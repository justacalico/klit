// SPDX-License-Identifier: AGPL-3.0

import 'package:kilt/client/client.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/shared/shared.dart';
import 'package:kilt/wiki/wiki.dart';
import 'package:flutter/material.dart';

class WikiLoadingPage extends StatefulWidget {
  const WikiLoadingPage(this.id, {super.key});

  final String id;

  @override
  State<WikiLoadingPage> createState() => _WikiLoadingPageState();
}

class _WikiLoadingPageState extends State<WikiLoadingPage> {
  late Future<Wiki> wiki = context.read<Client>().wikis.get(id: widget.id);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureLoadingPage<Wiki>(
      future: wiki,
      builder: (context, value) => WikiPage(wiki: value),
      title: Text(l10n.wikiWikiTitle(widget.id)),
      onError: Text(l10n.wikiFailedLoadOne),
      onEmpty: Text(l10n.wikiNotFound),
    );
  }
}
