import 'package:flutter/material.dart';

import '../app/app_globals.dart';
import '../widgets/bottom_nav.dart';

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
                    radius: 28,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE1E8EC)),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Language',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    ValueListenableBuilder<AppLanguage>(
                      valueListenable: appLanguageNotifier,
                      builder: (context, language, _) {
                        return ToggleButtons(
                          borderRadius: BorderRadius.circular(8),
                          isSelected: [
                            language == AppLanguage.english,
                            language == AppLanguage.bangla,
                          ],
                          onPressed: (index) {
                            appLanguageNotifier.value = index == 0
                                ? AppLanguage.english
                                : AppLanguage.bangla;
                          },
                          children: const [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('English'),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('Bangla'),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE1E8EC)),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Use Device Location',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Off = Baitul Mukarram, Dhaka',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: useDeviceLocationNotifier,
                      builder: (context, enabled, _) {
                        return Switch(
                          value: enabled,
                          onChanged: (v) => useDeviceLocationNotifier.value = v,
                          activeThumbColor: const Color(0xFF14A3B8),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE1E8EC)),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Sehri Alert',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    ValueListenableBuilder<bool>(
                      valueListenable: sehriAlertEnabledNotifier,
                      builder: (context, enabled, _) {
                        return Switch(
                          value: enabled,
                          onChanged: (v) => sehriAlertEnabledNotifier.value = v,
                          activeThumbColor: const Color(0xFF14A3B8),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE1E8EC)),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Iftar Alert',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    ValueListenableBuilder<bool>(
                      valueListenable: iftarAlertEnabledNotifier,
                      builder: (context, enabled, _) {
                        return Switch(
                          value: enabled,
                          onChanged: (v) => iftarAlertEnabledNotifier.value = v,
                          activeThumbColor: const Color(0xFF14A3B8),
                        );
                      },
                    ),
                  ],
                ),
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
            bottomNav(context, 4),
          ],
        ),
      ),
    );
  }
}
