import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../app/app_globals.dart';
import '../app/route_names.dart';
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

  Future<void> _clearCache() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Clear Cache'),
          content: const Text(
            'This will remove offline Quran text/audio cache and temporary app data.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (shouldClear != true) return;
    await DefaultCacheManager().emptyCache();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Cache cleared')));
  }

  Future<void> _openRoute(String routeName) async {
    await Navigator.of(context).pushNamed(routeName);
  }

  Future<void> _toggleSehriAlert(bool enabled) async {
    if (!enabled) {
      sehriAlertEnabledNotifier.value = false;
      return;
    }
    final granted = await ensureNotificationPermissions();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification permission is required')),
        );
      }
      sehriAlertEnabledNotifier.value = false;
      return;
    }
    sehriAlertEnabledNotifier.value = true;
  }

  Future<void> _togglePrayerAlerts(bool enabled) async {
    if (!enabled) {
      prayerAlertsEnabledNotifier.value = false;
      return;
    }
    final granted = await ensureNotificationPermissions();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification permission is required')),
        );
      }
      prayerAlertsEnabledNotifier.value = false;
      return;
    }
    prayerAlertsEnabledNotifier.value = true;
  }

  Future<void> _toggleIftarAlert(bool enabled) async {
    if (!enabled) {
      iftarAlertEnabledNotifier.value = false;
      return;
    }
    final granted = await ensureNotificationPermissions();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification permission is required')),
        );
      }
      iftarAlertEnabledNotifier.value = false;
      return;
    }
    iftarAlertEnabledNotifier.value = true;
  }

  Future<void> _testAlertNow({required bool sehri}) async {
    final granted = await ensureNotificationPermissions();
    if (!granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enable notification permission first')),
      );
      return;
    }

    final tone = alertToneNotifier.value;
    final playSound = alertTonePlaySound(tone);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelIdForTone(sehri ? 'sehri_alert_channel' : 'iftar_alert_channel'),
        sehri ? 'Sehri Alerts' : 'Iftar Alerts',
        channelDescription: sehri
            ? 'Alert when Sehri time starts (${alertToneLabel(tone)})'
            : 'Alert when Iftar time starts (${alertToneLabel(tone)})',
        importance: Importance.max,
        priority: Priority.high,
        playSound: playSound,
        sound: alertToneSound(tone),
        audioAttributesUsage: alertToneUsage(tone),
      ),
      iOS: DarwinNotificationDetails(presentSound: playSound),
    );

    await localNotificationsPlugin.show(
      sehri ? 9001 : 9002,
      sehri ? 'Sehri Alert (Test)' : 'Iftar Alert (Test)',
      sehri
          ? 'Test notification for Sehri alert is working.'
          : 'Test notification for Iftar alert is working.',
      details,
      payload: sehri ? 'sehri_test' : 'iftar_test',
    );

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Test alert sent')));
  }

  Future<void> _selectAlertTone(AppAlertTone? tone) async {
    if (tone == null || tone == alertToneNotifier.value) return;
    final granted = await ensureNotificationPermissions();
    if (!granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enable notification permission first')),
      );
      return;
    }

    alertToneNotifier.value = tone;
    await saveAlertTonePreference(tone);
    if (!mounted) return;
    final message = tone == AppAlertTone.adhan
        ? 'Alert tone: ${alertToneLabel(tone)}. Add adhan_alert.mp3 in android/app/src/main/res/raw/'
        : 'Alert tone: ${alertToneLabel(tone)}';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

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
                      'Prayer Alerts',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    ValueListenableBuilder<bool>(
                      valueListenable: prayerAlertsEnabledNotifier,
                      builder: (context, enabled, _) {
                        return Switch(
                          value: enabled,
                          onChanged: _togglePrayerAlerts,
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
                          onChanged: _toggleSehriAlert,
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
                          onChanged: _toggleIftarAlert,
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Alert Tone',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Separate sound profile for app alerts',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'For Adhan tone: res/raw/adhan_alert.mp3',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ValueListenableBuilder<AppAlertTone>(
                      valueListenable: alertToneNotifier,
                      builder: (context, tone, _) {
                        return DropdownButtonHideUnderline(
                          child: DropdownButton<AppAlertTone>(
                            value: tone,
                            borderRadius: BorderRadius.circular(10),
                            items: AppAlertTone.values.map((item) {
                              return DropdownMenuItem<AppAlertTone>(
                                value: item,
                                child: Text(alertToneLabel(item)),
                              );
                            }).toList(),
                            onChanged: _selectAlertTone,
                          ),
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
                  const SizedBox(height: 12),
                  const Text(
                    'App',
                    style: TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                  Card(
                    margin: const EdgeInsets.only(top: 8),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.privacy_tip_outlined),
                          title: const Text('Privacy Policy'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _openRoute(RouteNames.privacyPolicy),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.info_outline),
                          title: const Text('About & Version'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _openRoute(RouteNames.about),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(
                            Icons.delete_sweep_outlined,
                            color: Color(0xFFE74A5A),
                          ),
                          title: const Text('Clear Cache'),
                          subtitle: const Text(
                            'Remove offline Quran data and temporary files',
                          ),
                          onTap: _clearCache,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.notifications_active),
                          title: const Text('Test Sehri Alert'),
                          subtitle: const Text('Send notification now'),
                          onTap: () => _testAlertNow(sehri: true),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(
                            Icons.notifications_active_outlined,
                          ),
                          title: const Text('Test Iftar Alert'),
                          subtitle: const Text('Send notification now'),
                          onTap: () => _testAlertNow(sehri: false),
                        ),
                      ],
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
