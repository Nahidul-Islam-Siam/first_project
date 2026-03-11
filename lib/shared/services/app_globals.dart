import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin localNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
bool localNotificationsInitialized = false;
const int sehriNotificationId = 1001;
const int iftarNotificationId = 1002;
const int fajrNotificationId = 2001;
const int dzuhrNotificationId = 2002;
const int ashrNotificationId = 2003;
const int maghribNotificationId = 2004;
const int ishaNotificationId = 2005;

enum AppLanguage { english, bangla }

enum AppAlertTone { appDefault, alarmLike, adhan, silent }

enum AppFontSize { small, medium, large }

double appFontScale(AppFontSize size) {
  switch (size) {
    case AppFontSize.small:
      return 0.92;
    case AppFontSize.medium:
      return 1.0;
    case AppFontSize.large:
      return 1.1;
  }
}

String appFontSizeLabel(AppFontSize size) {
  switch (size) {
    case AppFontSize.small:
      return 'Small';
    case AppFontSize.medium:
      return 'Medium';
    case AppFontSize.large:
      return 'Large';
  }
}

final ValueNotifier<AppLanguage> appLanguageNotifier =
    ValueNotifier<AppLanguage>(AppLanguage.bangla);
final ValueNotifier<bool> useDeviceLocationNotifier = ValueNotifier<bool>(true);
final ValueNotifier<bool> prayerAlertsEnabledNotifier = ValueNotifier<bool>(
  true,
);
final ValueNotifier<bool> sehriAlertEnabledNotifier = ValueNotifier<bool>(true);
final ValueNotifier<bool> iftarAlertEnabledNotifier = ValueNotifier<bool>(true);
final ValueNotifier<AppAlertTone> alertToneNotifier =
    ValueNotifier<AppAlertTone>(AppAlertTone.appDefault);
final ValueNotifier<bool> darkThemeEnabledNotifier = ValueNotifier<bool>(false);
final ValueNotifier<AppFontSize> appFontSizeNotifier =
    ValueNotifier<AppFontSize>(AppFontSize.medium);
final ValueNotifier<String> profileNameNotifier = ValueNotifier<String>(
  'Tuafel Ahmed Zuarder',
);
final ValueNotifier<String> profileLocationNotifier = ValueNotifier<String>(
  'Dhaka, Bangladesh',
);
final ValueNotifier<String?> profilePhotoBase64Notifier =
    ValueNotifier<String?>(null);
final ValueNotifier<String?> profilePhotoUrlNotifier = ValueNotifier<String?>(
  null,
);
final ValueNotifier<bool> showLatinLettersNotifier = ValueNotifier<bool>(true);
final ValueNotifier<bool> showTranslationNotifier = ValueNotifier<bool>(true);
final ValueNotifier<String> translationLanguageNotifier = ValueNotifier<String>(
  'Bangla',
);
final ValueNotifier<bool> showTajweedNotifier = ValueNotifier<bool>(false);
final ValueNotifier<bool> hapticFeedbackEnabledNotifier = ValueNotifier<bool>(
  true,
);
final ValueNotifier<bool> skipAuthGateNotifier = ValueNotifier<bool>(false);
final ValueNotifier<String> translatorNotifier = ValueNotifier<String>(
  'Dr. Mustafa Khattab',
);
final ValueNotifier<String> reciterNotifier = ValueNotifier<String>(
  'Mishary Rashid Alafasy',
);
final ValueNotifier<String> adzanVoiceNotifier = ValueNotifier<String>(
  'Hanan Attaki',
);
final ValueNotifier<String> imsakVoiceNotifier = ValueNotifier<String>(
  'Default',
);
final ValueNotifier<bool> hifzModeEnabledNotifier = ValueNotifier<bool>(false);
final ValueNotifier<bool> hifzHideBanglaMeaningNotifier = ValueNotifier<bool>(
  false,
);
final ValueNotifier<int> hifzRepeatCountNotifier = ValueNotifier<int>(3);

const _alertToneCacheKey = 'alert_tone_preference_v1';
const _appPreferencesCacheKey = 'app_preferences_v1';
const _appPreferencesSchemaVersion = 3;
final BaseCacheManager _settingsCache = DefaultCacheManager();

