import 'package:kilt/app/app.dart';
import 'package:kilt/follow/follow.dart';
import 'package:kilt/logs/logs.dart';
import 'package:workmanager/workmanager.dart';

/// Handles all background tasks that the app registered.
@pragma('vm:entry-point')
void executeBackgroundTasks() =>
    Workmanager().executeTask((task, inputData) async {
      await initializeAppInfo();
      await initializeLogger(postfix: 'background');

      final logger = Logger('BackgroundTasks');
      logger.info('Executing Task $task');

      AppStorage? storage;

      try {
        storage = await initializeAppStorage(cache: false);

        final cancelToken = createBackgroundCancelToken(task);
        cancelToken.whenCancel.then((e) {
          logger.info('Task $task was cancelled: ${e.error}');
        });

        FlutterLocalNotificationsPlugin notifications =
            await initializeNotifications();

        switch (task) {
          case followsBackgroundTaskKey:
            await runFollowUpdates(
              storage: storage,
              notifications: notifications,
              cancelToken: cancelToken,
            );
          default:
            throw StateError('Task $task is unknown!');
        }

        return true;
      } on Object catch (e, stack) {
        logger.severe('Failed executing Task $task', e, stack);
        rethrow;
      } finally {
        await storage?.close();
        logger.info('Task $task completed');
      }
    });
