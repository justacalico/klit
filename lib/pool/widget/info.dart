import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/pool/pool.dart';
import 'package:kilt/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PoolInfo extends StatelessWidget {
  const PoolInfo({super.key, required this.pool});

  final Pool pool;

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
          textInfoRow(l10n.commonPosts, pool.postIds.length.toString()),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.commonId),
              InkWell(
                child: Text('#${pool.id}'),
                onLongPress: () async {
                  ScaffoldMessengerState messenger = ScaffoldMessenger.of(
                    context,
                  );
                  Clipboard.setData(ClipboardData(text: pool.id.toString()));
                  await Navigator.of(context).maybePop();
                  messenger.showSnackBar(
                    SnackBar(
                      duration: const Duration(seconds: 1),
                      content: Text(l10n.poolCopiedId(pool.id)),
                    ),
                  );
                },
              ),
            ],
          ),
          textInfoRow(l10n.poolActivity, pool.active ? l10n.commonActive : l10n.commonInactive),
          textInfoRow(
            l10n.commonCreated,
            DateFormatting.dateTime(pool.createdAt.toLocal()),
          ),
          textInfoRow(
            l10n.commonUpdated,
            DateFormatting.dateTime(pool.updatedAt.toLocal()),
          ),
        ],
      ),
    );
  }
}
