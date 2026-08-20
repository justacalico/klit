// SPDX-License-Identifier: AGPL-3.0

import 'package:flutter/material.dart';
import 'package:kilt/logs/logs.dart';
import 'package:kilt/shared/shared.dart';

class ErrorNotifier extends StatelessWidget {
  const ErrorNotifier({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    final logs = context.watch<Logs?>();
    if (logs == null) return child;
    return LoggerErrorNotifier(
      logs: logs,
      onOpenLogs: () => navigatorKey.currentState!.push(
        MaterialPageRoute(builder: (context) => const LogsPage()),
      ),
      child: child,
    );
  }
}
