import 'dart:async';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:ponjika/ponjika.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/core/constants/route_names.dart';
import 'package:first_project/features/quran/models/quran_models.dart';
import 'package:first_project/features/quran/services/quran_api_service.dart';
import 'package:first_project/features/quran/services/quran_last_read_service.dart';
import 'package:first_project/features/quran/screens/surah_detail_screen.dart';
import 'package:first_project/shared/widgets/bottom_nav.dart';
import 'package:first_project/features/home/models/home_activity_models.dart';
import 'package:first_project/features/home/widgets/home_activity_widgets.dart';

class DailyActivityScreen extends StatefulWidget {
  const DailyActivityScreen({super.key});

  @override
  State<DailyActivityScreen> createState() => _DailyActivityScreenState();
}

class _DailyActivityScreenState extends State<DailyActivityScreen> {
  static const _baitulMukarramLat = 23.7286;
  static const _baitulMukarramLng = 90.4106;
  static const _baitulMukarramLabel = 'Baitul Mukarram, Dhaka';
  static const _headerHeight = 330.0;
  static const _apiMethod = 1; // University of Islamic Sciences, Karachi
  static const _apiSchool = 1; // Hanafi

  late final Timer _clockTimer;
  DateTime _now = DateTime.now();
  double? _latitude;
  double? _longitude;
  bool _isFetchingPrayerSchedule = false;
  bool _ignoreNextLocationToggleChange = false;
  DailyPrayerSchedule? _todaySchedule;
  DailyPrayerSchedule? _tomorrowSchedule;
  DateTime? _lastPrayerCalcDate;
  DateTime? _nextSehriAt;
  DateTime? _nextIftarAt;
  bool _isRefreshingLocation = false;
  String _locationLabel = 'Detecting location...';
  String _countdownLabel = 'Calculating prayer...';
  String _activePrayer = 'Dzuhr';
  Duration _activeRemaining = Duration.zero;
  double _activeProgress = 0.0;
  Map<String, String> _prayerTimes = const {
    'Fajr': '--:--',
    'Dzuhr': '--:--',
    'Ashr': '--:--',
    'Maghrib': '--:--',
    'Isha': '--:--',
  };

  int _completedDaily = 3;
  final int _dailyGoal = 6;
  final List<String> _prayerOrder = const [
    'Fajr',
    'Dzuhr',
    'Ashr',
    'Maghrib',
    'Isha',
  ];
  late final PageController _prayerPageController;
  String? _selectedPrayer;
  final QuranLastReadService _lastReadService = QuranLastReadService();
  final QuranApiService _quranApiService = QuranApiService();
  final Dio _prayerApi = Dio(
    BaseOptions(
      baseUrl: 'https://api.aladhan.com',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      responseType: ResponseType.json,
    ),
  );
  int? _lastReadSurahNo;
  QuranChapter? _lastReadChapter;

  final List<ActivityItem> _activities = [
    ActivityItem(title: 'Alms', done: 4, total: 10),
    ActivityItem(title: 'Recite the Al Quran', done: 8, total: 10),
  ];