bool _applyLegacyBanglaMigration(Map<dynamic, dynamic> json) {
  final storedLanguage = (json['language'] ?? '').toString().trim();
  final storedTranslation = (json['translationLanguage'] ?? '')
      .toString()
      .trim();
  final storedLocation = (json['profileLocation'] ?? '').toString().trim();

  var changed = false;

  final looksLegacyLanguage =
      storedLanguage.isEmpty || storedLanguage.toLowerCase() == 'english';
  if (looksLegacyLanguage && appLanguageNotifier.value != AppLanguage.bangla) {
    appLanguageNotifier.value = AppLanguage.bangla;
    changed = true;
  }

  final looksLegacyTranslation =
      storedTranslation.isEmpty || storedTranslation.toLowerCase() == 'english';
  if (looksLegacyTranslation && translationLanguageNotifier.value != 'Bangla') {
    translationLanguageNotifier.value = 'Bangla';
    changed = true;
  }

  final looksLegacyLocation =
      storedLocation.isEmpty || storedLocation == 'Sylhet, Bangladesh';
  if (looksLegacyLocation &&
      profileLocationNotifier.value != 'Dhaka, Bangladesh') {
    profileLocationNotifier.value = 'Dhaka, Bangladesh';
    changed = true;
  }

  return changed;
}

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

String channelIdForTone(String baseChannelId, {AppAlertTone? tone}) {
  final resolvedTone = tone ?? alertToneNotifier.value;
  return '${baseChannelId}_${alertToneChannelSuffix(resolvedTone)}';
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
  await _configureLocalTimeZone();

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();

  await localNotificationsPlugin.initialize(
    const InitializationSettings(android: androidSettings, iOS: iosSettings),
  );
  localNotificationsInitialized = true;

  await loadAlertTonePreference();
  await ensureNotificationPermissions();
  await ensureExactAlarmPermissions();
}

Future<void> _configureLocalTimeZone() async {
  try {
    final timezoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneName));
  } catch (_) {
    // Keep app usable even if timezone lookup fails on a specific device.
    tz.setLocalLocation(tz.getLocation('UTC'));
  }
}

Future<void> loadAppPreferences() async {
  final cached = await _settingsCache.getFileFromCache(_appPreferencesCacheKey);
  if (cached == null || !await cached.file.exists()) return;

  try {
    final json = jsonDecode(await cached.file.readAsString());
    if (json is! Map) return;

    final schemaVersion = (json['schema_version'] as num?)?.toInt() ?? 1;
    final language = (json['language'] ?? '').toString();
    appLanguageNotifier.value = language == 'bangla'
        ? AppLanguage.bangla
        : AppLanguage.english;

    final darkTheme = json['darkTheme'];
    if (darkTheme is bool) {
      darkThemeEnabledNotifier.value = darkTheme;
    }

    final fontSize = (json['fontSize'] ?? '').toString();
    switch (fontSize) {
      case 'small':
        appFontSizeNotifier.value = AppFontSize.small;
        break;
      case 'large':
        appFontSizeNotifier.value = AppFontSize.large;
        break;
      default:
        appFontSizeNotifier.value = AppFontSize.medium;
        break;
    }

    final useDeviceLocation = json['useDeviceLocation'];
    if (useDeviceLocation is bool) {
      useDeviceLocationNotifier.value = useDeviceLocation;
    }

    final prayerAlerts = json['prayerAlerts'];
    if (prayerAlerts is bool) {
      prayerAlertsEnabledNotifier.value = prayerAlerts;
    }

    final sehriAlert = json['sehriAlert'];
    if (sehriAlert is bool) {
      sehriAlertEnabledNotifier.value = sehriAlert;
    }

    final iftarAlert = json['iftarAlert'];
    if (iftarAlert is bool) {
      iftarAlertEnabledNotifier.value = iftarAlert;
    }

    final profileName = (json['profileName'] ?? '').toString().trim();
    if (profileName.isNotEmpty) {
      profileNameNotifier.value = profileName;
    }

    final profileLocation = (json['profileLocation'] ?? '').toString().trim();
    if (profileLocation.isNotEmpty) {
      profileLocationNotifier.value = profileLocation;
    }

    final profilePhoto = (json['profilePhoto'] ?? '').toString().trim();
    profilePhotoBase64Notifier.value = profilePhoto.isEmpty
        ? null
        : profilePhoto;
    final profilePhotoUrl = (json['profilePhotoUrl'] ?? '').toString().trim();
    profilePhotoUrlNotifier.value = profilePhotoUrl.isEmpty
        ? null
        : profilePhotoUrl;

    final showLatin = json['showLatinLetters'];
    if (showLatin is bool) {
      showLatinLettersNotifier.value = showLatin;
    }

    final showTranslation = json['showTranslation'];
    if (showTranslation is bool) {
      showTranslationNotifier.value = showTranslation;
    }

    final translationLanguage = (json['translationLanguage'] ?? '')
        .toString()
        .trim();
    if (translationLanguage.isNotEmpty) {
      translationLanguageNotifier.value = translationLanguage;
    }

    final showTajweed = json['showTajweed'];
    if (showTajweed is bool) {
      showTajweedNotifier.value = showTajweed;
    }

    final hapticFeedback = json['hapticFeedback'];
    if (hapticFeedback is bool) {
      hapticFeedbackEnabledNotifier.value = hapticFeedback;
    }

    final skipAuthGate = json['skipAuthGate'];
    if (skipAuthGate is bool) {
      skipAuthGateNotifier.value = skipAuthGate;
    }

    final translator = (json['translator'] ?? '').toString().trim();
    if (translator.isNotEmpty) {
      translatorNotifier.value = translator;
    }

    final reciter = (json['reciter'] ?? '').toString().trim();
    if (reciter.isNotEmpty) {
      reciterNotifier.value = reciter;
    }

    final adzanVoice = (json['adzanVoice'] ?? '').toString().trim();
    if (adzanVoice.isNotEmpty) {
      adzanVoiceNotifier.value = adzanVoice;
    }

    final imsakVoice = (json['imsakVoice'] ?? '').toString().trim();
    if (imsakVoice.isNotEmpty) {
      imsakVoiceNotifier.value = imsakVoice;
    }

    final hifzModeEnabled = json['hifzModeEnabled'];
    if (hifzModeEnabled is bool) {
      hifzModeEnabledNotifier.value = hifzModeEnabled;
    }

    final hifzHideBanglaMeaning = json['hifzHideBanglaMeaning'];
    if (hifzHideBanglaMeaning is bool) {
      hifzHideBanglaMeaningNotifier.value = hifzHideBanglaMeaning;
    }

    final hifzRepeatCount = (json['hifzRepeatCount'] as num?)?.toInt();
    if (hifzRepeatCount != null && [1, 3, 5, 10].contains(hifzRepeatCount)) {
      hifzRepeatCountNotifier.value = hifzRepeatCount;
    }

    if (schemaVersion < _appPreferencesSchemaVersion) {
      final changed = _applyLegacyBanglaMigration(json);
      if (changed) {
        await saveAppPreferences();
      }
    }
  } catch (_) {
    // Ignore corrupted local preferences and keep defaults.
  }
}

