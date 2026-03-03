import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {  
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Design Preview',
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      ),
      home: const UiPreviewHome(),
    );
  }
}

class UiPreviewHome extends StatelessWidget {
  const UiPreviewHome({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <({String title, Widget page})>[
      (title: 'Splash Screen', page: const RamadanSplashScreen()),
      (title: 'Sign Up Screen', page: const SignupScreen()),
      (title: 'Profile Preferences', page: const ProfilePreferencesScreen()),
      (title: 'Edit Profile', page: const EditProfileScreen()),
      (title: 'Daily Activity', page: const DailyActivityScreen()),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('UI Mock Screens')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return FilledButton.tonal(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => item.page),
              );
            },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(item.title),
          );
        },
      ),
    );
  }
}

class RamadanSplashScreen extends StatelessWidget {
  const RamadanSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2951B9),
              Color(0xFF2A6D8A),
              Color(0xFF5F8D73),
              Color(0xFF0D6D78),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.nightlight_round,
                        color: Color(0xFF65DDFF),
                        size: 46,
                      ),
                      SizedBox(height: 8),
                      Icon(
                        Icons.menu_book_rounded,
                        color: Color(0xFF65DDFF),
                        size: 90,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 260,
                child: CustomPaint(painter: _MosqueSilhouettePainter()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MosqueSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final skyline = Paint()..color = const Color(0xFF0C5F6A);
    final glow = Paint()
      ..shader =
          const RadialGradient(
            colors: [Color(0xFFCFD978), Color(0x00CFD978)],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.6, size.height * 0.7),
              radius: 80,
            ),
          );

    canvas.drawCircle(Offset(size.width * 0.62, size.height * 0.74), 64, glow);

    final domePath = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width * 0.2, size.height)
      ..lineTo(size.width * 0.2, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.34,
        size.height * 0.28,
        size.width * 0.5,
        size.height * 0.72,
      )
      ..lineTo(size.width * 0.5, size.height)
      ..lineTo(size.width * 0.74, size.height)
      ..lineTo(size.width * 0.74, size.height * 0.68)
      ..lineTo(size.width * 0.79, size.height * 0.68)
      ..lineTo(size.width * 0.79, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, size.height * 0.86)
      ..quadraticBezierTo(
        size.width * 0.9,
        size.height * 0.76,
        size.width * 0.8,
        size.height * 0.86,
      )
      ..lineTo(size.width * 0.55, size.height * 0.86)
      ..quadraticBezierTo(
        size.width * 0.36,
        size.height * 0.78,
        size.width * 0.16,
        size.height * 0.86,
      )
      ..lineTo(0, size.height * 0.86)
      ..close();
    canvas.drawPath(domePath, skyline);

    final minaret = Paint()..color = const Color(0xFF0C5F6A);
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.3,
        size.height * 0.34,
        10,
        size.height * 0.52,
      ),
      minaret,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.82,
        size.height * 0.3,
        10,
        size.height * 0.56,
      ),
      minaret,
    );

    final tip1 = Path()
      ..moveTo(size.width * 0.29, size.height * 0.34)
      ..lineTo(size.width * 0.35, size.height * 0.34)
      ..lineTo(size.width * 0.32, size.height * 0.2)
      ..close();
    canvas.drawPath(tip1, minaret);

    final tip2 = Path()
      ..moveTo(size.width * 0.81, size.height * 0.3)
      ..lineTo(size.width * 0.87, size.height * 0.3)
      ..lineTo(size.width * 0.84, size.height * 0.16)
      ..close();
    canvas.drawPath(tip2, minaret);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  InputDecoration _fieldStyle(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF8BC8E1), fontSize: 11),
      filled: true,
      fillColor: const Color(0x22A9D9FF),
      suffixIcon: icon != null
          ? Icon(icon, size: 14, color: const Color(0xFF7DDDF2))
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2C8BC8), Color(0xFF0A2D72)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0x22000000),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'Sign Up',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      decoration: _fieldStyle(
                        'muslim@gmail.com',
                        icon: Icons.alternate_email,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      decoration: _fieldStyle(
                        'Name',
                        icon: Icons.person_outline,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      decoration: _fieldStyle(
                        'Confirm Password',
                        icon: Icons.visibility_outlined,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: const [
                        Icon(
                          Icons.toggle_on,
                          color: Color(0xFF84E4F5),
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Save my info?',
                          style: TextStyle(
                            color: Color(0xFF8ECFE4),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6CF1FF), Color(0xFF15C9E4)],
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'SIGN UP',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Center(
                      child: Text(
                        'OR',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _socialBtn('Continue with Phone', Icons.phone_android),
                    const SizedBox(height: 8),
                    _socialBtn('Continue with Google', Icons.g_mobiledata),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialBtn(String text, IconData icon) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0x1FFFFFFF),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(width: 6),
          Icon(icon, size: 16, color: Colors.white),
        ],
      ),
    );
  }
}

class ProfilePreferencesScreen extends StatefulWidget {
  const ProfilePreferencesScreen({super.key});

