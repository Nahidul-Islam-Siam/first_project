import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'package:first_project/core/constants/route_names.dart';
import 'package:first_project/features/prayer_time/services/prayer_schedule_service.dart';
import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/shared/widgets/bottom_nav.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  static const _baitulMukarramLat = 23.7286;
  static const _baitulMukarramLng = 90.4106;
  static const _fallbackLabel = 'Baitul Mukarram, Dhaka';

  final PrayerScheduleService _service = PrayerScheduleService();

  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  DailyPrayerSchedule? _todaySchedule;
  DailyPrayerSchedule? _tomorrowSchedule;

  String _locationLabel = 'Detecting location...';
  bool _isLoading = true;
  bool _isSyncing = false;
  bool _isRefreshing = false;
  bool _usingFallbackLocation = false;
  bool _usingOfflineCalculation = false;

  String _activePrayer = 'Fajr';
  DateTime? _nextPrayerAt;
  Duration _remaining = Duration.zero;
  double _elapsedProgress = 0.0;

  bool get _isBangla => appLanguageNotifier.value == AppLanguage.bangla;

  String _text(String english, String bangla) => _isBangla ? bangla : english;

  @override
  void initState() {
    super.initState();
    appLanguageNotifier.addListener(_onLanguageChanged);
    useDeviceLocationNotifier.addListener(_onLocationModeChanged);
    profileLocationNotifier.addListener(_onProfileLocationChanged);
    _seedLocalPrayerPreview();
    unawaited(_loadPrayerData(showLoader: false));
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
      _updateActivePrayer();
      if (_needsFreshSchedule() && !_isLoading) {
        unawaited(_loadPrayerData(showLoader: false));
      }
    });
  }

  @override
  void dispose() {
    appLanguageNotifier.removeListener(_onLanguageChanged);
    useDeviceLocationNotifier.removeListener(_onLocationModeChanged);
    profileLocationNotifier.removeListener(_onProfileLocationChanged);
    _clockTimer?.cancel();
    super.dispose();
  }

  void _onLanguageChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onLocationModeChanged() {
    unawaited(_loadPrayerData(showLoader: false));
  }

  void _onProfileLocationChanged() {
    if (!mounted || useDeviceLocationNotifier.value) return;
    setState(() => _locationLabel = _profileOrFallbackLocationLabel());
  }

  bool _needsFreshSchedule() {
    final today = DateTime(_now.year, _now.month, _now.day);
    return _todaySchedule == null ||
        _tomorrowSchedule == null ||
        !_isSameDate(_todaySchedule!.date, today) ||
        !_isSameDate(
          _tomorrowSchedule!.date,
          today.add(const Duration(days: 1)),
        );
  }

  String _profileOrFallbackLocationLabel() {
    final value = profileLocationNotifier.value.trim();
    return value.isEmpty ? _fallbackLabel : value;
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await _loadPrayerData(showLoader: false);
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  void _seedLocalPrayerPreview() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final todaySchedule = _service.calculateFallback(
      date: today,
      latitude: _baitulMukarramLat,
      longitude: _baitulMukarramLng,
    );
    final tomorrowSchedule = _service.calculateFallback(
      date: tomorrow,
      latitude: _baitulMukarramLat,
      longitude: _baitulMukarramLng,
    );

    setState(() {
      _now = now;
      _todaySchedule = todaySchedule;
      _tomorrowSchedule = tomorrowSchedule;
      _locationLabel = _profileOrFallbackLocationLabel();
      _usingFallbackLocation = true;
      _usingOfflineCalculation = true;
      _isLoading = false;
      _isSyncing = true;
    });
    _updateActivePrayer();
  }

  Future<void> _loadPrayerData({required bool showLoader}) async {
    final hasExistingPreview = _todaySchedule != null && _tomorrowSchedule != null;
    if (mounted) {
      setState(() {
        _isSyncing = true;
        if (showLoader && !hasExistingPreview) {
          _isLoading = true;
        }
      });
    } else {
      _isSyncing = true;
      if (showLoader && !hasExistingPreview) {
        _isLoading = true;
      }
    }

    final resolved = await _resolveCoordinatesAndLabel();
    final today = DateTime(_now.year, _now.month, _now.day);
    final tomorrow = today.add(const Duration(days: 1));

    DailyPrayerSchedule todaySchedule;
    DailyPrayerSchedule tomorrowSchedule;
    var usedOfflineFallback = false;

    try {
      final result = await Future.wait<DailyPrayerSchedule>([
        _service.fetchFromApi(
          date: today,
          latitude: resolved.latitude,
          longitude: resolved.longitude,
        ),
        _service.fetchFromApi(
          date: tomorrow,
          latitude: resolved.latitude,
          longitude: resolved.longitude,
        ),
      ]);
      todaySchedule = result[0];
      tomorrowSchedule = result[1];
    } catch (_) {
      usedOfflineFallback = true;
      todaySchedule = _service.calculateFallback(
        date: today,
        latitude: resolved.latitude,
        longitude: resolved.longitude,
      );
      tomorrowSchedule = _service.calculateFallback(
        date: tomorrow,
        latitude: resolved.latitude,
        longitude: resolved.longitude,
      );
    }

    if (!mounted) return;
    setState(() {
      _todaySchedule = todaySchedule;
      _tomorrowSchedule = tomorrowSchedule;
      _locationLabel = resolved.label;
      _usingFallbackLocation = resolved.usingFallbackLocation;
      _usingOfflineCalculation = usedOfflineFallback;
      _isLoading = false;
      _isSyncing = false;
      _now = DateTime.now();
    });
    _updateActivePrayer();
  }

  Future<
    ({
      double latitude,
      double longitude,
      String label,
      bool usingFallbackLocation,
    })
  > _resolveCoordinatesAndLabel() async {
    if (!useDeviceLocationNotifier.value) {
      return (
        latitude: _baitulMukarramLat,
        longitude: _baitulMukarramLng,
        label: _profileOrFallbackLocationLabel(),
        usingFallbackLocation: true,
      );
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return (
          latitude: _baitulMukarramLat,
          longitude: _baitulMukarramLng,
          label: _profileOrFallbackLocationLabel(),
          usingFallbackLocation: true,
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return (
          latitude: _baitulMukarramLat,
          longitude: _baitulMukarramLng,
          label: _profileOrFallbackLocationLabel(),
          usingFallbackLocation: true,
        );
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

      final label = await _resolveLocationLabel(
        position.latitude,
        position.longitude,
      );
      return (
        latitude: position.latitude,
        longitude: position.longitude,
        label: label,
        usingFallbackLocation: false,
      );
    } catch (_) {
      return (
        latitude: _baitulMukarramLat,
        longitude: _baitulMukarramLng,
        label: _profileOrFallbackLocationLabel(),
        usingFallbackLocation: true,
      );
    }
  }

  Future<String> _resolveLocationLabel(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) return _profileOrFallbackLocationLabel();
      final place = placemarks.first;
      final city =
          place.locality ??
          place.subAdministrativeArea ??
          place.administrativeArea ??
          'Current location';
      final area = place.administrativeArea ?? place.country ?? '';
      final label = area.isNotEmpty ? '$city, $area' : city;
      if (profileLocationNotifier.value != label) {
        profileLocationNotifier.value = label;
        await saveAppPreferences();
      }
      return label;
    } catch (_) {
      return _profileOrFallbackLocationLabel();
    }
  }

  void _updateActivePrayer() {
    final today = _todaySchedule;
    final tomorrow = _tomorrowSchedule;
    if (today == null || tomorrow == null || !mounted) return;

    final list = <({String key, DateTime at})>[
      (key: 'Fajr', at: today.fajr),
      (key: 'Zuhr', at: today.dzuhr),
      (key: 'Asr', at: today.asr),
      (key: 'Maghrib', at: today.maghrib),
      (key: 'Isha', at: today.isha),
    ];

    ({String key, DateTime at})? nextPrayer;
    var nextIndex = -1;
    for (var i = 0; i < list.length; i++) {
      if (list[i].at.isAfter(_now)) {
        nextPrayer = list[i];
        nextIndex = i;
        break;
      }
    }

    DateTime previousBoundary;
    if (nextPrayer == null) {
      nextPrayer = (key: 'Fajr', at: tomorrow.fajr);
      previousBoundary = today.isha;
    } else if (nextIndex == 0) {
      previousBoundary = today.isha.subtract(const Duration(days: 1));
    } else {
      previousBoundary = list[nextIndex - 1].at;
    }

    var remaining = nextPrayer.at.difference(_now);
    if (remaining.isNegative) remaining = Duration.zero;

    final fullWindow = nextPrayer.at.difference(previousBoundary);
    final progress = fullWindow.inMilliseconds <= 0
        ? 0.0
        : ((fullWindow.inMilliseconds - remaining.inMilliseconds) /
                  fullWindow.inMilliseconds)
              .clamp(0.0, 1.0);

    setState(() {
      _activePrayer = nextPrayer!.key;
      _nextPrayerAt = nextPrayer.at;
      _remaining = remaining;
      _elapsedProgress = progress;
    });
  }

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _localizedPrayer(String key) {
    if (!_isBangla) return key;
    const map = {
      'Fajr': 'Fajr',
      'Sunrise': 'Sunrise',
      'Zuhr': 'Zuhr',
      'Asr': 'Asr',
      'Maghrib': 'Maghrib',
      'Isha': 'Isha',
    };
    return map[key] ?? key;
  }

  String _formatTime(DateTime? value) {
    if (value == null) return '--:--';
    final hour12 = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final amPm = value.hour < 12 ? 'AM' : 'PM';
    final out = '$hour12:$minute $amPm';
    return _isBangla ? _toBanglaDigits(out) : out;
  }

  String _formatRemaining() {
    final safe = _remaining.isNegative ? Duration.zero : _remaining;
    final hh = safe.inHours.toString().padLeft(2, '0');
    final mm = (safe.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (safe.inSeconds % 60).toString().padLeft(2, '0');
    final out = '$hh:$mm:$ss';
    return _isBangla ? _toBanglaDigits(out) : out;
  }

  String _toBanglaDigits(String input) {
    const latin = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bangla = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    var output = input;
    for (var i = 0; i < latin.length; i++) {
      output = output.replaceAll(latin[i], bangla[i]);
    }
    return output;
  }

  List<({String key, IconData icon, DateTime? time, String subtitle})>
  _prayerCards() {
    final today = _todaySchedule;
    return [
      (
        key: 'Fajr',
        icon: Icons.wb_twilight_rounded,
        time: today?.fajr,
        subtitle: _text('Dawn prayer', 'Dawn prayer'),
      ),
      (
        key: 'Zuhr',
        icon: Icons.wb_sunny_rounded,
        time: today?.dzuhr,
        subtitle: _text('Midday prayer', 'Midday prayer'),
      ),
      (
        key: 'Asr',
        icon: Icons.brightness_5_rounded,
        time: today?.asr,
        subtitle: _text('Afternoon prayer', 'Afternoon prayer'),
      ),
      (
        key: 'Maghrib',
        icon: Icons.bedtime_rounded,
        time: today?.maghrib,
        subtitle: _text('Sunset prayer', 'Sunset prayer'),
      ),
      (
        key: 'Isha',
        icon: Icons.nightlight_round,
        time: today?.isha,
        subtitle: _text('Night prayer', 'Night prayer'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    final ringProgress = (1.0 - _elapsedProgress).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: glass.bgBottom,
      body: NoorifyGlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                    children: [
                      NoorifyGlassCard(
                        radius: BorderRadius.circular(24),
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                  return;
                                }
                                Navigator.of(
                                  context,
                                ).pushReplacementNamed(RouteNames.discover);
                              },
                              style: IconButton.styleFrom(
                                backgroundColor: glass.isDark
                                    ? const Color(0x332EB8E6)
                                    : const Color(0x221EA8B8),
                                foregroundColor: glass.accent,
                              ),
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _text('Prayer Times', 'Prayer Times'),
                                    style: TextStyle(
                                      color: glass.textPrimary,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _locationLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: glass.textSecondary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (_isSyncing) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      _text(
                                        'Syncing location and online data...',
                                        'Syncing location and online data...',
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: glass.accentSoft,
                                        fontSize: 10.8,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _isRefreshing ? null : _refresh,
                              style: IconButton.styleFrom(
                                backgroundColor: glass.isDark
                                    ? const Color(0x332EB8E6)
                                    : const Color(0x221EA8B8),
                                foregroundColor: glass.accent,
                              ),
                              icon: _isRefreshing
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: glass.accent,
                                      ),
                                    )
                                  : const Icon(Icons.refresh_rounded),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      NoorifyGlassCard(
                        radius: BorderRadius.circular(24),
                        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                        child: _isLoading
                            ? SizedBox(
                                height: 220,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: glass.accent,
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  SizedBox(
                                    width: 210,
                                    height: 210,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        SizedBox(
                                          width: 190,
                                          height: 190,
                                          child: CircularProgressIndicator(
                                            value: 1,
                                            strokeWidth: 11,
                                            color: glass.isDark
                                                ? const Color(0x2248D4EE)
                                                : const Color(0x44B7DCEB),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 190,
                                          height: 190,
                                          child: CircularProgressIndicator(
                                            value: ringProgress,
                                            strokeWidth: 11,
                                            strokeCap: StrokeCap.round,
                                            color: glass.accent,
                                            backgroundColor:
                                                Colors.transparent,
                                          ),
                                        ),
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _text(
                                                'Next Prayer',
                                                'Next Prayer',
                                              ),
                                              style: TextStyle(
                                                color: glass.textSecondary,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _localizedPrayer(_activePrayer),
                                              style: TextStyle(
                                                color: glass.textPrimary,
                                                fontSize: 28,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _formatRemaining(),
                                              style: TextStyle(
                                                color: glass.accentSoft,
                                                fontSize: 26,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _text(
                                                'Remaining',
                                                'Remaining',
                                              ),
                                              style: TextStyle(
                                                color: glass.textMuted,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: glass.isDark
                                                    ? const Color(0x222EB8E6)
                                                    : const Color(0x251EA8B8),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                                border: Border.all(
                                                  color: glass.glassBorder,
                                                ),
                                              ),
                                              child: Text(
                                                _formatTime(_nextPrayerAt),
                                                style: TextStyle(
                                                  color: glass.textPrimary,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (_usingFallbackLocation ||
                                      _usingOfflineCalculation)
                                    Text(
                                      _usingOfflineCalculation
                                          ? _text(
                                              'Using offline prayer calculation',
                                              'Using offline prayer calculation',
                                            )
                                          : _text(
                                              'Using saved location',
                                              'Using saved location',
                                            ),
                                      style: TextStyle(
                                        color: glass.textSecondary,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _prayerCards().length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 1.22,
                            ),
                        itemBuilder: (context, index) {
                          final item = _prayerCards()[index];
                          final isActive = item.key == _activePrayer;
                          return _PrayerTimeCard(
                            title: _localizedPrayer(item.key),
                            subtitle: item.subtitle,
                            time: _formatTime(item.time),
                            icon: item.icon,
                            isActive: isActive,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(44),
                                side: BorderSide(color: glass.glassBorder),
                                foregroundColor: glass.textPrimary,
                              ),
                              onPressed: () => Navigator.of(
                                context,
                              ).pushNamed(RouteNames.prayerCompass),
                              icon: const Icon(Icons.explore_rounded),
                              label: Text(
                                _text('Open Qibla', 'Open Qibla'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(44),
                                backgroundColor: glass.accent,
                                foregroundColor: glass.isDark
                                    ? const Color(0xFF082733)
                                    : Colors.white,
                              ),
                              onPressed: _isRefreshing ? null : _refresh,
                              icon: const Icon(Icons.refresh_rounded),
                              label: Text(_text('Refresh', 'Refresh')),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              bottomNav(context, 3),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrayerTimeCard extends StatelessWidget {
  const _PrayerTimeCard({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.isActive,
  });

  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    final activeBg = glass.isDark
        ? const [Color(0xFF1E353F), Color(0xFF123340)]
        : const [Color(0xFFE5FAFF), Color(0xFFD8F4FB)];
    final idleBg = glass.isDark
        ? const [Color(0xFF121F2E), Color(0xFF0D1824)]
        : const [Color(0xFFF7FCFF), Color(0xFFEAF4FB)];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: isActive ? activeBg : idleBg,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isActive
              ? glass.accent.withValues(alpha: 0.7)
              : glass.glassBorder,
          width: isActive ? 1.4 : 1,
        ),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: glass.accent.withValues(alpha: 0.22),
              blurRadius: 16,
              spreadRadius: 0.4,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: glass.accent.withValues(alpha: isActive ? 0.22 : 0.12),
                ),
                child: Icon(icon, size: 17, color: glass.accent),
              ),
              const Spacer(),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: glass.accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Active',
                    style: TextStyle(
                      color: glass.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: TextStyle(
              color: glass.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            time,
            style: TextStyle(
              color: isActive ? glass.accent : glass.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: glass.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
