import 'dart:async';

import 'package:kilt/app/app.dart';
import 'package:kilt/settings/settings.dart';
import 'package:kilt/shared/shared.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sub/flutter_sub.dart';

typedef _AppInitData = ({Logs logs, AppStorage storage, VoidCallback dispose});

bool _backgroundTasksScheduled = false;

class AppInit extends StatefulWidget {
  const AppInit({super.key, required this.child});

  final Widget child;

  static AppInitState of(BuildContext context) =>
      context.findAncestorStateOfType<AppInitState>()!;
  static AppInitState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<AppInitState>();

  @override
  State<AppInit> createState() => AppInitState();
}

class AppInitState extends State<AppInit> {
  Key _key = UniqueKey();

  void reinitialize() => setState(() => _key = UniqueKey());

  Future<_AppInitData> _init() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await DateFormatting.ensureInitialized();
    await initializeAppInfo();
    final logs = await initializeLogger();
    final storage = await initializeAppStorage();
    VideoService.ensureInitialized();
    return (
      logs: logs,
      storage: storage,
      dispose: () {
        logs.close();
        storage.close();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SubFuture<_AppInitData>(
      create: _init,
      keys: [_key],
      dispose: (future) => future.then((data) => data.dispose()).ignore(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CupertinoApp(
            key: const Key('loading'),
            theme: AppTheme.dark.cupertino,
            home: Theme(
              data: AppTheme.dark.data,
              child: _LoadingScaffold(snapshot: snapshot),
            ),
          );
        }

        final (:logs, :storage, dispose: _) = snapshot.data!;
        if (!_backgroundTasksScheduled) {
          _backgroundTasksScheduled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            initializeBackgroundTasks();
          });
        }
        return MultiProvider(
          providers: [
            Provider.value(value: logs),
            Provider.value(value: storage),
          ],
          child: widget.child,
        );
      },
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold({required this.snapshot});

  final AsyncSnapshot<_AppInitData> snapshot;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Center(
        child: DefaultTextStyle.merge(
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppIcon(radius: 64),
              if (snapshot.error != null) ...[
                const SizedBox(height: 16),
                const Text('Failed to initialize'),
                if (kDebugMode) ...[
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString()),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
