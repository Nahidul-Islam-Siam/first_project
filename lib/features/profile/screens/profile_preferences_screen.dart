import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/core/constants/route_names.dart';
import 'package:first_project/shared/widgets/bottom_nav.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class ProfilePreferencesScreen extends StatefulWidget {
  const ProfilePreferencesScreen({super.key});

  @override
  State<ProfilePreferencesScreen> createState() =>
      _ProfilePreferencesScreenState();
}

class _ProfilePreferencesScreenState extends State<ProfilePreferencesScreen> {
  static const _teal = Color(0xFF14A3B8);

  bool get _isBangla => appLanguageNotifier.value == AppLanguage.bangla;

  String _text(String english, String bangla) => _isBangla ? bangla : english;

  @override
  void initState() {
    super.initState();
    appLanguageNotifier.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    appLanguageNotifier.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (!mounted) return;
    setState(() {});
  }

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
          title: Text(_text('Logout', 'লগআউট')),
          content: Text(
            _text(
              'Are you sure you want to logout now?',
              'আপনি কি এখন লগআউট করতে চান?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(_text('Cancel', 'বাতিল')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(_text('Logout', 'লগআউট')),
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

  String _fontSizeLabel(AppFontSize size) {
    if (!_isBangla) return appFontSizeLabel(size);
    switch (size) {
      case AppFontSize.small:
        return 'ছোট';
      case AppFontSize.medium:
        return 'মাঝারি';
      case AppFontSize.large:
        return 'বড়';
    }
  }

  String _translationLanguageLabel(String value) {
    if (!_isBangla) return value;
    if (value == 'Bangla') return 'বাংলা';
    if (value == 'English') return 'ইংরেজি';
    return value;
  }

  Future<void> _setDarkTheme(bool value) async {
    darkThemeEnabledNotifier.value = value;
    await saveAppPreferences();
  }

  Future<void> _setUseDeviceLocation(bool value) async {
    try {
      if (!value) {
        useDeviceLocationNotifier.value = false;
        await saveAppPreferences();
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        useDeviceLocationNotifier.value = false;
        await saveAppPreferences();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _text(
                'Please enable phone location service first',
                'প্রথমে ফোনের লোকেশন সার্ভিস চালু করুন',
              ),
            ),
          ),
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        useDeviceLocationNotifier.value = false;
        await saveAppPreferences();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _text(
                'Location permission is permanently denied. Enable it in app settings.',
                'লোকেশন পারমিশন স্থায়ীভাবে বন্ধ। অ্যাপ সেটিংস থেকে চালু করুন।',
              ),
            ),
          ),
        );
        return;
      }
      if (permission == LocationPermission.denied) {
        useDeviceLocationNotifier.value = false;
        await saveAppPreferences();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _text(
                'Location permission is needed for accurate timings',
                'সঠিক সময়ের জন্য লোকেশন পারমিশন প্রয়োজন',
              ),
            ),
          ),
        );
        return;
      }

      useDeviceLocationNotifier.value = value;
      await saveAppPreferences();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text('Device location enabled', 'ডিভাইস লোকেশন চালু হয়েছে'),
          ),
        ),
      );
    } catch (e) {
      useDeviceLocationNotifier.value = false;
      await saveAppPreferences();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'Unable to enable location on this device right now',
              'এই ডিভাইসে এখন লোকেশন চালু করা যাচ্ছে না',
            ),
          ),
        ),
      );
      debugPrint('Use device location toggle failed: $e');
    }
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

  Future<void> _setHifzMode(bool value) async {
    hifzModeEnabledNotifier.value = value;
    if (!value) {
      hifzHideBanglaMeaningNotifier.value = false;
    }
    await saveAppPreferences();
  }

  Future<void> _setHifzHideBanglaMeaning(bool value) async {
    hifzHideBanglaMeaningNotifier.value = value;
    await saveAppPreferences();
  }

  Future<void> _selectHifzRepeatCount() async {
    final current = '${hifzRepeatCountNotifier.value}x';
    final selected = await _pickOption(
      title: _text('Hifz Repeat Count', 'হিফজ রিপিট সংখ্যা'),
      options: const ['1x', '3x', '5x', '10x'],
      current: current,
    );
    if (selected == null) return;
    final parsed = int.tryParse(selected.replaceAll('x', ''));
    if (parsed == null || parsed == hifzRepeatCountNotifier.value) return;
    hifzRepeatCountNotifier.value = parsed;
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
                  trailing: selected
                      ? const Icon(Icons.check, color: _teal)
                      : null,
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
              ListTile(
                title: Text(
                  _text('Font Size', 'ফন্ট সাইজ'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const Divider(height: 1),
              ...AppFontSize.values.map((size) {
                final selected = size == current;
                return ListTile(
                  title: Text(_fontSizeLabel(size)),
                  trailing: selected
                      ? const Icon(Icons.check, color: _teal)
                      : null,
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
        final glass = NoorifyGlassTheme(context);
        final bytes = _decodeProfilePhoto(encoded);
        if (bytes != null) {
          return CircleAvatar(
            radius: 19,
            backgroundImage: MemoryImage(bytes),
            backgroundColor: Colors.white,
          );
        }
        return CircleAvatar(
          radius: 19,
          backgroundColor: glass.isDark
              ? const Color(0xFF2A3A4A)
              : const Color(0xFFCCD7E2),
          child: Icon(
            Icons.person,
            color: glass.isDark
                ? const Color(0xFFB6C9D8)
                : const Color(0xFF6B7A8A),
            size: 19,
          ),
        );
      },
    );
  }

  Widget _sectionCard({required Widget child}) {
    return NoorifyGlassCard(
      radius: BorderRadius.circular(14),
      padding: EdgeInsets.zero,
      child: child,
    );
  }

  Widget _sectionLabel(String text) {
    final glass = NoorifyGlassTheme(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 12, 6, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 10.5,
            color: glass.textMuted,
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
    final glass = NoorifyGlassTheme(context);
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -2),
      leading: Icon(icon, size: 16, color: glass.textSecondary),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: glass.textPrimary,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: glass.textMuted,
                height: 1.2,
              ),
            ),
      trailing:
          trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: glass.textMuted,
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
    final glass = NoorifyGlassTheme(context);
    return _rowTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: glass.accent,
        activeThumbColor: Colors.white,
        inactiveTrackColor: glass.isDark
            ? const Color(0x335F7E94)
            : const Color(0xFFD4DCE3),
        inactiveThumbColor: glass.isDark
            ? const Color(0xFF8AA8BC)
            : const Color(0xFF90A2AF),
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
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                    child: Text(
                      _text('Profile', 'প্রোফাইল'),
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
                  _sectionLabel(_text('General', 'সাধারণ')),
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
                              title: _text('Font Size', 'ফন্ট সাইজ'),
                              subtitle: _fontSizeLabel(size),
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
                              title: _text('Dark Theme', 'ডার্ক থিম'),
                              subtitle: _text(
                                'Switch to dark color scheme',
                                'ডার্ক কালার স্কিম চালু করুন',
                              ),
                              value: enabled,
                              onChanged: _setDarkTheme,
                            );
                          },
                        ),
                        const Divider(height: 1, color: _line),
                        ValueListenableBuilder<bool>(
                          valueListenable: useDeviceLocationNotifier,
                          builder: (context, enabled, _) {
                            return _switchRow(
                              icon: Icons.my_location_rounded,
                              title: _text(
                                'Use Device Location',
                                'ডিভাইস লোকেশন ব্যবহার',
                              ),
                              subtitle: _text(
                                'Accurate prayer/sehri/iftar by your area',
                                'আপনার এলাকার সঠিক সালাত/সেহরি/ইফতার সময়',
                              ),
                              value: enabled,
                              onChanged: _setUseDeviceLocation,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  _sectionLabel(_text('Prayer Setting', 'প্রার্থনা সেটিং')),
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
                              title: _text(
                                'Show Latin Letters',
                                'লাতিন লেখা দেখান',
                              ),
                              subtitle: _text(
                                'Latin lyrics while navigating Al Quran',
                                'কুরআন পড়ার সময় লাতিন উচ্চারণ দেখান',
                              ),
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
                              title: _text('Show Translation', 'অনুবাদ দেখান'),
                              subtitle: _translationLanguageLabel(language),
                              value: enabled,
                              onChanged: (value) async {
                                await _setShowTranslation(value);
                                if (!value) return;
                                final currentOption =
                                    _isBangla && language == 'Bangla'
                                    ? 'বাংলা'
                                    : language;
                                final selected = await _pickOption(
                                  title: _text(
                                    'Translation Language',
                                    'অনুবাদের ভাষা',
                                  ),
                                  options: _isBangla
                                      ? const ['বাংলা', 'English']
                                      : const ['English', 'Bangla'],
                                  current: currentOption,
                                );
                                if (selected == null) {
                                  return;
                                }
                                final normalizedSelected = selected == 'বাংলা'
                                    ? 'Bangla'
                                    : selected;
                                if (normalizedSelected == language) return;
                                translationLanguageNotifier.value =
                                    normalizedSelected;
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
                              title: _text('Show Tajweed', 'তাজবিদ দেখান'),
                              subtitle: _text(
                                'Click to view the tajweed detail',
                                'তাজবিদের বিস্তারিত দেখতে চালু করুন',
                              ),
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
                              title: _text('Translator', 'অনুবাদক'),
                              subtitle: translator,
                              onTap: () async {
                                final selected = await _pickOption(
                                  title: _text('Translator', 'অনুবাদক'),
                                  options: const [
                                    'Dr. Mustafa Khattab',
                                    'Muhiuddin Khan',
                                    'Tafsir Ibn Kathir (Brief)',
                                  ],
                                  current: translator,
                                );
                                if (selected == null ||
                                    selected == translator) {
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
                              title: _text('Reciters', 'কারী'),
                              subtitle: reciter,
                              onTap: () async {
                                final selected = await _pickOption(
                                  title: _text('Reciter', 'কারী'),
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
                              title: _text(
                                'Adzan Notification',
                                'আযান নোটিফিকেশন',
                              ),
                              subtitle: voice,
                              value: enabled,
                              onChanged: (value) async {
                                await _setAdzanNotification(value);
                                if (!value) return;
                                final selected = await _pickOption(
                                  title: _text('Adzan Voice', 'আযানের ভয়েস'),
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
                              title: _text(
                                'Imsak Notification',
                                'ইমসাক নোটিফিকেশন',
                              ),
                              subtitle: voice,
                              value: enabled,
                              onChanged: (value) async {
                                await _setImsakNotification(value);
                                if (!value) return;
                                final selected = await _pickOption(
                                  title: _text('Imsak Tone', 'ইমসাক টোন'),
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
                  _sectionLabel(_text('Quran Learning', 'কুরআন লার্নিং')),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ValueListenableBuilder<bool>(
                      valueListenable: hifzModeEnabledNotifier,
                      builder: (context, enabled, _) {
                        return Column(
                          children: [
                            _switchRow(
                              icon: Icons.self_improvement_outlined,
                              title: _text(
                                'Enable Hifz Mode',
                                'হিফজ মোড চালু করুন',
                              ),
                              subtitle: _text(
                                'Use repeat mode for ayah memorization',
                                'আয়াত মুখস্থের জন্য রিপিট মোড ব্যবহার করুন',
                              ),
                              value: enabled,
                              onChanged: _setHifzMode,
                            ),
                            if (enabled) ...[
                              const Divider(height: 1, color: _line),
                              ValueListenableBuilder<int>(
                                valueListenable: hifzRepeatCountNotifier,
                                builder: (context, repeatCount, _) {
                                  return _rowTile(
                                    icon: Icons.repeat_rounded,
                                    title: _text(
                                      'Hifz Repeat Count',
                                      'হিফজ রিপিট সংখ্যা',
                                    ),
                                    subtitle: _text(
                                      '${repeatCount}x per ayah',
                                      'প্রতি আয়াতে ${repeatCount}x',
                                    ),
                                    onTap: _selectHifzRepeatCount,
                                  );
                                },
                              ),
                              const Divider(height: 1, color: _line),
                              ValueListenableBuilder<bool>(
                                valueListenable: hifzHideBanglaMeaningNotifier,
                                builder: (context, hideBangla, _) {
                                  return _switchRow(
                                    icon: Icons.visibility_off_outlined,
                                    title: _text(
                                      'Hide Bangla in Hifz',
                                      'হিফজে বাংলা লুকান',
                                    ),
                                    subtitle: _text(
                                      'Show Arabic only while practicing',
                                      'প্র্যাকটিসে শুধু আরবি দেখান',
                                    ),
                                    value: hideBangla,
                                    onChanged: _setHifzHideBanglaMeaning,
                                  );
                                },
                              ),
                            ],
                          ],
                        );
                      },
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
                      label: Text(
                        _text('Log Out', 'লগ আউট'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
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
