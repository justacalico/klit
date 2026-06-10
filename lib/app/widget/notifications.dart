import 'dart:async';
import 'dart:convert';

import 'package:kilt/app/app.dart';
import 'package:kilt/client/client.dart';
import 'package:kilt/follow/follow.dart';
import 'package:kilt/logs/logs.dart';
import 'package:kilt/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sub/flutter_sub.dart';
import 'package:go_router/go_router.dart';

class NotificationHandler extends StatefulWidget {
  const NotificationHandler({
    super.key,
    required this.child,
    required this.navigatorKey,
    required this.goRouter,
  });

  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;
  final GoRouter goRouter;

  @override
  State<NotificationHandler> createState() => _NotificationHandlerState();
}

class _NotificationHandlerState extends State<NotificationHandler> {
  Future<FlutterLocalNotificationsPlugin>? _notifications;
  List<Follow>? previousFollows;
  Logger logger = Logger('Notifications');

  @override
  void initState() {
    super.initState();
    if (PlatformCapabilities.hasNotifications) {
      _notifications =
          initializeNotifications(onDidReceiveNotificationResponse: handle);
    }
    initialize();
  }

  Future<void> initialize() async {
    if (!PlatformCapabilities.hasNotifications || _notifications == null) return;
    NotificationAppLaunchDetails? details =
        await (await _notifications!).getNotificationAppLaunchDetails();
    if (details != null && details.didNotificationLaunchApp) {
      NotificationResponse? response = details.notificationResponse;
      if (response != null) {
        handle(response);
      }
    }
  }

  Future<void> setupFollowBackground(List<Follow> follows) async {
    if (!PlatformCapabilities.hasNotifications) return;
    bool wasNotifying =
        previousFollows != null &&
        previousFollows!.where((e) => e.type == FollowType.notify).isNotEmpty;
    bool isNotifying = follows
        .where((e) => e.type == FollowType.notify)
        .isNotEmpty;
    if (wasNotifying == isNotifying) return;

    if (isNotifying && _notifications != null) {
      bool? result;
      result = await (await _notifications!)
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      result = await (await _notifications!)
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      if (!(result ?? true)) return;
    }
    registerFollowBackgroundTask(follows);
  }

  Future<void> sendNotifications(List<Follow> follows, int identity) async {
    if (!PlatformCapabilities.hasNotifications || _notifications == null) return;
    if (previousFollows != null) {
      await updateFollowNotifications(
        identity: identity,
        previous: previousFollows!,
        updated: follows,
        notifications: await _notifications!,
      );
    }
  }

  Future<void> handle(NotificationResponse response) async {
    if (!context.mounted) return;
    String? payload = response.payload;
    if (payload == null) return;
    NotificationPayload? notification;
    try {
      notification = NotificationPayload.fromJson(json.decode(payload));
    } on FormatException catch (e, s) {
      logger.severe('Failed to parse notification payload', e, s);
      return;
    }

    switch (notification.type) {
      case 'follow':
        widget.goRouter.go('/');
        if (notification.query != null) {
          final tags = notification.query!['tags'] ?? '';
          widget.goRouter.go('/search?tags=${Uri.encodeComponent(tags)}');
        }
        if (notification.id != null) {
          widget.goRouter.push('/post/${notification.id}');
        }
        break;
      default:
        logger.warning('Unknown notification type: ${notification.type}');
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = context.watch<Client>();
    return SubStream<List<Follow>>(
      create: () => client.follows
          .all(query: FollowsQuery(types: [FollowType.notify]))
          .streamed,
      keys: [client],
      listener: (event) async {
        await Future.wait([
          setupFollowBackground(event),
          sendNotifications(event, client.identity.id),
        ]);
        previousFollows = event;
      },
      builder: (context, stream) => widget.child,
    );
  }
}