Future<void> saveAppPreferences() async {
  final payload = jsonEncode({
    'schema_version': _appPreferencesSchemaVersion,
    'language': appLanguageNotifier.value.name,
    'darkTheme': darkThemeEnabledNotifier.value,
    'fontSize': appFontSizeNotifier.value.name,
    'useDeviceLocation': useDeviceLocationNotifier.value,
    'prayerAlerts': prayerAlertsEnabledNotifier.value,
    'sehriAlert': sehriAlertEnabledNotifier.value,
    'iftarAlert': iftarAlertEnabledNotifier.value,
    'profileName': profileNameNotifier.value,
    'profileLocation': profileLocationNotifier.value,
    'profilePhoto': profilePhotoBase64Notifier.value ?? '',
    'profilePhotoUrl': profilePhotoUrlNotifier.value ?? '',
    'showLatinLetters': showLatinLettersNotifier.value,
    'showTranslation': showTranslationNotifier.value,
    'translationLanguage': translationLanguageNotifier.value,
    'showTajweed': showTajweedNotifier.value,
    'hapticFeedback': hapticFeedbackEnabledNotifier.value,
    'skipAuthGate': skipAuthGateNotifier.value,
    'translator': translatorNotifier.value,
    'reciter': reciterNotifier.value,
    'adzanVoice': adzanVoiceNotifier.value,
    'imsakVoice': imsakVoiceNotifier.value,
    'hifzModeEnabled': hifzModeEnabledNotifier.value,
    'hifzHideBanglaMeaning': hifzHideBanglaMeaningNotifier.value,
    'hifzRepeatCount': hifzRepeatCountNotifier.value,
  });

  await _settingsCache.putFile(
    _appPreferencesCacheKey,
    Uint8List.fromList(utf8.encode(payload)),
    key: _appPreferencesCacheKey,
    fileExtension: 'json',
  );
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

Future<bool> ensureExactAlarmPermissions() async {
  final android = localNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  if (android == null) return true;

  final canScheduleExact = await android.canScheduleExactNotifications();
  if (canScheduleExact == true) return true;

  final requested = await android.requestExactAlarmsPermission();
  return requested ?? false;
}
