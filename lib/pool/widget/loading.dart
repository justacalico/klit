// SPDX-License-Identifier: AGPL-3.0

import 'package:flutter/material.dart';
import 'package:kilt/client/client.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/pool/pool.dart';
import 'package:kilt/shared/shared.dart';

class PoolLoadingPage extends StatefulWidget {
  const PoolLoadingPage(this.id, {super.key, this.orderByOldest});

  final int id;
  final bool? orderByOldest;

  @override
  State<PoolLoadingPage> createState() => _PoolLoadingPageState();
}

class _PoolLoadingPageState extends State<PoolLoadingPage> {
  late Future<Pool> pool = context.read<Client>().pools.get(id: widget.id);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureLoadingPage<Pool>(
      future: pool,
      builder: (context, value) =>
          PoolPage(pool: value, orderByOldest: widget.orderByOldest),
      title: Text(l10n.poolPoolTitle(widget.id)),
      onError: Text(l10n.poolFailedLoadOne),
      onEmpty: Text(l10n.poolNotFound),
    );
  }
}
