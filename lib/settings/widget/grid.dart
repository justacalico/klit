// SPDX-License-Identifier: AGPL-3.0

import 'package:kilt/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';

extension GridQuiltDescription on GridQuilt {
  String description(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case GridQuilt.square:
        return l10n.settingsQuiltQuadratic;
      case GridQuilt.vertical:
        return l10n.settingsQuiltExpand;
    }
  }

  IconData get icon {
    switch (this) {
      case GridQuilt.square:
        return Icons.view_module;
      case GridQuilt.vertical:
        return Icons.view_column;
    }
  }
}

class GridSettingsTile extends StatelessWidget {
  const GridSettingsTile({super.key, required this.state, this.onChange});

  final GridQuilt state;
  final void Function(GridQuilt state)? onChange;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      title: Text(l10n.settingsQuilt),
      subtitle: Text(state.description(context)),
      leading: Icon(state.icon),
      onTap: () => showDialog(
        context: context,
        builder: (context) => SimpleDialog(
          title: Text(l10n.settingsGrid),
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: GridQuilt.values
                  .map(
                    (state) => ListTile(
                      trailing: Icon(state.icon),
                      title: Text(state.description(context)),
                      onTap: () {
                        onChange!(state);
                        Navigator.of(context).maybePop();
                      },
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
