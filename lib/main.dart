import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:klit/app/app.dart';
import 'package:klit/router.dart';

void main() {
  final navigatorKey = GlobalKey<NavigatorState>();
  final goRouter = createAppRouter(navigatorKey);
  runApp(
    ProviderScope(
      child: App(
        navigatorKey: navigatorKey,
        goRouter: goRouter,
      ),
    ),
  );
}