  @override
  void initState() {
    super.initState();
    _prayerPageController = PageController(
      viewportFraction: 0.23,
      initialPage: _prayerOrder.indexOf(_activePrayer),
    );
    appLanguageNotifier.addListener(_onLanguageChanged);
    useDeviceLocationNotifier.addListener(_onUseDeviceLocationChanged);
    prayerAlertsEnabledNotifier.addListener(_onPrayerAlertToggleChanged);
    sehriAlertEnabledNotifier.addListener(_onSehriAlertToggleChanged);
    iftarAlertEnabledNotifier.addListener(_onIftarAlertToggleChanged);
    alertToneNotifier.addListener(_onAlertToneChanged);
    _loadPrayerData();
    _loadLastReadCard();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _safeSetState(() => _now = DateTime.now());
      _updateCountdown();
      if (_lastPrayerCalcDate == null ||
          _lastPrayerCalcDate!.day != _now.day ||
          _lastPrayerCalcDate!.month != _now.month ||
          _lastPrayerCalcDate!.year != _now.year) {
        _recalculatePrayerTimesForToday();
      }
    });
  }

  @override
  void dispose() {
    appLanguageNotifier.removeListener(_onLanguageChanged);
    useDeviceLocationNotifier.removeListener(_onUseDeviceLocationChanged);
    prayerAlertsEnabledNotifier.removeListener(_onPrayerAlertToggleChanged);
    sehriAlertEnabledNotifier.removeListener(_onSehriAlertToggleChanged);
    iftarAlertEnabledNotifier.removeListener(_onIftarAlertToggleChanged);
    alertToneNotifier.removeListener(_onAlertToneChanged);
    _clockTimer.cancel();
    _prayerPageController.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  void _onLanguageChanged() {
    _safeSetState(() {});
  }

  Future<void> _onUseDeviceLocationChanged() async {
    if (_ignoreNextLocationToggleChange) {
      _ignoreNextLocationToggleChange = false;
      return;
    }
    await _loadPrayerData();
    _safeSetState(() {});
  }

  void _setUseDeviceLocationSilently(bool value) {
    if (useDeviceLocationNotifier.value == value) return;
    _ignoreNextLocationToggleChange = true;
    useDeviceLocationNotifier.value = value;
  }

  Future<void> _onSehriAlertToggleChanged() async {
    if (sehriAlertEnabledNotifier.value) {
      if (_nextSehriAt != null) {
        await _scheduleSehriNotification(_nextSehriAt!);
      }
    } else {
      await _cancelSehriNotification();
    }
    _safeSetState(() {});
  }

  Future<void> _onPrayerAlertToggleChanged() async {
    await _refreshPrayerAlertScheduling();
    _safeSetState(() {});
  }

  Future<void> _onIftarAlertToggleChanged() async {
    if (iftarAlertEnabledNotifier.value) {
      if (_nextIftarAt != null) {
        await _scheduleIftarNotification(_nextIftarAt!);
      }
    } else {
      await _cancelIftarNotification();
    }
    _safeSetState(() {});
  }

  void _onAlertToneChanged() {
    unawaited(_refreshAllAlertSchedulesForToneChange());
    _safeSetState(() {});
  }

  Future<void> _refreshAllAlertSchedulesForToneChange() async {
    await _refreshPrayerAlertScheduling();
    await _refreshMealAlertScheduling();
  }

  String get _formattedTime {
    final hour12 = (_now.hour % 12 == 0) ? 12 : _now.hour % 12;
    final minute = _now.minute.toString().padLeft(2, '0');
    final value = '$hour12:$minute';
    return _isBangla ? _toBanglaDigits(value) : value;
  }

  String get _formattedHijriDate {
    final hijri = HijriCalendar.fromDate(_now);
    final day = hijri.hDay.toString();
    final year = hijri.hYear.toString();
    final month = hijri.longMonthName;

    if (_isBangla) {
      return '${_toBanglaDigits(day)} ${_localizedHijriMonthName(month)} ${_toBanglaDigits(year)} \u09b9\u09bf\u099c\u09b0\u09bf';
    }
    return '$day $month $year H';
  }

  String get _formattedBanglaDate {
    return Ponjika.format(date: _now, format: 'DD MM YY');
  }

  String get _formattedBritishDate {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final day = _now.day.toString().padLeft(2, '0');
    final value = '$day ${months[_now.month - 1]} ${_now.year}';
    return _isBangla ? _toBanglaDigits(value) : value;
  }

  List<String> get _headerDateVariants {
    final banglaLabel = _isBangla ? '\u09ac\u09be\u0982\u09b2\u09be' : 'Bangla';
    final hijriLabel = _isBangla ? '\u0986\u09b0\u09ac\u09bf' : 'Hijri';
    final britishLabel = _isBangla
        ? '\u0987\u0982\u09b0\u09c7\u099c\u09bf'
        : 'English (UK)';
    return [
      '$banglaLabel: $_formattedBanglaDate',
      '$hijriLabel: $_formattedHijriDate',
      '$britishLabel: $_formattedBritishDate',
    ];
  }

  String get _activeHeaderDate {
    final variants = _headerDateVariants;
    final index = (_now.millisecondsSinceEpoch ~/ 5000) % variants.length;
    return variants[index];
  }

  bool get _isBangla => appLanguageNotifier.value == AppLanguage.bangla;

  String _toBanglaDigits(String input) {
    const latin = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bangla = [
      '\u09e6',
      '\u09e7',
      '\u09e8',
      '\u09e9',
      '\u09ea',
      '\u09eb',
      '\u09ec',
      '\u09ed',
      '\u09ee',
      '\u09ef',
    ];
    var output = input;
    for (var i = 0; i < latin.length; i++) {
      output = output.replaceAll(latin[i], bangla[i]);
    }
    return output;
  }

  String _localizedPrayerName(String name) {
    if (!_isBangla) return name;
    const map = {
      'Fajr': '\u09ab\u099c\u09b0',
      'Dzuhr': '\u09af\u09cb\u09b9\u09b0',
      'Ashr': '\u0986\u09b8\u09b0',
      'Maghrib': '\u09ae\u09be\u0997\u09b0\u09bf\u09ac',
      'Isha': '\u0987\u09b6\u09be',
    };
    return map[name] ?? name;
  }

  String _localizedHijriMonthName(String name) {
    if (!_isBangla) return name;
    const monthMap = {
      'Muharram': '\u09ae\u09b9\u09b0\u09b0\u09ae',
      'Safar': '\u09b8\u09ab\u09b0',
      'Rabi\' al-awwal':
          '\u09b0\u09ac\u09bf\u0989\u09b2 \u0986\u0989\u09df\u09be\u09b2',
      'Rabi\' al-thani':
          '\u09b0\u09ac\u09bf\u0989\u09b8 \u09b8\u09be\u09a8\u09bf',
      'Jumada al-awwal':
          '\u099c\u09ae\u09be\u09a6\u09bf\u0989\u09b2 \u0986\u0989\u09df\u09be\u09b2',
      'Jumada al-thani':
          '\u099c\u09ae\u09be\u09a6\u09bf\u0989\u09b8 \u09b8\u09be\u09a8\u09bf',
      'Rajab': '\u09b0\u099c\u09ac',
      'Sha\'ban': '\u09b6\u09be\u09ac\u09be\u09a8',
      'Ramadan': '\u09b0\u09ae\u099c\u09be\u09a8',
      'Shawwal': '\u09b6\u0993\u09df\u09be\u09b2',
      'Dhu al-Qi\'dah': '\u099c\u09bf\u09b2\u0995\u09a6',
      'Dhu al-Hijjah': '\u099c\u09bf\u09b2\u09b9\u099c',
    };
    return monthMap[name] ?? name;
  }

  String _localizedCountdownLabel() {
    if (!_isBangla) return _countdownLabel;
    final parts = _countdownLabel.split(' in ');
    if (parts.length == 2) {
      return '${_localizedPrayerName(parts[0])} \u09ac\u09be\u0995\u09bf ${_toBanglaDigits(parts[1])}';
    }
    return _toBanglaDigits(_countdownLabel);
  }

  String _localizedActiveRemainingLabel() => _isBangla
      ? '\u09b6\u09c7\u09b7 \u09b9\u0993\u09df\u09be\u09b0 \u09ac\u09be\u0995\u09bf'
      : 'Time Left';

  String _localizedPrayerTimeLabel() => _isBangla
      ? '\u09aa\u09cd\u09b0\u09be\u09b0\u09cd\u09a5\u09a8\u09be\u09b0 \u09b8\u09ae\u09df'
      : 'Prayer Time';

  String _localizedSehriAlertTitle() => _isBangla
      ? '\u09b8\u09c7\u09b9\u09b0\u09bf \u098f\u09b2\u09be\u09b0\u09cd\u099f'
      : 'Sehri Alert';

  String _localizedSehriAlertBody() => _isBangla
      ? '\u09b8\u09c7\u09b9\u09b0\u09bf\u09b0 \u09b8\u09ae\u09df \u09b9\u09df\u09c7\u099b\u09c7\u0964'
      : 'It is time for Sehri.';

  String _localizedIftarAlertTitle() => _isBangla
      ? '\u0987\u09ab\u09a4\u09be\u09b0 \u098f\u09b2\u09be\u09b0\u09cd\u099f'
      : 'Iftar Alert';

  String _localizedIftarAlertBody() => _isBangla
      ? '\u0987\u09ab\u09a4\u09be\u09b0\u09c7\u09b0 \u09b8\u09ae\u09df \u09b9\u09df\u09c7\u099b\u09c7\u0964'
      : 'It is time for Iftar.';

  String _localizedPrayerTime(String value) =>
      _isBangla ? _toBanglaDigits(value) : value;

  String _localizedNextSehriLabel() => _isBangla
      ? '\u09aa\u09b0\u09ac\u09b0\u09cd\u09a4\u09c0 \u09b8\u09c7\u09b9\u09b0\u09bf'
      : 'Next Sehri';

  String _localizedNextIftarLabel() => _isBangla
      ? '\u09aa\u09b0\u09ac\u09b0\u09cd\u09a4\u09c0 \u0987\u09ab\u09a4\u09be\u09b0'
      : 'Next Iftar';

  String _localizedDawnPrefix() => _isBangla ? '\u09ad\u09cb\u09b0' : 'Dawn';

  String _localizedSunsetPrefix() =>
      _isBangla ? '\u09b8\u09a8\u09cd\u09a7\u09cd\u09af\u09be' : 'Sunset';

  String _localizedRemainingLabel() => _isBangla
      ? '\u0985\u09ac\u09b6\u09bf\u09b7\u09cd\u099f \u09b8\u09ae\u09df'
      : 'Remaining';

  String _localizedLastReadLabel() => _isBangla
      ? '\u09b8\u09b0\u09cd\u09ac\u09b6\u09c7\u09b7 \u09a4\u09bf\u09b2\u09be\u0993\u09df\u09be\u09a4'
      : 'Last Read';

  String _localizedContinueLabel() => _isBangla
      ? '\u099a\u09be\u09b2\u09bf\u09df\u09c7 \u09af\u09be\u09a8'
      : 'Continue';

  String _lastReadPrimaryLine() {
    final chapter = _lastReadChapter;
    if (chapter != null) {
      final surahNo = _isBangla
          ? _toBanglaDigits(chapter.surahNo.toString())
          : chapter.surahNo.toString();
      return _isBangla
          ? '${chapter.surahName} • \u09b8\u09c2\u09b0\u09be $surahNo'
          : '${chapter.surahName} • Surah $surahNo';
    }

    if (_lastReadSurahNo != null) {
      final surahNo = _isBangla
          ? _toBanglaDigits(_lastReadSurahNo.toString())
          : _lastReadSurahNo.toString();
      return _isBangla ? '\u09b8\u09c2\u09b0\u09be $surahNo' : 'Surah $surahNo';
    }

    return _isBangla
        ? '\u09b8\u09be\u09ae\u09cd\u09aa\u09cd\u09b0\u09a4\u09bf\u0995 \u09a4\u09bf\u09b2\u09be\u0993\u09df\u09be\u09a4 \u09a8\u09c7\u0987'
        : 'No recent recitation';
  }

  String? _lastReadSecondaryLine() {
    final chapter = _lastReadChapter;
    if (chapter == null) return null;
    if (chapter.surahNameTranslation.trim().isEmpty) return null;
    return chapter.surahNameTranslation;
  }

  String _localizedTimeOrPlaceholder(DateTime? time) {
    if (time == null) return '--:--';
    return _localizedPrayerTime(_formatPrayerTime(time));
  }

  String _formattedIftarRemaining() {
    if (_nextIftarAt == null) return '--:--:--';
    final remaining = _nextIftarAt!.difference(_now);
    final safe = remaining.isNegative ? Duration.zero : remaining;
    final hh = safe.inHours.toString().padLeft(2, '0');
    final mm = (safe.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (safe.inSeconds % 60).toString().padLeft(2, '0');
    final value = '$hh:$mm:$ss';
    return _isBangla ? _toBanglaDigits(value) : value;
  }

  Future<void> _loadLastReadCard() async {
    final savedSurahNo = await _lastReadService.readLastReadSurahNo();
    if (!mounted) return;

    if (savedSurahNo == null) {
      _safeSetState(() {
        _lastReadSurahNo = null;
        _lastReadChapter = null;
      });
      return;
    }

    QuranChapter? chapter;
    try {
      final chapters = await _quranApiService.fetchChapters();
      for (final item in chapters) {
        if (item.surahNo == savedSurahNo) {
          chapter = item;
          break;
        }
      }
    } catch (_) {
      // Keep number fallback when chapter metadata is unavailable.
    }

    if (!mounted) return;
    _safeSetState(() {
      _lastReadSurahNo = savedSurahNo;
      _lastReadChapter = chapter;
    });
  }

  Future<void> _openLastRead() async {
    final chapter = _lastReadChapter;
    if (chapter != null) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => SurahDetailScreen(chapter: chapter),
        ),
      );
      return;
    }

    await Navigator.of(context).pushNamed(RouteNames.quran);
    if (!mounted) return;
    await _loadLastReadCard();
  }

  Future<void> _scheduleMealNotification({
    required int id,
    required String channelId,
    required String channelName,
    required String channelDescription,
    required DateTime at,
    required String title,
    required String body,
    required String payload,
  }) async {
    if (!localNotificationsInitialized) return;
    _ensureTimezoneInitializedForScheduling();
    var scheduled = tz.TZDateTime.from(at, tz.local);
    final nowTz = tz.TZDateTime.now(tz.local);
    if (scheduled.isBefore(nowTz)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    final tone = alertToneNotifier.value;
    NotificationDetails detailsForTone(AppAlertTone value) {
      final valuePlaySound = alertTonePlaySound(value);
      return NotificationDetails(
        android: AndroidNotificationDetails(
          channelIdForTone(channelId, tone: value),
          channelName,
          channelDescription: '$channelDescription (${alertToneLabel(value)})',
          importance: Importance.max,
          priority: Priority.high,
          playSound: valuePlaySound,
          sound: alertToneSound(value),
          audioAttributesUsage: alertToneUsage(value),
        ),
        iOS: DarwinNotificationDetails(presentSound: valuePlaySound),
      );
    }

    Future<void> scheduleWithDetails(
      NotificationDetails details, {
      required AndroidScheduleMode mode,
    }) async {
      await localNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        details,
        androidScheduleMode: mode,
        payload: payload,
      );
    }

    final details = detailsForTone(tone);

    try {
      await scheduleWithDetails(
        details,
        mode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } on PlatformException catch (e) {
      // Android 13/14 may block exact alarms unless special permission is granted.
      if (e.code == 'exact_alarms_not_permitted') {
        await scheduleWithDetails(
          details,
          mode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } else if (tone == AppAlertTone.adhan) {
        // If raw adhan sound is missing/invalid, fallback to default tone.
        final fallback = detailsForTone(AppAlertTone.appDefault);
        try {
          await scheduleWithDetails(
            fallback,
            mode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        } on PlatformException catch (fallbackError) {
          if (fallbackError.code == 'exact_alarms_not_permitted') {
            await scheduleWithDetails(
              fallback,
              mode: AndroidScheduleMode.inexactAllowWhileIdle,
            );
          } else {
            rethrow;
          }
        }
      } else {
        rethrow;
      }
    }
  }

  void _ensureTimezoneInitializedForScheduling() {
    try {
      // Accessing tz.local throws if local location was never configured.
      tz.local;
    } catch (_) {
      try {
        tz_data.initializeTimeZones();
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {
        // Keep scheduling flow from crashing even in test environments.
      }
    }
  }

  Future<void> _scheduleSehriNotification(DateTime sehriTime) async {
    if (!sehriAlertEnabledNotifier.value) return;
    await _scheduleMealNotification(
      id: sehriNotificationId,
      channelId: 'sehri_alert_channel',
      channelName: 'Sehri Alerts',
      channelDescription: 'Alert when Sehri time starts',
      at: sehriTime,
      title: _localizedSehriAlertTitle(),
      body: _localizedSehriAlertBody(),
      payload: 'sehri',
    );
  }

  Future<void> _schedulePrayerNotification({
    required int id,
    required String prayerName,
    required DateTime at,
  }) async {
    if (!prayerAlertsEnabledNotifier.value) return;
    await _scheduleMealNotification(
      id: id,
      channelId: 'prayer_alert_channel',
      channelName: 'Prayer Alerts',
      channelDescription: 'Alert when prayer time starts',
      at: at,
      title: '$prayerName Prayer Alert',
      body: 'It is time for $prayerName prayer.',
      payload: 'prayer_${prayerName.toLowerCase()}',
    );
  }

  Future<void> _cancelPrayerNotifications() async {
    if (!localNotificationsInitialized) return;
    await localNotificationsPlugin.cancel(fajrNotificationId);
    await localNotificationsPlugin.cancel(dzuhrNotificationId);
    await localNotificationsPlugin.cancel(ashrNotificationId);
    await localNotificationsPlugin.cancel(maghribNotificationId);
    await localNotificationsPlugin.cancel(ishaNotificationId);
  }

  Future<void> _refreshPrayerAlertScheduling() async {
    try {
      if (!prayerAlertsEnabledNotifier.value) {
        await _cancelPrayerNotifications();
        return;
      }

      final schedule = _todaySchedule;
      if (schedule == null) return;

      await _schedulePrayerNotification(
        id: fajrNotificationId,
        prayerName: 'Fajr',
        at: schedule.fajr,
      );
      await _schedulePrayerNotification(
        id: dzuhrNotificationId,
        prayerName: 'Dzuhr',
        at: schedule.dzuhr,
      );
      await _schedulePrayerNotification(
        id: ashrNotificationId,
        prayerName: 'Ashr',
        at: schedule.ashr,
      );
      await _schedulePrayerNotification(
        id: maghribNotificationId,
        prayerName: 'Maghrib',
        at: schedule.maghrib,
      );
      await _schedulePrayerNotification(
        id: ishaNotificationId,
        prayerName: 'Isha',
        at: schedule.isha,
      );
    } catch (e) {
      debugPrint('Prayer alert scheduling failed: $e');
    }
  }

  Future<void> _scheduleIftarNotification(DateTime iftarTime) async {
    if (!iftarAlertEnabledNotifier.value) return;
    await _scheduleMealNotification(
      id: iftarNotificationId,
      channelId: 'iftar_alert_channel',
      channelName: 'Iftar Alerts',
      channelDescription: 'Alert when Iftar time starts',
      at: iftarTime,
      title: _localizedIftarAlertTitle(),
      body: _localizedIftarAlertBody(),
      payload: 'iftar',
    );
  }

  Future<void> _cancelSehriNotification() async {
    if (!localNotificationsInitialized) return;
    await localNotificationsPlugin.cancel(sehriNotificationId);
  }

  Future<void> _cancelIftarNotification() async {
    if (!localNotificationsInitialized) return;
    await localNotificationsPlugin.cancel(iftarNotificationId);
  }

  Future<void> _refreshMealAlertScheduling() async {
    try {
      if (_nextSehriAt != null) {
        if (sehriAlertEnabledNotifier.value) {
          await _scheduleSehriNotification(_nextSehriAt!);
        } else {
          await _cancelSehriNotification();
        }
      }

      if (_nextIftarAt != null) {
        if (iftarAlertEnabledNotifier.value) {
          await _scheduleIftarNotification(_nextIftarAt!);
        } else {
          await _cancelIftarNotification();
        }
      }
    } catch (e) {
      debugPrint('Meal alert scheduling failed: $e');
    }
  }

  String get _displayPrayer => _selectedPrayer ?? _activePrayer;
  bool get _isShowingActivePrayer => _displayPrayer == _activePrayer;

  void _syncPrayerPageToActive({required bool animate}) {
    if (!_prayerPageController.hasClients) return;
    final target = _prayerOrder.indexOf(_activePrayer);
    if (target == -1) return;
    if (animate) {
      _prayerPageController.animateToPage(
        target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    } else {
      _prayerPageController.jumpToPage(target);
    }
  }

  Future<void> _loadPrayerData() async {
    if (!useDeviceLocationNotifier.value) {
      _setBaitulMukarramLocation();
      await _refreshPrayerScheduleFromSource(forceRefresh: true);
      return;
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setUseDeviceLocationSilently(false);
        _setBaitulMukarramLocation();
        await _refreshPrayerScheduleFromSource(forceRefresh: true);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _setUseDeviceLocationSilently(false);
        _setBaitulMukarramLocation();
        await _refreshPrayerScheduleFromSource(forceRefresh: true);
        return;
      }

      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
      } catch (_) {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown == null) rethrow;
        position = lastKnown;
      }
      _latitude = position.latitude;
      _longitude = position.longitude;
      await _resolveLocationLabel(position.latitude, position.longitude);
    } catch (e) {
      _setBaitulMukarramLocation();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not read current location. Using fallback temporarily.',
            ),
          ),
        );
      }
      debugPrint('Device location fetch failed: $e');
    }

    await _refreshPrayerScheduleFromSource(forceRefresh: true);
  }

  void _setBaitulMukarramLocation() {
    _latitude = _baitulMukarramLat;
    _longitude = _baitulMukarramLng;
    _safeSetState(() => _locationLabel = _baitulMukarramLabel);
  }

  Future<void> _resolveLocationLabel(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty || !mounted) return;
      final place = placemarks.first;
      final city =
          place.locality ??
          place.subAdministrativeArea ??
          place.administrativeArea ??
          'Current location';
      final area = place.administrativeArea ?? place.country ?? '';
      final label = area.isNotEmpty ? '$city, $area' : city;
      _safeSetState(() => _locationLabel = label);
    } catch (_) {
      _safeSetState(() => _locationLabel = 'Current location');
    }
  }

  Future<void> _refreshLocationFromHeader() async {
    if (_isRefreshingLocation) return;
    _isRefreshingLocation = true;
    try {
      _setUseDeviceLocationSilently(true);
      await _loadPrayerData();
      await saveAppPreferences();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Prayer times updated for $_locationLabel')),
      );
    } finally {
      _isRefreshingLocation = false;
    }
  }

  Future<void> _refreshPrayerScheduleFromSource({
    required bool forceRefresh,
  }) async {
    if (!mounted) return;
    if (_isFetchingPrayerSchedule) return;
    final today = DateTime(_now.year, _now.month, _now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final alreadyLoaded =
        _todaySchedule != null &&
        _tomorrowSchedule != null &&
        _isSameDate(_todaySchedule!.date, today) &&
        _isSameDate(_tomorrowSchedule!.date, tomorrow);
    if (!forceRefresh && alreadyLoaded) return;

    _isFetchingPrayerSchedule = true;
    try {
      final results = await Future.wait<DailyPrayerSchedule>([
        _fetchPrayerScheduleFromApi(today),
        _fetchPrayerScheduleFromApi(tomorrow),
      ]);
      _todaySchedule = results[0];
      _tomorrowSchedule = results[1];
    } catch (_) {
      // Fallback for offline mode or API failure.
      _todaySchedule = _buildFallbackSchedule(today);
      _tomorrowSchedule = _buildFallbackSchedule(tomorrow);
      if (mounted && forceRefresh) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Using offline calculated prayer times'),
          ),
        );
      }
    } finally {
      _isFetchingPrayerSchedule = false;
    }

    if (!mounted) return;
    _recalculatePrayerTimesForToday();
  }

  Future<DailyPrayerSchedule> _fetchPrayerScheduleFromApi(DateTime date) async {
    final latitude = _latitude ?? _baitulMukarramLat;
    final longitude = _longitude ?? _baitulMukarramLng;
    final response = await _prayerApi.get(
      '/v1/timings/${_formatApiDate(date)}',
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'method': _apiMethod,
        'school': _apiSchool,
      },
    );

    final root = response.data;
    if (root is! Map) {
      throw const FormatException('Invalid prayer response root');
    }
    final data = root['data'];
    if (data is! Map) {
      throw const FormatException('Invalid prayer response data');
    }
    final timings = data['timings'];
    if (timings is! Map) {
      throw const FormatException('Invalid prayer response timings');
    }

    String valueFor(String key) => (timings[key] ?? '').toString();
    return DailyPrayerSchedule(
      date: DateTime(date.year, date.month, date.day),
      imsak: _parseApiTime(date, valueFor('Imsak')),
      fajr: _parseApiTime(date, valueFor('Fajr')),
      dzuhr: _parseApiTime(date, valueFor('Dhuhr')),
      ashr: _parseApiTime(date, valueFor('Asr')),
      maghrib: _parseApiTime(date, valueFor('Maghrib')),
      isha: _parseApiTime(date, valueFor('Isha')),
    );
  }

  String _formatApiDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$dd-$mm-${date.year}';
  }

  DateTime _parseApiTime(DateTime date, String raw) {
    final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(raw);
    if (match == null) {
      throw FormatException('Invalid prayer time: $raw');
    }
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DailyPrayerSchedule _buildFallbackSchedule(DateTime date) {
    final prayers = _prayerTimesForDate(date);
    return DailyPrayerSchedule(
      date: DateTime(date.year, date.month, date.day),
      imsak: prayers.fajr.toLocal(),
      fajr: prayers.fajr.toLocal(),
      dzuhr: prayers.dhuhr.toLocal(),
      ashr: prayers.asr.toLocal(),
      maghrib: prayers.maghrib.toLocal(),
      isha: prayers.isha.toLocal(),
    );
  }

  CalculationParameters _buildCalculationParams() {
    final params = CalculationMethodParameters.karachi();
    params.madhab = Madhab.hanafi;
    return params;
  }

  PrayerTimes _prayerTimesForDate(DateTime date) {
    final latitude = _latitude ?? _baitulMukarramLat;
    final longitude = _longitude ?? _baitulMukarramLng;
    return PrayerTimes(
      date: date,
      coordinates: Coordinates(latitude, longitude),
      calculationParameters: _buildCalculationParams(),
    );
  }

  RamadanMealData _buildRamadanMealData({
    required DateTime now,
    required DateTime sehri,
    required DateTime maghrib,
    required DateTime tomorrowSehri,
    required DateTime tomorrowMaghrib,
  }) {
    final nextSehri = now.isBefore(sehri) ? sehri : tomorrowSehri;
    final nextIftar = now.isBefore(maghrib) ? maghrib : tomorrowMaghrib;
    return RamadanMealData(nextSehri: nextSehri, nextIftar: nextIftar);
  }

  void _recalculatePrayerTimesForToday() {
    if (!mounted) return;
    final today = DateTime(_now.year, _now.month, _now.day);

    final scheduleToday = _todaySchedule;
    final scheduleTomorrow = _tomorrowSchedule;
    if (scheduleToday == null ||
        scheduleTomorrow == null ||
        !_isSameDate(scheduleToday.date, today)) {
      unawaited(_refreshPrayerScheduleFromSource(forceRefresh: true));
      return;
    }

    final fajr = scheduleToday.fajr;
    final dzuhr = scheduleToday.dzuhr;
    final ashr = scheduleToday.ashr;
    final maghrib = scheduleToday.maghrib;
    final isha = scheduleToday.isha;
    final ishaBefore = scheduleToday.isha.subtract(const Duration(days: 1));
    final mealData = _buildRamadanMealData(
      now: _now,
      sehri: scheduleToday.imsak,
      maghrib: maghrib,
      tomorrowSehri: scheduleTomorrow.imsak,
      tomorrowMaghrib: scheduleTomorrow.maghrib,
    );
    final activeData = _buildActivePrayerData(
      now: _now,
      fajr: fajr,
      dzuhr: dzuhr,
      ashr: ashr,
      maghrib: maghrib,
      isha: isha,
      ishaBefore: ishaBefore,
    );

    _safeSetState(() {
      _lastPrayerCalcDate = today;
      _prayerTimes = {
        'Fajr': _formatPrayerTime(fajr),
        'Dzuhr': _formatPrayerTime(dzuhr),
        'Ashr': _formatPrayerTime(ashr),
        'Maghrib': _formatPrayerTime(maghrib),
        'Isha': _formatPrayerTime(isha),
      };
      _activePrayer = activeData.name;
      _countdownLabel = activeData.countdownLabel;
      _activeRemaining = activeData.remaining;
      _activeProgress = activeData.progress;
      _nextSehriAt = mealData.nextSehri;
      _nextIftarAt = mealData.nextIftar;
    });
    _refreshMealAlertScheduling();
    _refreshPrayerAlertScheduling();
    if (_selectedPrayer == null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncPrayerPageToActive(animate: false);
      });
    }
  }

  void _updateCountdown() {
    if (_prayerTimes['Fajr'] == '--:--') return;
    final today = DateTime(_now.year, _now.month, _now.day);
    final scheduleToday = _todaySchedule;
    final scheduleTomorrow = _tomorrowSchedule;
    if (scheduleToday == null ||
        scheduleTomorrow == null ||
        !_isSameDate(scheduleToday.date, today)) {
      if (!_isFetchingPrayerSchedule) {
        unawaited(_refreshPrayerScheduleFromSource(forceRefresh: true));
      }
      return;
    }

    final fajr = scheduleToday.fajr;
    final dzuhr = scheduleToday.dzuhr;
    final ashr = scheduleToday.ashr;
    final maghrib = scheduleToday.maghrib;
    final isha = scheduleToday.isha;
    final ishaBefore = scheduleToday.isha.subtract(const Duration(days: 1));
    final mealData = _buildRamadanMealData(
      now: _now,
      sehri: scheduleToday.imsak,
      maghrib: maghrib,
      tomorrowSehri: scheduleTomorrow.imsak,
      tomorrowMaghrib: scheduleTomorrow.maghrib,
    );
    final activeData = _buildActivePrayerData(
      now: _now,
      fajr: fajr,
      dzuhr: dzuhr,
      ashr: ashr,
      maghrib: maghrib,
      isha: isha,
      ishaBefore: ishaBefore,
    );
    final mealsChanged =
        mealData.nextSehri != _nextSehriAt ||
        mealData.nextIftar != _nextIftarAt;

    if (mounted &&
        (activeData.name != _activePrayer ||
            activeData.countdownLabel != _countdownLabel ||
            activeData.progress != _activeProgress ||
            activeData.remaining != _activeRemaining ||
            mealsChanged)) {
      _safeSetState(() {
        _activePrayer = activeData.name;
        _countdownLabel = activeData.countdownLabel;
        _activeRemaining = activeData.remaining;
        _activeProgress = activeData.progress;
        _nextSehriAt = mealData.nextSehri;
        _nextIftarAt = mealData.nextIftar;
      });
      if (mealsChanged) {
        _refreshMealAlertScheduling();
      }
      if (_selectedPrayer == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _syncPrayerPageToActive(animate: true);
        });
      }
    }
  }

  String _formatPrayerTime(DateTime time) {
    final h = (time.hour % 12 == 0 ? 12 : time.hour % 12).toString();
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  ActivePrayerData _buildActivePrayerData({
    required DateTime now,
    required DateTime fajr,
    required DateTime dzuhr,
    required DateTime ashr,
    required DateTime maghrib,
    required DateTime isha,
    required DateTime ishaBefore,
  }) {
    final schedule = <MapEntry<String, DateTime>>[
      MapEntry('Fajr', fajr),
      MapEntry('Dzuhr', dzuhr),
      MapEntry('Ashr', ashr),
      MapEntry('Maghrib', maghrib),
      MapEntry('Isha', isha),
    ];

    MapEntry<String, DateTime>? activePrayer;
    int activeIndex = -1;
    for (int i = 0; i < schedule.length; i++) {
      if (schedule[i].value.isAfter(now)) {
        activePrayer = schedule[i];
        activeIndex = i;
        break;
      }
    }

    DateTime previousBoundary;
    if (activePrayer == null) {
      activePrayer = MapEntry('Fajr', fajr.add(const Duration(days: 1)));
      previousBoundary = isha;
    } else if (activeIndex == 0) {
      previousBoundary = ishaBefore;
    } else {
      previousBoundary = schedule[activeIndex - 1].value;
    }

    final remaining = activePrayer.value.difference(now);
    final totalWindow = activePrayer.value.difference(previousBoundary);
    final elapsed = totalWindow - remaining;
    final progress = totalWindow.inMilliseconds <= 0
        ? 0.0
        : (elapsed.inMilliseconds / totalWindow.inMilliseconds).clamp(0.0, 1.0);
    final hh = remaining.inHours.toString().padLeft(2, '0');
    final mm = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return ActivePrayerData(
      name: activePrayer.key,
      countdownLabel: '${activePrayer.key} in $hh:$mm:$ss',
      remaining: remaining.isNegative ? Duration.zero : remaining,
      progress: progress,
    );
  }

  String _formattedActiveRemaining() {
    final d = _activeRemaining.isNegative ? Duration.zero : _activeRemaining;
    final hh = d.inHours.toString().padLeft(2, '0');
    final mm = (d.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (d.inSeconds % 60).toString().padLeft(2, '0');
    final value = '$hh:$mm:$ss';
    return _isBangla ? _toBanglaDigits(value) : value;
  }

  Widget _buildRamadanMealsSection() {
    final sehriTime = _localizedTimeOrPlaceholder(_nextSehriAt);
    final iftarTime = _localizedTimeOrPlaceholder(_nextIftarAt);
    final sehriTrailing = '${_localizedDawnPrefix()} $sehriTime';
    final iftarTrailing = '${_localizedSunsetPrefix()} $iftarTime';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD7E3D9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
            child: Row(
              children: [
                const Icon(
                  Icons.lunch_dining_outlined,
                  size: 18,
                  color: Color(0xFF5A6D61),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _localizedNextSehriLabel(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF25332D),
                    ),
                  ),
                ),
                Text(
                  sehriTrailing,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF25332D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFDCE7DD)),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: const BoxDecoration(
              color: Color(0xFFEAF2EB),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDF0E3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    size: 15,
                    color: Color(0xFF0B8D69),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _localizedNextIftarLabel(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF25332D),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      iftarTrailing,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF25332D),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_localizedRemainingLabel()} ${_formattedIftarRemaining()}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4D5F56),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gaugePrayerName = _localizedPrayerName(_displayPrayer);
    final gaugeSubtitle = _isShowingActivePrayer
        ? _localizedActiveRemainingLabel()
        : _localizedPrayerTimeLabel();
    final gaugeValue = _isShowingActivePrayer
        ? _formattedActiveRemaining()
        : _localizedPrayerTime(_prayerTimes[_displayPrayer] ?? '--:--');
    final gaugeProgress = _isShowingActivePrayer ? _activeProgress : 0.0;
    final lastReadSecondary = _lastReadSecondaryLine();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: _headerHeight,
              decoration: const BoxDecoration(
                color: Color(0xFF1D98A9),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(24),
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/header-bg.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              _formattedTime,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.w700,
                                height: 1,
                              ),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: 170,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 420),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                layoutBuilder:
                                    (currentChild, previousChildren) => Stack(
                                      alignment: Alignment.centerRight,
                                      children: [
                                        ...previousChildren,
                                        ...?currentChild == null
                                            ? null
                                            : [currentChild],
                                      ],
                                    ),
                                transitionBuilder: (child, animation) {
                                  final slide = Tween<Offset>(
                                    begin: const Offset(0, -0.28),
                                    end: Offset.zero,
                                  ).animate(animation);
                                  return ClipRect(
                                    child: SlideTransition(
                                      position: slide,
                                      child: FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  _activeHeaderDate,
                                  key: ValueKey(_activeHeaderDate),
                                  textAlign: TextAlign.right,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              _localizedCountdownLabel(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: _refreshLocationFromHeader,
                              borderRadius: BorderRadius.circular(1000),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0x33FFFFFF),
                                  borderRadius: BorderRadius.circular(1000),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    SizedBox(
                                      width: 132,
                                      child: Text(
                                        _locationLabel,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.refresh_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        HomeActivePrayerGauge(
                          prayerName: gaugePrayerName,
                          subtitle: gaugeSubtitle,
                          remainingTime: gaugeValue,
                          progress: gaugeProgress,
                        ),
                        const SizedBox(height: 6),
                        if (!_isShowingActivePrayer)
                          Align(
                            alignment: Alignment.center,
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () {
                                setState(() => _selectedPrayer = null);
                                _syncPrayerPageToActive(animate: true);
                              },
                              icon: const Icon(Icons.my_location, size: 16),
                              label: Text(
                                _isBangla
                                    ? '\u09ac\u09b0\u09cd\u09a4\u09ae\u09be\u09a8 \u09aa\u09cd\u09b0\u09be\u09b0\u09cd\u09a5\u09a8\u09be'
                                    : 'Back to current',
                              ),
                            ),
                          ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: -12,
                    child: SizedBox(
                      height: 102,
                      child: PageView.builder(
                        controller: _prayerPageController,
                        itemCount: _prayerOrder.length,
                        onPageChanged: (index) {
                          setState(() => _selectedPrayer = _prayerOrder[index]);
                        },
                        itemBuilder: (context, index) {
                          final prayer = _prayerOrder[index];
                          return Center(
                            child: HomePrayerTile(
                              title: _localizedPrayerName(prayer),
                              time: _localizedPrayerTime(
                                _prayerTimes[prayer] ?? '--:--',
                              ),
                              active: prayer == _displayPrayer,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                children: [
                  _buildRamadanMealsSection(),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE1E8EC)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _localizedLastReadLabel(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6F8DA1),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.menu_book_rounded,
                                    size: 16,
                                    color: Color(0xFF1D98A9),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _lastReadPrimaryLine(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF1F252D),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (lastReadSecondary != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  lastReadSecondary,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF6F8DA1),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        FilledButton(
                          onPressed: _openLastRead,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1D98A9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(1000),
                            ),
                          ),
                          child: Text(
                            _localizedContinueLabel(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE1E8EC)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => Navigator.of(
                                context,
                              ).pushNamed(RouteNames.prayerCompass),
                              child: Row(
                                children: [
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Locate',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF1F252D),
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Qibla',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1D98A9),
                                      borderRadius: BorderRadius.circular(1000),
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: const Icon(
                                      Icons.explore,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          const SizedBox(
                            height: 48,
                            child: VerticalDivider(
                              color: Color(0xFFE1E8EC),
                              thickness: 1,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => Navigator.of(
                                context,
                              ).pushNamed(RouteNames.findMosque),
                              child: Row(
                                children: [
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Find nearest',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF1F252D),
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Mosque',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1D98A9),
                                      borderRadius: BorderRadius.circular(1000),
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: const Icon(
                                      Icons.location_city,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () =>
                          Navigator.of(context).pushNamed(RouteNames.asma),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE1E8EC)),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Read',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF1F252D),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    '99 Names (Asma Ul Husna)',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1D98A9),
                                borderRadius: BorderRadius.circular(1000),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: const Icon(
                                Icons.auto_stories_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () =>
                          Navigator.of(context).pushNamed(RouteNames.dua),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE1E8EC)),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Read',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF1F252D),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Hisnul Muslim Duas',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1D98A9),
                                borderRadius: BorderRadius.circular(1000),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: const Icon(
                                Icons.menu_book_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text(
                        'Daily Activity',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F252D),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC95C16),
                          borderRadius: BorderRadius.circular(1000),
                        ),
                        child: const Text(
                          '50%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Complete the daily activity checklist',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6F8DA1)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (int i = 0; i < _dailyGoal; i++) ...[
                        Expanded(
                          child: Container(
                            height: 6,
                            margin: EdgeInsets.only(
                              right: i == _dailyGoal - 1 ? 0 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: i < _completedDaily
                                  ? const Color(0xFF1D98A9)
                                  : const Color(0xFFE1E8EC),
                              borderRadius: BorderRadius.circular(1000),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      Text(
                        '$_completedDaily/$_dailyGoal',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1D98A9),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._activities.map(
                    (activity) => HomeChecklistRow(
                      title: activity.title,
                      status: '${activity.done}/${activity.total}',
                      isDone: activity.done >= activity.total,
                      onTapDone: () {
                        setState(() {
                          if (activity.done < activity.total) {
                            activity.done += 1;
                          }
                          if (_completedDaily < _dailyGoal) {
                            _completedDaily += 1;
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 46),
                      backgroundColor: const Color(0xFF1D98A9),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Daily activity saved locally'),
                        ),
                      );
                    },
                    child: const Text('Go to Checklist'),
                  ),
                ],
              ),
            ),
            bottomNav(context, 0),
          ],
        ),
      ),
    );
  }
}
