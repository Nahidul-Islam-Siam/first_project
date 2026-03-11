part of '../screens/daily_activity_screen.dart';

mixin DailyActivityControllerMixin on State<DailyActivityScreen> {
  static const _kaabaLat = 21.422487;
  static const _kaabaLng = 39.826206;
  static const _baitulMukarramLat = 23.7286;
  static const _baitulMukarramLng = 90.4106;
  static const _baitulMukarramLabel = 'Baitul Mukarram, Dhaka';
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
  String _activePrayer = 'Zuhr';
  Duration _activeRemaining = Duration.zero;
  double _activeProgress = 0.0;
  Map<String, String> _prayerTimes = const {
    'Fajr': '--:--',
    'Zuhr': '--:--',
    'Asr': '--:--',
    'Maghrib': '--:--',
    'Isha': '--:--',
  };

  final int _completedDaily = 3;
  final int _dailyGoal = 6;
  StreamSubscription<CompassEvent>? _homeCompassSub;
  double? _homeHeading;
  double? _homeQiblaBearing;
  final List<String> _prayerOrder = const [
    'Fajr',
    'Zuhr',
    'Asr',
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
  bool _announcementModalChecked = false;
  bool _announcementModalFetchInProgress = false;
  static String? _lastShownAnnouncementId;

  void initializeDailyActivityController() {
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
    _initializeMiniCompass();
    _loadPrayerData();
    _loadLastReadCard();
    unawaited(_showAnnouncementModalIfNeeded());
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

  void disposeDailyActivityController() {
    appLanguageNotifier.removeListener(_onLanguageChanged);
    useDeviceLocationNotifier.removeListener(_onUseDeviceLocationChanged);
    prayerAlertsEnabledNotifier.removeListener(_onPrayerAlertToggleChanged);
    sehriAlertEnabledNotifier.removeListener(_onSehriAlertToggleChanged);
    iftarAlertEnabledNotifier.removeListener(_onIftarAlertToggleChanged);
    alertToneNotifier.removeListener(_onAlertToneChanged);
    _homeCompassSub?.cancel();
    _clockTimer.cancel();
    _prayerPageController.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  Future<void> _showAnnouncementModalIfNeeded() async {
    if (_announcementModalChecked || _announcementModalFetchInProgress) return;
    if (Firebase.apps.isEmpty) {
      _announcementModalChecked = true;
      return;
    }
    final hasInternet = await NetworkUtils.hasInternet();
    if (!hasInternet) {
      _announcementModalChecked = true;
      return;
    }
    _announcementModalFetchInProgress = true;
    try {
      final announcement = await AnnouncementService.instance
          .fetchLatestActiveModalAnnouncement();
      if (!mounted) return;
      _announcementModalChecked = true;
      if (announcement == null) return;
      if (_lastShownAnnouncementId == announcement.id) return;
      _lastShownAnnouncementId = announcement.id;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openAnnouncementDialog(announcement);
      });
    } catch (e) {
      debugPrint('Announcement modal loading failed: $e');
    } finally {
      _announcementModalFetchInProgress = false;
    }
  }

  void _openAnnouncementDialog(AnnouncementItem item) {
    final title = item.localizedTitle(_isBangla);
    final message = item.localizedMessage(_isBangla);
    final posterUrl = item.posterUrl?.trim();
    final hasPoster = _isNetworkImageUrl(posterUrl);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            title.isEmpty
                ? (_isBangla
                      ? '\u0997\u09c1\u09b0\u09c1\u09a4\u09cd\u09ac\u09aa\u09c2\u09b0\u09cd\u09a3 \u0998\u09cb\u09b7\u09a3\u09be'
                      : 'Important Announcement')
                : title,
          ),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasPoster) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        posterUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    message.isEmpty
                        ? (_isBangla
                              ? '\u09a8\u09a4\u09c1\u09a8 \u0986\u09aa\u09a1\u09c7\u099f \u09aa\u09c7\u09a4\u09c7 \u0986\u09ae\u09be\u09a6\u09c7\u09b0 \u09b8\u09be\u09a5\u09c7 \u09a5\u09be\u0995\u09c1\u09a8\u0964'
                              : 'Stay connected for the latest app update.')
                        : message,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                _isBangla
                    ? '\u09ac\u09a8\u09cd\u09a7 \u0995\u09b0\u09c1\u09a8'
                    : 'Close',
              ),
            ),
          ],
        );
      },
    );
  }

  bool _isNetworkImageUrl(String? value) {
    if (value == null || value.isEmpty) return false;
    final uri = Uri.tryParse(value);
    if (uri == null) return false;
    final scheme = uri.scheme.toLowerCase();
    return scheme == 'http' || scheme == 'https';
  }

  void _initializeMiniCompass() {
    _homeCompassSub?.cancel();
    final stream = FlutterCompass.events;
    if (stream == null) {
      _homeHeading = null;
      return;
    }

    _homeCompassSub = stream.listen(
      (event) {
        final heading = event.heading;
        if (heading == null || heading.isNaN) return;
        _safeSetState(() {
          _homeHeading = _normalizeDegrees(heading);
        });
      },
      onError: (_) {
        _safeSetState(() => _homeHeading = null);
      },
    );
  }

  void _updateHomeQiblaBearing(double lat, double lng) {
    _homeQiblaBearing = _calculateQiblaBearingBasic(lat: lat, lng: lng);
  }

  double _calculateQiblaBearingBasic({
    required double lat,
    required double lng,
  }) {
    final latRad = lat * math.pi / 180;
    final lngRad = lng * math.pi / 180;
    final kaabaLatRad = _kaabaLat * math.pi / 180;
    final kaabaLngRad = _kaabaLng * math.pi / 180;
    final dLng = kaabaLngRad - lngRad;

    final y = math.sin(dLng);
    final x =
        math.cos(latRad) * math.tan(kaabaLatRad) -
        math.sin(latRad) * math.cos(dLng);
    final bearing = math.atan2(y, x) * 180 / math.pi;
    return _normalizeDegrees(bearing);
  }

  double _normalizeDegrees(double degrees) {
    final normalized = degrees % 360;
    return normalized < 0 ? normalized + 360 : normalized;
  }

  double _signedQiblaDelta(double target, double current) {
    return ((target - current + 540) % 360) - 180;
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
      'Zuhr': '\u09af\u09cb\u09b9\u09b0',
      'Asr': '\u0986\u09b8\u09b0',
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
        prayerName: 'Zuhr',
        at: schedule.dzuhr,
      );
      await _schedulePrayerNotification(
        id: ashrNotificationId,
        prayerName: 'Asr',
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
      _updateHomeQiblaBearing(position.latitude, position.longitude);
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
    _updateHomeQiblaBearing(_baitulMukarramLat, _baitulMukarramLng);
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
        'Zuhr': _formatPrayerTime(dzuhr),
        'Asr': _formatPrayerTime(ashr),
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
      MapEntry('Zuhr', dzuhr),
      MapEntry('Asr', ashr),
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
}
