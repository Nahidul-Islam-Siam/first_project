import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:ponjika/ponjika.dart';
import 'package:timezone/timezone.dart' as tz;

import '../app/app_globals.dart';
import '../widgets/bottom_nav.dart';

class DailyActivityScreen extends StatefulWidget {
  const DailyActivityScreen({super.key});

  @override
  State<DailyActivityScreen> createState() => _DailyActivityScreenState();
}

class _DailyActivityScreenState extends State<DailyActivityScreen> {
  static const _dhakaLat = 23.8103;
  static const _dhakaLng = 90.4125;
  static const _headerHeight = 330.0;

  late final Timer _clockTimer;
  DateTime _now = DateTime.now();
  double? _latitude;
  double? _longitude;
  DateTime? _lastPrayerCalcDate;
  DateTime? _todayFajr;
  DateTime? _todayIftar;
  DateTime? _nextSehriAt;
  DateTime? _nextIftarAt;
  DateTime? _lastShownSehriModalAt;
  DateTime? _lastShownIftarModalAt;
  bool _isAlertDialogOpen = false;
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

  final List<_ActivityItem> _activities = [
    _ActivityItem(title: 'Alms', done: 4, total: 10),
    _ActivityItem(title: 'Recite the Al Quran', done: 8, total: 10),
  ];

  @override
  void initState() {
    super.initState();
    _prayerPageController = PageController(
      viewportFraction: 0.23,
      initialPage: _prayerOrder.indexOf(_activePrayer),
    );
    appLanguageNotifier.addListener(_onLanguageChanged);
    sehriAlertEnabledNotifier.addListener(_onSehriAlertToggleChanged);
    iftarAlertEnabledNotifier.addListener(_onIftarAlertToggleChanged);
    _loadPrayerData();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
      _updateCountdown();
      _maybeShowMealAlertsModal();
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
    sehriAlertEnabledNotifier.removeListener(_onSehriAlertToggleChanged);
    iftarAlertEnabledNotifier.removeListener(_onIftarAlertToggleChanged);
    _clockTimer.cancel();
    _prayerPageController.dispose();
    super.dispose();
  }

  void _onLanguageChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _onSehriAlertToggleChanged() async {
    if (sehriAlertEnabledNotifier.value) {
      if (_nextSehriAt != null) {
        await _scheduleSehriNotification(_nextSehriAt!);
      }
    } else {
      await _cancelSehriNotification();
    }
    if (mounted) setState(() {});
  }

