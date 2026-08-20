// SPDX-License-Identifier: AGPL-3.0

import 'package:flutter/material.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/logs/logs.dart';
import 'package:kilt/shared/shared.dart';
import 'package:recase/recase.dart';

class LogRecordDrawer extends StatelessWidget {
  const LogRecordDrawer({
    super.key,
    required this.levels,
    required this.onChanged,
  });

  final List<int> levels;
  final ValueSetter<List<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const filters = <Level>[
      Level.FINE,
      Level.INFO,
      Level.WARNING,
      Level.SEVERE,
      Level.SHOUT,
    ];

    final icons = <Level, Widget>{
      Level.FINE: const Icon(Icons.monitor_heart_outlined),
      Level.INFO: const Icon(Icons.info_outline),
      Level.WARNING: const Icon(Icons.warning_amber),
      Level.SEVERE: const Icon(Icons.report_outlined),
      Level.SHOUT: const Icon(Icons.crisis_alert),
    };

    return ContextDrawer(
      title: Text(l10n.logsLogs),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: ListTileHeader(title: l10n.logsLevels),
        ),
        for (final filter in filters)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: CheckboxListTile(
              secondary: icons[filter],
              title: Text(filter.name.pascalCase),
              value: levels.contains(filter.value),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                final levels = List<int>.of(this.levels);
                if (value) {
                  levels.add(filter.value);
                } else {
                  levels.remove(filter.value);
                }
                onChanged(levels);
              },
            ),
          ),
      ],
    );
  }
}
