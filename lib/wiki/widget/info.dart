// SPDX-License-Identifier: AGPL-3.0

import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/shared/shared.dart';
import 'package:kilt/wiki/wiki.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WikiInfo extends StatelessWidget {
  const WikiInfo({super.key, required this.wiki});

  final Wiki wiki;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget textInfoRow(String label, String value) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value)],
      );
    }

    return DefaultTextStyle(
      style: TextStyle(color: dimTextColor(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.commonId),
              InkWell(
                child: Text('#${wiki.id}'),
                onLongPress: () async {
                  ScaffoldMessengerState messenger = ScaffoldMessenger.of(
                    context,
                  );
                  Clipboard.setData(ClipboardData(text: wiki.id.toString()));
                  await Navigator.of(context).maybePop();
                  messenger.showSnackBar(
                    SnackBar(
                      duration: const Duration(seconds: 1),
                      content: Text(l10n.wikiCopiedId(wiki.id)),
                    ),
                  );
                },
              ),
            ],
          ),
          if (wiki.otherNames case final otherNames?)
            textInfoRow(l10n.wikiAlias, otherNames.join(', ')),
          textInfoRow(
            l10n.commonCreated,
            DateFormatting.dateTime(wiki.createdAt.toLocal()),
          ),
          textInfoRow(
            l10n.commonUpdated,
            DateFormatting.dateTime(
              (wiki.updatedAt ?? wiki.createdAt).toLocal(),
            ),
          ),
          if (wiki.isLocked case final isLocked?)
            textInfoRow('locked', isLocked ? l10n.commonYes : l10n.commonNo),
        ],
      ),
    );
  }
}
