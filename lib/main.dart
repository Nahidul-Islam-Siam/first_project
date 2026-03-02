import 'package:flutter/material.dart';

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
        fontFamily: 'sans-serif',
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
      appBar: AppBar(
        title: const Text('UI Mock Screens'),
      ),
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
                      Icon(Icons.nightlight_round, color: Color(0xFF65DDFF), size: 46),
                      SizedBox(height: 8),
                      Icon(Icons.menu_book_rounded, color: Color(0xFF65DDFF), size: 90),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 260,
                child: CustomPaint(
                  painter: _MosqueSilhouettePainter(),
                ),
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
      ..shader = const RadialGradient(
        colors: [Color(0xFFCFD978), Color(0x00CFD978)],
      ).createShader(Rect.fromCircle(center: Offset(size.width * 0.6, size.height * 0.7), radius: 80));

    canvas.drawCircle(Offset(size.width * 0.62, size.height * 0.74), 64, glow);

    final domePath = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width * 0.2, size.height)
      ..lineTo(size.width * 0.2, size.height * 0.72)
      ..quadraticBezierTo(size.width * 0.34, size.height * 0.28, size.width * 0.5, size.height * 0.72)
      ..lineTo(size.width * 0.5, size.height)
      ..lineTo(size.width * 0.74, size.height)
      ..lineTo(size.width * 0.74, size.height * 0.68)
      ..lineTo(size.width * 0.79, size.height * 0.68)
      ..lineTo(size.width * 0.79, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, size.height * 0.86)
      ..quadraticBezierTo(size.width * 0.9, size.height * 0.76, size.width * 0.8, size.height * 0.86)
      ..lineTo(size.width * 0.55, size.height * 0.86)
      ..quadraticBezierTo(size.width * 0.36, size.height * 0.78, size.width * 0.16, size.height * 0.86)
      ..lineTo(0, size.height * 0.86)
      ..close();
    canvas.drawPath(domePath, skyline);

    final minaret = Paint()..color = const Color(0xFF0C5F6A);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.3, size.height * 0.34, 10, size.height * 0.52), minaret);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.82, size.height * 0.3, 10, size.height * 0.56), minaret);

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
      suffixIcon: icon != null ? Icon(icon, size: 14, color: const Color(0xFF7DDDF2)) : null,
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
                      style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 20),
                    TextField(decoration: _fieldStyle('muslim@gmail.com', icon: Icons.alternate_email)),
                    const SizedBox(height: 10),
                    TextField(decoration: _fieldStyle('Name', icon: Icons.person_outline)),
                    const SizedBox(height: 10),
                    TextField(decoration: _fieldStyle('Confirm Password', icon: Icons.visibility_outlined)),
                    const SizedBox(height: 10),
                    Row(
                      children: const [
                        Icon(Icons.toggle_on, color: Color(0xFF84E4F5), size: 18),
                        SizedBox(width: 6),
                        Text('Save my info?', style: TextStyle(color: Color(0xFF8ECFE4), fontSize: 10)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: const LinearGradient(colors: [Color(0xFF6CF1FF), Color(0xFF15C9E4)]),
                      ),
                      child: const Center(
                        child: Text('SIGN UP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Center(child: Text('OR', style: TextStyle(color: Colors.white70, fontSize: 11))),
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
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 11)),
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
  State<ProfilePreferencesScreen> createState() => _ProfilePreferencesScreenState();
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
                  const CircleAvatar(radius: 18, child: Icon(Icons.person, size: 18)),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Nuha Mvhed Zunader', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('Done namaj 30/30', style: TextStyle(fontSize: 11, color: Colors.blueGrey)),
                    ],
                  ),
                  const Spacer(),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  const Text('General', style: TextStyle(fontSize: 11, color: Colors.black54)),
                  ...values.entries.map(
                    (e) => SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(e.key, style: const TextStyle(fontSize: 13)),
                      subtitle: const Text('Lorem ipsum description', style: TextStyle(fontSize: 10)),
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
                  Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                const CircleAvatar(
                  radius: 42,
                  backgroundImage: NetworkImage('https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=300'),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Color(0xFF14A3B8), shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
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

class DailyActivityScreen extends StatelessWidget {
  const DailyActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              decoration: const BoxDecoration(
                color: Color(0xFF17A6B8),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Text('14:01', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
                      Spacer(),
                      Text('03 Ramadan 1446', style: TextStyle(color: Colors.white, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      _Pill(label: 'Fajr', time: '6:06'),
                      _Pill(label: 'Dhuhr', time: '1:15'),
                      _Pill(label: 'Asr', time: '4:42'),
                      _Pill(label: 'Magrib', time: '6:12'),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    const Expanded(child: Text('30/30', style: TextStyle(fontWeight: FontWeight.w600))),
                    const SizedBox(width: 6),
                    _chip('All'),
                    const SizedBox(width: 6),
                    _chip('Prayer', active: true),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: const [
                  _ActivityRow(title: 'Breakfast', subtitle: 'What are you eating today?', status: '+'),
                  _ActivityRow(title: 'Learn the Holy Quran', subtitle: 'Ayat to learn today', status: '0/4'),
                  _ActivityRow(title: 'Zikir', subtitle: 'SubhanAllah 100', status: '0/5'),
                  _ActivityRow(title: 'Daily Tasbeeh', subtitle: 'SubhanAllah 33', status: '1/3'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            _bottomNav(0),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, {bool active = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF14A3B8) : const Color(0xFFE9EEF0),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(text, style: TextStyle(color: active ? Colors.white : Colors.black87, fontSize: 11)),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.time});

  final String label;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: const Color(0x2FFFFFFF), borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
          const SizedBox(height: 2),
          Text(time, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.title, required this.subtitle, required this.status});

  final String title;
  final String subtitle;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.black54)),
              ],
            ),
          ),
          Text(status, style: const TextStyle(fontSize: 11, color: Colors.black54)),
          const SizedBox(width: 6),
          const Icon(Icons.radio_button_unchecked, color: Color(0xFF7FA7B5), size: 16),
        ],
      ),
    );
  }
}

Widget _bottomNav(int active) {
  final items = [
    ('Home', Icons.home_filled),
    ('Search', Icons.search),
    ('Plan', Icons.view_agenda_outlined),
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
            Icon(item.$2, size: 20, color: isActive ? const Color(0xFF14A3B8) : Colors.black45),
            const SizedBox(height: 2),
            Text(
              item.$1,
              style: TextStyle(fontSize: 10, color: isActive ? const Color(0xFF14A3B8) : Colors.black45),
            ),
          ],
        );
      }),
    ),
  );
}
