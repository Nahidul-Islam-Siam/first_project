import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

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
  static const _teal = Color(0xFF14A3B8);
  static const _line = Color(0xFFE5E8EC);
  static const _mutedText = Color(0xFF8A96A3);
  static const _titleText = Color(0xFF1F252D);

  Future<void> _openEditProfile() async {
    await Navigator.of(context).pushNamed(RouteNames.editProfile);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout now?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
    if (confirm != true || !mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(RouteNames.signIn, (route) => false);
  }

  Future<void> _setFontSize(AppFontSize value) async {
    appFontSizeNotifier.value = value;
    await saveAppPreferences();
  }

  Future<void> _setDarkTheme(bool value) async {
    darkThemeEnabledNotifier.value = value;
    await saveAppPreferences();
  }

  Future<void> _setShowLatinLetters(bool value) async {
    showLatinLettersNotifier.value = value;
    await saveAppPreferences();
  }

  Future<void> _setShowTranslation(bool value) async {
    showTranslationNotifier.value = value;
    await saveAppPreferences();
  }

  Future<void> _setShowTajweed(bool value) async {
    showTajweedNotifier.value = value;
    await saveAppPreferences();
  }

  Future<void> _setAdzanNotification(bool value) async {
    prayerAlertsEnabledNotifier.value = value;
    await saveAppPreferences();
  }

  Future<void> _setImsakNotification(bool value) async {
    sehriAlertEnabledNotifier.value = value;
    await saveAppPreferences();
  }

  Future<String?> _pickOption({
    required String title,
    required List<String> options,
    required String current,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const Divider(height: 1),
              ...options.map((option) {
                final selected = option == current;
                return ListTile(
                  title: Text(option),
                  trailing: selected ? const Icon(Icons.check, color: _teal) : null,
                  onTap: () => Navigator.of(sheetContext).pop(option),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectFontSize() async {
    final current = appFontSizeNotifier.value;
    final selected = await showModalBottomSheet<AppFontSize>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text(
                  'Font Size',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const Divider(height: 1),
              ...AppFontSize.values.map((size) {
                final selected = size == current;
                return ListTile(
                  title: Text(appFontSizeLabel(size)),
                  trailing: selected ? const Icon(Icons.check, color: _teal) : null,
                  onTap: () => Navigator.of(sheetContext).pop(size),
                );
              }),
            ],
          ),
        );
      },
    );
    if (selected == null || selected == current) return;
    await _setFontSize(selected);
  }

  Uint8List? _decodeProfilePhoto(String? base64) {
    if (base64 == null || base64.isEmpty) return null;
    try {
      return base64Decode(base64);
    } catch (_) {
      return null;
    }
  }

  Widget _avatar() {
    return ValueListenableBuilder<String?>(
      valueListenable: profilePhotoBase64Notifier,
      builder: (context, encoded, _) {
        final bytes = _decodeProfilePhoto(encoded);
        if (bytes != null) {
          return CircleAvatar(
            radius: 19,
            backgroundImage: MemoryImage(bytes),
            backgroundColor: Colors.white,
          );
        }
        return const CircleAvatar(
          radius: 19,
          backgroundColor: Color(0xFFCCD7E2),
          child: Icon(Icons.person, color: Color(0xFF6B7A8A), size: 19),
        );
      },
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 12, 6, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 10.5,
            color: _mutedText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _rowTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -2),
      leading: Icon(icon, size: 16, color: const Color(0xFF7B8A99)),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _titleText,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: _mutedText, height: 1.2),
            ),
      trailing:
          trailing ??
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFFB0BAC3),
            size: 18,
          ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      horizontalTitleGap: 10,
      minVerticalPadding: 6,
    );
  }

  Widget _switchRow({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return _rowTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: _teal,
        activeThumbColor: Colors.white,
        inactiveTrackColor: const Color(0xFFD4DCE3),
        inactiveThumbColor: const Color(0xFF90A2AF),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                    child: Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _titleText,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        _avatar(),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ValueListenableBuilder<String>(
                                valueListenable: profileNameNotifier,
                                builder: (context, name, _) {
                                  return Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: _titleText,
                                      fontSize: 13,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 1),
                              ValueListenableBuilder<String>(
                                valueListenable: profileLocationNotifier,
                                builder: (context, location, _) {
                                  return Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_rounded,
                                        color: _teal,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 3),
                                      Expanded(
                                        child: Text(
                                          location,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            color: _teal,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        color: Color(0xFFBAC4CD),
                                        size: 16,
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _openEditProfile,
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 17,
                            color: _mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _sectionLabel('General'),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        ValueListenableBuilder<AppFontSize>(
                          valueListenable: appFontSizeNotifier,
                          builder: (context, size, _) {
                            return _rowTile(
                              icon: Icons.text_fields_rounded,
                              title: 'Font Size',
                              subtitle: appFontSizeLabel(size),
                              onTap: _selectFontSize,
                            );
                          },
                        ),
                        const Divider(height: 1, color: _line),
                        ValueListenableBuilder<bool>(
                          valueListenable: darkThemeEnabledNotifier,
                          builder: (context, enabled, _) {
                            return _switchRow(
                              icon: Icons.dark_mode_outlined,
                              title: 'Dark Theme',
                              subtitle: 'Switch to dark color scheme',
                              value: enabled,
                              onChanged: _setDarkTheme,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  _sectionLabel('Prayer Setting'),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        ValueListenableBuilder<bool>(
                          valueListenable: showLatinLettersNotifier,
                          builder: (context, enabled, _) {
                            return _switchRow(
                              icon: Icons.short_text_rounded,
                              title: 'Show Latin Letters',
                              subtitle: 'Latin lyrics while navigating Al Quran',
                              value: enabled,
                              onChanged: _setShowLatinLetters,
                            );
                          },
                        ),
                        const Divider(height: 1, color: _line),
                        ValueListenableBuilder2<bool, String>(
                          first: showTranslationNotifier,
                          second: translationLanguageNotifier,
                          builder: (context, enabled, language, _) {
                            return _switchRow(
                              icon: Icons.translate_rounded,
                              title: 'Show Translation',
                              subtitle: language,
                              value: enabled,
                              onChanged: (value) async {
                                await _setShowTranslation(value);
                                if (!value) return;
                                final selected = await _pickOption(
                                  title: 'Translation Language',
                                  options: const ['English', 'Bangla'],
                                  current: language,
                                );
                                if (selected == null || selected == language) {
                                  return;
                                }
                                translationLanguageNotifier.value = selected;
                                await saveAppPreferences();
                              },
                            );
                          },
                        ),
                        const Divider(height: 1, color: _line),
                        ValueListenableBuilder<bool>(
                          valueListenable: showTajweedNotifier,
                          builder: (context, enabled, _) {
                            return _switchRow(
                              icon: Icons.menu_book_outlined,
                              title: 'Show Tajweed',
                              subtitle: 'Click to view the tajweed detail',
                              value: enabled,
                              onChanged: _setShowTajweed,
                            );
                          },
                        ),
                        const Divider(height: 1, color: _line),
                        ValueListenableBuilder<String>(
                          valueListenable: translatorNotifier,
                          builder: (context, translator, _) {
                            return _rowTile(
                              icon: Icons.person_outline,
                              title: 'Translator',
                              subtitle: translator,
                              onTap: () async {
                                final selected = await _pickOption(
                                  title: 'Translator',
                                  options: const [
                                    'Dr. Mustafa Khattab',
                                    'Muhiuddin Khan',
                                    'Tafsir Ibn Kathir (Brief)',
                                  ],
                                  current: translator,
                                );
                                if (selected == null || selected == translator) {
                                  return;
                                }
                                translatorNotifier.value = selected;
                                await saveAppPreferences();
                              },
                            );
                          },
                        ),
                        const Divider(height: 1, color: _line),
                        ValueListenableBuilder<String>(
                          valueListenable: reciterNotifier,
                          builder: (context, reciter, _) {
                            return _rowTile(
                              icon: Icons.mic_none_rounded,
                              title: 'Reciters',
                              subtitle: reciter,
                              onTap: () async {
                                final selected = await _pickOption(
                                  title: 'Reciter',
                                  options: const [
                                    'Mishary Rashid Alafasy',
                                    'Saad Al-Ghamdi',
                                    'Maher Al Muaiqly',
                                  ],
                                  current: reciter,
                                );
                                if (selected == null || selected == reciter) {
                                  return;
                                }
                                reciterNotifier.value = selected;
                                await saveAppPreferences();
                              },
                            );
                          },
                        ),
                        const Divider(height: 1, color: _line),
                        ValueListenableBuilder2<bool, String>(
                          first: prayerAlertsEnabledNotifier,
                          second: adzanVoiceNotifier,
                          builder: (context, enabled, voice, _) {
                            return _switchRow(
                              icon: Icons.notifications_active_outlined,
                              title: 'Adzan Notification',
                              subtitle: voice,
                              value: enabled,
                              onChanged: (value) async {
                                await _setAdzanNotification(value);
                                if (!value) return;
                                final selected = await _pickOption(
                                  title: 'Adzan Voice',
                                  options: const [
                                    'Hanan Attaki',
                                    'Mishary Alafasy',
                                    'Maher Al Muaiqly',
                                  ],
                                  current: voice,
                                );
                                if (selected == null || selected == voice) {
                                  return;
                                }
                                adzanVoiceNotifier.value = selected;
                                await saveAppPreferences();
                              },
                            );
                          },
                        ),
                        const Divider(height: 1, color: _line),
                        ValueListenableBuilder2<bool, String>(
                          first: sehriAlertEnabledNotifier,
                          second: imsakVoiceNotifier,
                          builder: (context, enabled, voice, _) {
                            return _switchRow(
                              icon: Icons.alarm_on_outlined,
                              title: 'Imsak Notification',
                              subtitle: voice,
                              value: enabled,
                              onChanged: (value) async {
                                await _setImsakNotification(value);
                                if (!value) return;
                                final selected = await _pickOption(
                                  title: 'Imsak Tone',
                                  options: const ['Default', 'Gentle', 'Beep'],
                                  current: voice,
                                );
                                if (selected == null || selected == voice) {
                                  return;
                                }
                                imsakVoiceNotifier.value = selected;
                                await saveAppPreferences();
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.center,
                    child: FilledButton.icon(
                      onPressed: _logout,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE64C5B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 9,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 14),
                      label: const Text(
                        'Log Out',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            bottomNav(context, 4),
          ],
        ),
      ),
    );
  }
}

class ValueListenableBuilder2<A, B> extends StatelessWidget {
  const ValueListenableBuilder2({
    super.key,
    required this.first,
    required this.second,
    required this.builder,
  });

  final ValueNotifier<A> first;
  final ValueNotifier<B> second;
  final Widget Function(BuildContext context, A a, B b, Widget? child) builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (context, a, child) {
        return ValueListenableBuilder<B>(
          valueListenable: second,
          builder: (context, b, child) => builder(context, a, b, child),
        );
      },
    );
  }
}
