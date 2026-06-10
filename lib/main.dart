import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kilt/app/app.dart';
import 'package:kilt/router.dart';

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