  Future<void> _onIftarAlertToggleChanged() async {
    if (iftarAlertEnabledNotifier.value) {
      if (_nextIftarAt != null) {
        await _scheduleIftarNotification(_nextIftarAt!);
      }
    } else {
      await _cancelIftarNotification();
    }
    if (mounted) setState(() {});
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

  String _localizedStopAlerts() => _isBangla
      ? '\u098f\u09b2\u09be\u09b0\u09cd\u099f \u09ac\u09a8\u09cd\u09a7'
      : 'Stop Alerts';

  String _localizedClose() => _isBangla ? '\u09ac\u09a8\u09cd\u09a7' : 'Close';

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
    var scheduled = tz.TZDateTime.from(at, tz.local);
    final nowTz = tz.TZDateTime.now(tz.local);
    if (scheduled.isBefore(nowTz)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    try {
      await localNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
    } on PlatformException catch (e) {
      // Android 13/14 may block exact alarms unless special permission is granted.
      if (e.code == 'exact_alarms_not_permitted') {
        await localNotificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          scheduled,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: payload,
        );
      } else {
        rethrow;
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
    await localNotificationsPlugin.cancel(sehriNotificationId);
  }

  Future<void> _cancelIftarNotification() async {
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

  bool _isNowWithinAlertWindow(DateTime eventTime) {
    final end = eventTime.add(const Duration(minutes: 1));
    return !_now.isBefore(eventTime) && !_now.isAfter(end);
  }

  void _showMealAlertModal({
    required String title,
    required String body,
    required Future<void> Function() onStopPressed,
  }) {
    if (!mounted || _isAlertDialogOpen) return;
    _isAlertDialogOpen = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () async {
                await onStopPressed();
                if (context.mounted) Navigator.of(context).pop();
              },
              child: Text(_localizedStopAlerts()),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(_localizedClose()),
            ),
          ],
        );
      },
    ).whenComplete(() {
      _isAlertDialogOpen = false;
    });
  }

  void _maybeShowMealAlertsModal() {
    if (!mounted || _isAlertDialogOpen) return;

    if (sehriAlertEnabledNotifier.value &&
        _todayFajr != null &&
        _lastShownSehriModalAt != _todayFajr &&
        _isNowWithinAlertWindow(_todayFajr!)) {
      _lastShownSehriModalAt = _todayFajr;
      _showMealAlertModal(
        title: _localizedSehriAlertTitle(),
        body: _localizedSehriAlertBody(),
        onStopPressed: () async {
          sehriAlertEnabledNotifier.value = false;
          await _cancelSehriNotification();
        },
      );
      return;
    }

    if (iftarAlertEnabledNotifier.value &&
        _todayIftar != null &&
        _lastShownIftarModalAt != _todayIftar &&
        _isNowWithinAlertWindow(_todayIftar!)) {
      _lastShownIftarModalAt = _todayIftar;
      _showMealAlertModal(
        title: _localizedIftarAlertTitle(),
        body: _localizedIftarAlertBody(),
        onStopPressed: () async {
          iftarAlertEnabledNotifier.value = false;
          await _cancelIftarNotification();
        },
      );
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
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _latitude = _dhakaLat;
        _longitude = _dhakaLng;
        if (mounted) {
          setState(() => _locationLabel = 'Dhaka, Bangladesh');
        }
        _recalculatePrayerTimesForToday();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _latitude = _dhakaLat;
        _longitude = _dhakaLng;
        if (mounted) {
          setState(() => _locationLabel = 'Dhaka, Bangladesh');
        }
        _recalculatePrayerTimesForToday();
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      _latitude = position.latitude;
      _longitude = position.longitude;

      await _resolveLocationLabel(position.latitude, position.longitude);
      _recalculatePrayerTimesForToday();
    } catch (_) {
      _latitude = _dhakaLat;
      _longitude = _dhakaLng;
      if (!mounted) return;
      setState(() => _locationLabel = 'Dhaka, Bangladesh');
      _recalculatePrayerTimesForToday();
    }
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
          'Your location';
      final area = place.administrativeArea ?? place.country ?? '';
      final label = area.isNotEmpty ? '$city, $area' : city;
      setState(() => _locationLabel = label);
    } catch (_) {
      if (!mounted) return;
      setState(() => _locationLabel = 'Current location');
    }
  }

  CalculationParameters _buildCalculationParams() {
    final params = CalculationMethodParameters.karachi();
    params.madhab = Madhab.hanafi;
    return params;
  }

  PrayerTimes _prayerTimesForDate(DateTime date) {
    return PrayerTimes(
      date: date,
      coordinates: Coordinates(_latitude!, _longitude!),
      calculationParameters: _buildCalculationParams(),
    );
  }

  _RamadanMealData _buildRamadanMealData({
    required DateTime now,
    required DateTime fajr,
    required DateTime maghrib,
    required DateTime tomorrowFajr,
    required DateTime tomorrowMaghrib,
  }) {
    final nextSehri = now.isBefore(fajr) ? fajr : tomorrowFajr;
    final nextIftar = now.isBefore(maghrib) ? maghrib : tomorrowMaghrib;
    return _RamadanMealData(nextSehri: nextSehri, nextIftar: nextIftar);
  }

  void _recalculatePrayerTimesForToday() {
    if (_latitude == null || _longitude == null) return;
    final isNewDay =
        _lastPrayerCalcDate == null ||
        _lastPrayerCalcDate!.day != _now.day ||
        _lastPrayerCalcDate!.month != _now.month ||
        _lastPrayerCalcDate!.year != _now.year;

    final prayers = _prayerTimesForDate(_now);
    final tomorrowPrayers = _prayerTimesForDate(
      _now.add(const Duration(days: 1)),
    );

    final fajr = prayers.fajr.toLocal();
    final dzuhr = prayers.dhuhr.toLocal();
    final ashr = prayers.asr.toLocal();
    final maghrib = prayers.maghrib.toLocal();
    final isha = prayers.isha.toLocal();
    final ishaBefore = prayers.ishaBefore.toLocal();
    final mealData = _buildRamadanMealData(
      now: _now,
      fajr: fajr,
      maghrib: maghrib,
      tomorrowFajr: tomorrowPrayers.fajr.toLocal(),
      tomorrowMaghrib: tomorrowPrayers.maghrib.toLocal(),
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

    setState(() {
      _lastPrayerCalcDate = DateTime.now();
      _todayFajr = fajr;
      _todayIftar = maghrib;
      if (isNewDay) {
        _lastShownSehriModalAt = null;
        _lastShownIftarModalAt = null;
      }
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
    if (_selectedPrayer == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _syncPrayerPageToActive(animate: false);
      });
    }
  }

  void _updateCountdown() {
    if (_prayerTimes['Fajr'] == '--:--') return;
    if (_latitude == null || _longitude == null) return;
    final prayers = _prayerTimesForDate(_now);
    final tomorrowPrayers = _prayerTimesForDate(
      _now.add(const Duration(days: 1)),
    );

    final fajr = prayers.fajr.toLocal();
    final dzuhr = prayers.dhuhr.toLocal();
    final ashr = prayers.asr.toLocal();
    final maghrib = prayers.maghrib.toLocal();
    final isha = prayers.isha.toLocal();
    final ishaBefore = prayers.ishaBefore.toLocal();
    final mealData = _buildRamadanMealData(
      now: _now,
      fajr: fajr,
      maghrib: maghrib,
      tomorrowFajr: tomorrowPrayers.fajr.toLocal(),
      tomorrowMaghrib: tomorrowPrayers.maghrib.toLocal(),
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
      setState(() {
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

  _ActivePrayerData _buildActivePrayerData({
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
    return _ActivePrayerData(
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
                            Container(
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
                                    Icons.chevron_right,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _ActivePrayerGauge(
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
                            child: _PrayerTile(
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
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Last Read',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6F8DA1),
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.menu_book_rounded,
                                    size: 16,
                                    color: Color(0xFF1D98A9),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Al Baqarah : 120',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF1F252D),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Juz 1',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF6F8DA1),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        FilledButton(
                          onPressed: () {},
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1D98A9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(1000),
                            ),
                          ),
                          child: const Text(
                            'Continue',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
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
                        const SizedBox(width: 14),
                        const SizedBox(
                          height: 48,
                          child: VerticalDivider(
                            color: Color(0xFFE1E8EC),
                            thickness: 1,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                    (activity) => _ChecklistRow(
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

class _ActivityItem {
  _ActivityItem({required this.title, required this.done, required this.total});

  final String title;
  int done;
  final int total;
}

class _RamadanMealData {
  const _RamadanMealData({required this.nextSehri, required this.nextIftar});

  final DateTime nextSehri;
  final DateTime nextIftar;
}

class _ActivePrayerData {
  const _ActivePrayerData({
    required this.name,
    required this.countdownLabel,
    required this.remaining,
    required this.progress,
  });

  final String name;
  final String countdownLabel;
  final Duration remaining;
  final double progress;
}

class _ActivePrayerGauge extends StatelessWidget {
  const _ActivePrayerGauge({
    required this.prayerName,
    required this.subtitle,
    required this.remainingTime,
    required this.progress,
  });

  final String prayerName;
  final String subtitle;
  final String remainingTime;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(170, 100),
            painter: _ActivePrayerGaugePainter(progress: progress),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  prayerName,
                  style: const TextStyle(
                    color: Color(0xFF18363A),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF18363A),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  remainingTime,
                  style: const TextStyle(
                    color: Color(0xFF18363A),
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivePrayerGaugePainter extends CustomPainter {
  _ActivePrayerGaugePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 8.0;
    final radius = (size.width / 2) - stroke;
    final center = Offset(size.width / 2, size.height * 0.95);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..color = const Color(0x33FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = const Color(0xFF14383E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 3.14159, 3.14159, false, bgPaint);
    canvas.drawArc(
      rect,
      3.14159,
      3.14159 * progress.clamp(0.0, 1.0),
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ActivePrayerGaugePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _PrayerTile extends StatelessWidget {
  const _PrayerTile({
    required this.title,
    required this.time,
    this.active = false,
  });

  final String title;
  final String time;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      width: active ? 80 : 68,
      padding: EdgeInsets.symmetric(vertical: active ? 14 : 10),
      decoration: BoxDecoration(
        color: active ? const Color(0x44FFFFFF) : const Color(0x22FFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: active ? Border.all(color: const Color(0x66FFFFFF)) : null,
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: active ? 14 : 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Icon(
            active ? Icons.wb_sunny_rounded : Icons.cloud_rounded,
            size: active ? 18 : 16,
            color: Colors.white,
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(
              color: Colors.white,
              fontSize: active ? 13 : 12,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.title,
    required this.status,
    required this.isDone,
    required this.onTapDone,
  });

  final String title;
  final String status;
  final bool isDone;
  final VoidCallback onTapDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1E8EC)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Color(0xFF1F252D),
              ),
            ),
          ),
          Text(
            status,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF1D98A9),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onTapDone,
            borderRadius: BorderRadius.circular(16),
            child: Icon(
              isDone
                  ? Icons.check_circle_outline
                  : Icons.radio_button_unchecked,
              color: const Color(0xFF6F8DA1),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
