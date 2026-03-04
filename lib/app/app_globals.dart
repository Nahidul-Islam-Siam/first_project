import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;

final FlutterLocalNotificationsPlugin localNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
const int sehriNotificationId = 1001;
const int iftarNotificationId = 1002;
const int fajrNotificationId = 2001;
const int dzuhrNotificationId = 2002;
const int ashrNotificationId = 2003;
const int maghribNotificationId = 2004;
const int ishaNotificationId = 2005;

enum AppLanguage { english, bangla }

enum AppAlertTone { appDefault, alarmLike, adhan, silent }

final ValueNotifier<AppLanguage> appLanguageNotifier =
    ValueNotifier<AppLanguage>(AppLanguage.english);
final ValueNotifier<bool> useDeviceLocationNotifier = ValueNotifier<bool>(true);
final ValueNotifier<bool> prayerAlertsEnabledNotifier = ValueNotifier<bool>(
  true,
);
final ValueNotifier<bool> sehriAlertEnabledNotifier = ValueNotifier<bool>(true);
final ValueNotifier<bool> iftarAlertEnabledNotifier = ValueNotifier<bool>(true);
final ValueNotifier<AppAlertTone> alertToneNotifier =
    ValueNotifier<AppAlertTone>(AppAlertTone.appDefault);

const _alertToneCacheKey = 'alert_tone_preference_v1';
final BaseCacheManager _settingsCache = DefaultCacheManager();

String alertToneLabel(AppAlertTone tone) {
  switch (tone) {
    case AppAlertTone.appDefault:
      return 'App Default';
    case AppAlertTone.alarmLike:
      return 'Alarm Style';
    case AppAlertTone.adhan:
      return 'Adhan (MP3)';
    case AppAlertTone.silent:
      return 'Silent';
  }
}

String alertToneChannelSuffix(AppAlertTone tone) {
  switch (tone) {
    case AppAlertTone.appDefault:
      return 'default';
    case AppAlertTone.alarmLike:
      return 'alarm';
    case AppAlertTone.adhan:
      return 'adhan';
    case AppAlertTone.silent:
      return 'silent';
  }
}

String channelIdForTone(String baseChannelId) {
  return '${baseChannelId}_${alertToneChannelSuffix(alertToneNotifier.value)}';
}

AndroidNotificationSound? alertToneSound(AppAlertTone tone) {
  switch (tone) {
    case AppAlertTone.appDefault:
      return null;
    case AppAlertTone.alarmLike:
      return const UriAndroidNotificationSound(
        'content://settings/system/alarm_alert',
      );
    case AppAlertTone.adhan:
      return const RawResourceAndroidNotificationSound('adhan_alert');
    case AppAlertTone.silent:
      return null;
  }
}

AudioAttributesUsage alertToneUsage(AppAlertTone tone) {
  return tone == AppAlertTone.alarmLike || tone == AppAlertTone.adhan
      ? AudioAttributesUsage.alarm
      : AudioAttributesUsage.notification;
}

bool alertTonePlaySound(AppAlertTone tone) {
  return tone != AppAlertTone.silent;
}

Future<void> initializeNotifications() async {
  tz_data.initializeTimeZones();

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();

  await localNotificationsPlugin.initialize(
    const InitializationSettings(android: androidSettings, iOS: iosSettings),
  );

  await loadAlertTonePreference();
  await ensureNotificationPermissions();
}

Future<void> loadAlertTonePreference() async {
  final cached = await _settingsCache.getFileFromCache(_alertToneCacheKey);
  if (cached == null || !await cached.file.exists()) return;

  try {
    final json = jsonDecode(await cached.file.readAsString());
    if (json is! Map) return;
    final stored = (json['tone'] ?? '').toString();
    switch (stored) {
      case 'alarm':
        alertToneNotifier.value = AppAlertTone.alarmLike;
        break;
      case 'adhan':
        alertToneNotifier.value = AppAlertTone.adhan;
        break;
      case 'silent':
        alertToneNotifier.value = AppAlertTone.silent;
        break;
      default:
        alertToneNotifier.value = AppAlertTone.appDefault;
        break;
    }
  } catch (_) {
    // Ignore corrupted local preference and keep default tone.
  }
}

Future<void> saveAlertTonePreference(AppAlertTone tone) async {
  String value;
  switch (tone) {
    case AppAlertTone.appDefault:
      value = 'default';
      break;
    case AppAlertTone.alarmLike:
      value = 'alarm';
      break;
    case AppAlertTone.adhan:
      value = 'adhan';
      break;
    case AppAlertTone.silent:
      value = 'silent';
      break;
  }

  final payload = jsonEncode({'tone': value});
  await _settingsCache.putFile(
    _alertToneCacheKey,
    Uint8List.fromList(utf8.encode(payload)),
    key: _alertToneCacheKey,
    fileExtension: 'json',
  );
}

Future<bool> ensureNotificationPermissions() async {
  final androidGranted =
      await localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission() ??
      true;
  final iosGranted =
      await localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true) ??
      true;
  return androidGranted && iosGranted;
}
