// SPDX-License-Identifier: AGPL-3.0

import 'package:flutter/widgets.dart';
import 'package:kilt/logs/logs.dart';

class RouteLoggerObserver extends NavigatorObserver {
  final Logger logger = Logger('Routes');

  void logRoute(Route<dynamic>? route, String action) {
    if (route == null) return;
    final name = route.settings.name;
    if (name == null) return;
    logger.fine('$name $action');
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    logRoute(route, 'was pushed');
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    logRoute(route, 'was removed');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    logRoute(oldRoute, 'was replaced');
    logRoute(newRoute, 'has replaced');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    logRoute(route, 'was popped');
  }
}