  @override
  State<ProfilePreferencesScreen> createState() =>
      _ProfilePreferencesScreenState();
}

class _ProfilePreferencesScreenState extends State<ProfilePreferencesScreen> {
  final values = <String, bool>{
    'Prayer Time': true,
    'Quran Verses': true,
    'Prayer Learning': false,
    'Daily Tasbeeh': true,
    'Zikir Times': false,
    'Daily Newsfeed': true,
    'Dua Reminder': false,
    'Hadith Notification': true,
    'Email Notification': true,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    child: Icon(Icons.person, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Nuha Mvhed Zunader',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Done namaj 30/30',
                        style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  const Text(
                    'General',
                    style: TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                  ...values.entries.map(
                    (e) => SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(e.key, style: const TextStyle(fontSize: 13)),
                      subtitle: const Text(
                        'Lorem ipsum description',
                        style: TextStyle(fontSize: 10),
                      ),
                      value: e.value,
                      activeThumbColor: const Color(0xFF14A3B8),
                      onChanged: (v) => setState(() => values[e.key] = v),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 38),
                  backgroundColor: const Color(0xFFE74A5A),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {},
                child: const Text('Logout'),
              ),
            ),
            _bottomNav(2),
          ],
        ),
      ),
    );
  }
}

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.arrow_back_ios, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Edit Profile',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                const CircleAvatar(
                  radius: 42,
                  backgroundColor: Color(0xFFD9DEE3),
                  child: Icon(Icons.person, size: 42, color: Color(0xFF6F8DA1)),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF14A3B8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8ECEF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Text('Nuha Mvhed Zunader', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                  backgroundColor: const Color(0xFF14A3B8),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {},
                child: const Text('Save Change'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DailyActivityScreen extends StatefulWidget {
  const DailyActivityScreen({super.key});

  @override
  State<DailyActivityScreen> createState() => _DailyActivityScreenState();
}

class _DailyActivityScreenState extends State<DailyActivityScreen> {
  static const _dhakaLat = 23.8103;
  static const _dhakaLng = 90.4125;

  late final Timer _clockTimer;
  DateTime _now = DateTime.now();
  double? _latitude;
  double? _longitude;
  DateTime? _lastPrayerCalcDate;
  String _locationLabel = 'Detecting location...';
  String _countdownLabel = 'Calculating prayer...';
  String _activePrayer = 'Dzuhr';
  Map<String, String> _prayerTimes = const {

    'Fajr': '--:--',
    'Dzuhr': '--:--',
    'Ashr': '--:--',
    'Maghrib': '--:--',
    'Isha': '--:--',
  };

  int _completedDaily = 3;
  final int _dailyGoal = 6;

  final List<_ActivityItem> _activities = [
    _ActivityItem(title: 'Alms', done: 4, total: 10),
    _ActivityItem(title: 'Recite the Al Quran', done: 8, total: 10),
  ];

  @override
  void initState() {
    super.initState();
    _loadPrayerData();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
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
    _clockTimer.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final hour12 = (_now.hour % 12 == 0) ? 12 : _now.hour % 12;
    final minute = _now.minute.toString().padLeft(2, '0');
    return '$hour12:$minute';
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

  void _recalculatePrayerTimesForToday() {
    if (_latitude == null || _longitude == null) return;

    final params = CalculationMethodParameters.karachi();
    params.madhab = Madhab.hanafi;
    final prayers = PrayerTimes(
      date: DateTime.now(),
      coordinates: Coordinates(_latitude!, _longitude!),
      calculationParameters: params,
    );

    final fajr = prayers.fajr.toLocal();
    final dzuhr = prayers.dhuhr.toLocal();
    final ashr = prayers.asr.toLocal();
    final maghrib = prayers.maghrib.toLocal();
    final isha = prayers.isha.toLocal();

    setState(() {
      _lastPrayerCalcDate = DateTime.now();
      _prayerTimes = {
        'Fajr': _formatPrayerTime(fajr),
        'Dzuhr': _formatPrayerTime(dzuhr),
        'Ashr': _formatPrayerTime(ashr),
        'Maghrib': _formatPrayerTime(maghrib),
        'Isha': _formatPrayerTime(isha),
      };
      _activePrayer = _nextPrayerName(
        now: _now,
        fajr: fajr,
        dzuhr: dzuhr,
        ashr: ashr,
        maghrib: maghrib,
        isha: isha,
      );
      _countdownLabel = _countdownToNextPrayer(
        now: _now,
        fajr: fajr,
        dzuhr: dzuhr,
        ashr: ashr,
        maghrib: maghrib,
        isha: isha,
      );
    });
  }

  void _updateCountdown() {
    if (_prayerTimes['Fajr'] == '--:--') return;
    if (_latitude == null || _longitude == null) return;
    final params = CalculationMethodParameters.karachi();
    params.madhab = Madhab.hanafi;
    final prayers = PrayerTimes(
      date: DateTime.now(),
      coordinates: Coordinates(_latitude!, _longitude!),
      calculationParameters: params,
    );

    final fajr = prayers.fajr.toLocal();
    final dzuhr = prayers.dhuhr.toLocal();
    final ashr = prayers.asr.toLocal();
    final maghrib = prayers.maghrib.toLocal();
    final isha = prayers.isha.toLocal();

    final nextName = _nextPrayerName(
      now: _now,
      fajr: fajr,
      dzuhr: dzuhr,
      ashr: ashr,
      maghrib: maghrib,
      isha: isha,
    );
    final nextCountdown = _countdownToNextPrayer(
      now: _now,
      fajr: fajr,
      dzuhr: dzuhr,
      ashr: ashr,
      maghrib: maghrib,
      isha: isha,
    );

    if (mounted &&
        (nextName != _activePrayer || nextCountdown != _countdownLabel)) {
      setState(() {
        _activePrayer = nextName;
        _countdownLabel = nextCountdown;
      });
    }
  }

  String _formatPrayerTime(DateTime time) {
    final h = (time.hour % 12 == 0 ? 12 : time.hour % 12).toString();
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _nextPrayerName({
    required DateTime now,
    required DateTime fajr,
    required DateTime dzuhr,
    required DateTime ashr,
    required DateTime maghrib,
    required DateTime isha,
  }) {
    final ordered = <MapEntry<String, DateTime>>[
      MapEntry('Fajr', fajr),
      MapEntry('Dzuhr', dzuhr),
      MapEntry('Ashr', ashr),
      MapEntry('Maghrib', maghrib),
      MapEntry('Isha', isha),
    ];
    for (final prayer in ordered) {
      if (prayer.value.isAfter(now)) return prayer.key;
    }
    return 'Fajr';
  }

  String _countdownToNextPrayer({
    required DateTime now,
    required DateTime fajr,
    required DateTime dzuhr,
    required DateTime ashr,
    required DateTime maghrib,
    required DateTime isha,
  }) {
    final ordered = <MapEntry<String, DateTime>>[
      MapEntry('Fajr', fajr),
      MapEntry('Dzuhr', dzuhr),
      MapEntry('Ashr', ashr),
      MapEntry('Maghrib', maghrib),
      MapEntry('Isha', isha),
    ];

    MapEntry<String, DateTime>? nextPrayer;
    for (final prayer in ordered) {
      if (prayer.value.isAfter(now)) {
        nextPrayer = prayer;
        break;
      }
    }
    nextPrayer ??= MapEntry('Fajr', fajr.add(const Duration(days: 1)));

    final diff = nextPrayer.value.difference(now);
    final hh = diff.inHours.toString().padLeft(2, '0');
    final mm = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '${nextPrayer.key} in $hh:$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1D98A9),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(24),
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF1FB7C7), Color(0xFF1D98A9)],
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
                            Spacer(),
                            Text(
                              _countdownLabel,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text(
                              '10 Ramadhan 1446 H',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
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
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _PrayerTile(
                                title: 'Fajr',
                                time: _prayerTimes['Fajr'] ?? '--:--',
                                active: _activePrayer == 'Fajr',
                              ),
                              const SizedBox(width: 8),
                              _PrayerTile(
                                title: 'Dzuhr',
                                time: _prayerTimes['Dzuhr'] ?? '--:--',
                                active: _activePrayer == 'Dzuhr',
                              ),
                              const SizedBox(width: 8),
                              _PrayerTile(
                                title: 'Ashr',
                                time: _prayerTimes['Ashr'] ?? '--:--',
                                active: _activePrayer == 'Ashr',
                              ),
                              const SizedBox(width: 8),
                              _PrayerTile(
                                title: 'Maghrib',
                                time: _prayerTimes['Maghrib'] ?? '--:--',
                                active: _activePrayer == 'Maghrib',
                              ),
                              const SizedBox(width: 8),
                              _PrayerTile(
                                title: 'Isha',
                                time: _prayerTimes['Isha'] ?? '--:--',
                                active: _activePrayer == 'Isha',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                children: [
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
            _bottomNav(0),
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
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: active ? const Color(0x33FFFFFF) : const Color(0x22FFFFFF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Icon(
            active ? Icons.wb_sunny_rounded : Icons.cloud_rounded,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(height: 4),
          Text(time, style: const TextStyle(color: Colors.white, fontSize: 12)),
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

Widget _bottomNav(int active) {
  final items = [
    ('Home', Icons.home_filled),
    ('Discover', Icons.explore_outlined),
    ('Quran', Icons.menu_book_outlined),
    ('Prayer', Icons.calendar_month_outlined),
    ('Profile', Icons.person_outline),
  ];

  return Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(items.length, (index) {
        final item = items[index];
        final isActive = index == active;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.$2,
              size: 20,
              color: isActive ? const Color(0xFF14A3B8) : Colors.black45,
            ),
            const SizedBox(height: 2),
            Text(
              item.$1,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? const Color(0xFF14A3B8) : Colors.black45,
              ),
            ),
          ],
        );
      }),
    ),
  );
}
