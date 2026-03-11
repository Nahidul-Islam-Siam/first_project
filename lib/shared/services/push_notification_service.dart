import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:first_project/core/utils/network_utils.dart';
import 'package:first_project/firebase_options.dart';
import 'package:first_project/shared/services/app_globals.dart';

const String noorifyBroadcastTopic = 'noorify_all';
const String noorifyGeneralChannelId = 'noorify_general';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  bool _initialized = false;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;
  StreamSubscription<String>? _tokenRefreshSub;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _requestPermissions();
    await _configureForegroundPresentation();
    await _createAndroidChannel();
    await _setupMessageStreams();
    await _subscribeDefaultTopic();
    await _logFcmToken();
  }

  Future<void> dispose() async {
    await _foregroundSub?.cancel();
    await _openedSub?.cancel();
    await _tokenRefreshSub?.cancel();
  }

  Future<void> _requestPermissions() async {
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    } catch (e) {
      debugPrint('FCM permission request failed: $e');
    }
  }

  Future<void> _configureForegroundPresentation() async {
    try {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
    } catch (e) {
      debugPrint('FCM foreground presentation setup failed: $e');
    }
  }

  Future<void> _createAndroidChannel() async {
    final android = localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;

    try {
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          noorifyGeneralChannelId,
          'Noorify General',
          description: 'General announcements and broadcast notifications',
          importance: Importance.high,
          playSound: true,
        ),
      );
    } catch (e) {
      debugPrint('Notification channel creation failed: $e');
    }
  }

  Future<void> _setupMessageStreams() async {
    _foregroundSub?.cancel();
    _openedSub?.cancel();
    _tokenRefreshSub?.cancel();

    _foregroundSub = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
      onError: (error) {
        debugPrint('FCM foreground listener failed: $error');
      },
    );

    _openedSub = FirebaseMessaging.onMessageOpenedApp.listen(
      _handleOpenedMessage,
      onError: (error) {
        debugPrint('FCM onMessageOpenedApp failed: $error');
      },
    );

    _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen(
      (token) {
        debugPrint('FCM token refreshed: $token');
      },
      onError: (error) {
        debugPrint('FCM token refresh listener failed: $error');
      },
    );

    try {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        _handleOpenedMessage(initial);
      }
    } catch (e) {
      debugPrint('FCM getInitialMessage failed: $e');
    }
  }

  Future<void> _subscribeDefaultTopic() async {
    final online = await NetworkUtils.hasInternet();
    if (!online) {
      debugPrint('FCM topic subscribe skipped: no internet');
      return;
    }

    try {
      await FirebaseMessaging.instance.subscribeToTopic(noorifyBroadcastTopic);
      debugPrint('Subscribed to FCM topic: $noorifyBroadcastTopic');
    } catch (e) {
      debugPrint('FCM topic subscribe failed: $e');
    }
  }

  Future<void> _logFcmToken() async {
    final online = await NetworkUtils.hasInternet();
    if (!online) {
      debugPrint('FCM token fetch skipped: no internet');
      return;
    }
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        debugPrint('FCM token: $token');
      }
    } catch (e) {
      debugPrint('FCM token fetch failed: $e');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final title =
        notification?.title ??
        message.data['title']?.toString() ??
        'Noorify Notification';
    final body =
        notification?.body ??
        message.data['body']?.toString() ??
        'You have a new update.';

    final androidDetails = AndroidNotificationDetails(
      noorifyGeneralChannelId,
      'Noorify General',
      channelDescription: 'General announcements and broadcast notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    try {
      await localNotificationsPlugin.show(
        message.hashCode,
        title,
        body,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: jsonEncode(message.data),
      );
    } catch (e) {
      debugPrint('Showing foreground FCM notification failed: $e');
    }
  }

  void _handleOpenedMessage(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('FCM message opened: ${message.messageId}');
      debugPrint('FCM data: ${message.data}');
    }
  }
}

Future<void> initializePushNotifications() async {
  await PushNotificationService.instance.initialize();
}
