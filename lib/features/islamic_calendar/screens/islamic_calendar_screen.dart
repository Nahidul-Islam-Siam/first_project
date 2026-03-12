import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:ponjika/ponjika.dart';

import 'package:first_project/core/constants/route_names.dart';
import 'package:first_project/features/islamic_calendar/services/google_calendar_events_service.dart';
import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/shared/widgets/bottom_nav.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class IslamicCalendarScreen extends StatefulWidget {
  const IslamicCalendarScreen({super.key});

  @override
  State<IslamicCalendarScreen> createState() => _IslamicCalendarScreenState();
}

class _IslamicCalendarScreenState extends State<IslamicCalendarScreen> {
  static const _dhakaLat = 23.8103;
  static const _dhakaLng = 90.4125;

  static const _monthsEn = <String>[
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

  static const _monthsBn = <String>[
    'জানুয়ারি',
    'ফেব্রুয়ারি',
    'মার্চ',
    'এপ্রিল',
    'মে',
    'জুন',
    'জুলাই',
    'আগস্ট',
    'সেপ্টেম্বর',
    'অক্টোবর',
    'নভেম্বর',
    'ডিসেম্বর',
  ];

  static const _weekdaysEn = <String>[
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];
  static const _weekdaysBn = <String>[
    'শনি',
    'রবি',
    'সোম',
    'মঙ্গল',
    'বুধ',
    'বৃহঃ',
    'শুক্র',
  ];

  DateTime _selectedDate = DateTime.now();
  DateTime _displayedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  final Dio _calendarApi = Dio(
    BaseOptions(
      baseUrl: 'https://api.aladhan.com/v1',
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      sendTimeout: const Duration(seconds: 12),
      responseType: ResponseType.json,
    ),
  );

  final GoogleCalendarEventsService _googleCalendarEventsService =
      GoogleCalendarEventsService();

  Map<int, List<String>> _apiEventsByDay = const {};
  Map<int, List<String>> _googleEventsByDay = const {};
  bool _eventsLoading = false;
  final ScrollController _importantEventsController = ScrollController();
  Timer? _importantEventsAutoScrollTimer;
  int _importantEventsScrollDirection = 1;

  bool get _isBangla => appLanguageNotifier.value == AppLanguage.bangla;

  String _text(String en, String bn) => _isBangla ? bn : en;

  @override
  void initState() {
    super.initState();
    appLanguageNotifier.addListener(_onLanguageChanged);
    _restartImportantEventsAutoScroll();
    unawaited(_loadMonthEvents());
  }

  @override
  void dispose() {
    appLanguageNotifier.removeListener(_onLanguageChanged);
    _importantEventsAutoScrollTimer?.cancel();
    _importantEventsController.dispose();
    super.dispose();
  }

  void _onLanguageChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _changeMonth(int delta) {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + delta,
        1,
      );
      if (_selectedDate.year != _displayedMonth.year ||
          _selectedDate.month != _displayedMonth.month) {
        _selectedDate = DateTime(
          _displayedMonth.year,
          _displayedMonth.month,
          1,
        );
      }
    });
    _resetImportantEventsScroll();
    unawaited(_loadMonthEvents());
  }

  void _onSelectDate(DateTime date) {
    setState(() => _selectedDate = date);
    _resetImportantEventsScroll();
    _restartImportantEventsAutoScroll();
  }

  void _resetImportantEventsScroll() {
    if (_importantEventsController.hasClients) {
      _importantEventsController.jumpTo(0);
    }
    _importantEventsScrollDirection = 1;
  }

  void _restartImportantEventsAutoScroll() {
    _importantEventsAutoScrollTimer?.cancel();
    _importantEventsAutoScrollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _autoScrollImportantEvents(),
    );
  }

  void _autoScrollImportantEvents() {
    if (!mounted || !_importantEventsController.hasClients) return;
    final position = _importantEventsController.position;
    if (position.maxScrollExtent <= 0) return;

    const step = 54.0;
    var target = position.pixels + (step * _importantEventsScrollDirection);
    if (target >= position.maxScrollExtent) {
      target = position.maxScrollExtent;
      _importantEventsScrollDirection = -1;
    } else if (target <= 0) {
      target = 0;
      _importantEventsScrollDirection = 1;
    }

    _importantEventsController.animateTo(
      target,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOut,
    );
  }

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isInDisplayedMonth(DateTime date) =>
      date.year == _displayedMonth.year && date.month == _displayedMonth.month;

  String _toBanglaDigits(String input) {
    const latin = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bangla = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    var output = input;
    for (var i = 0; i < latin.length; i++) {
      output = output.replaceAll(latin[i], bangla[i]);
    }
    return output;
  }

  String _digits(String input) => _isBangla ? _toBanglaDigits(input) : input;

  String _gregorianMonth(int month) =>
      _isBangla ? _monthsBn[month - 1] : _monthsEn[month - 1];

  String _weekday(int index) =>
      _isBangla ? _weekdaysBn[index] : _weekdaysEn[index];

  String _hijriMonth(String english) {
    if (!_isBangla) return english;
    const map = <String, String>{
      'Muharram': 'মুহাররম',
      'Safar': 'সফর',
      "Rabi' al-awwal": 'রবিউল আউয়াল',
      "Rabi' al-thani": 'রবিউস সানি',
      'Jumada al-awwal': 'জুমাদিউল আউয়াল',
      'Jumada al-thani': 'জুমাদিউস সানি',
      'Rajab': 'রজব',
      "Sha'ban": 'শাবান',
      'Ramadan': 'রমজান',
      'Shawwal': 'শাওয়াল',
      "Dhu al-Qi'dah": 'জিলকদ',
      'Dhu al-Hijjah': 'জিলহজ',
    };
    return map[english] ?? english;
  }

  String _formatGregorian(DateTime date) {
    final raw = '${date.day} ${_gregorianMonth(date.month)} ${date.year}';
    return _digits(raw);
  }

  String _formatBanglaDate(DateTime date) {
    final raw = Ponjika.format(date: date, format: 'DD MM YY');
    return _digits(raw);
  }

  String _formatHijri(DateTime date) {
    final h = HijriCalendar.fromDate(date);
    final raw = '${h.hDay} ${_hijriMonth(h.longMonthName)} ${h.hYear}';
    return _isBangla ? '${_digits(raw)} হিজরি' : '${_digits(raw)} AH';
  }

  List<DateTime> _visibleDays() {
    final first = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final total = DateUtils.getDaysInMonth(
      _displayedMonth.year,
      _displayedMonth.month,
    );
    final leading = first.weekday % 7;
    final start = first.subtract(Duration(days: leading));
    final trailing = (leading + total) % 7;
    final trailingCount = trailing == 0 ? 0 : (7 - trailing);
    final length = leading + total + trailingCount;
    return List<DateTime>.generate(
      length,
      (index) => start.add(Duration(days: index)),
    );
  }

  List<String> _fallbackMappedIslamicEvents(DateTime date) {
    final h = HijriCalendar.fromDate(date);
    final key = '${h.hMonth}-${h.hDay}';
    final map = <String, List<String>>{
      '1-1': [_text('Islamic New Year', 'ইসলামিক নববর্ষ')],
      '1-10': [_text('Ashura', 'আশুরা')],
      '7-27': [_text('Isra and Miraj', 'শবে মেরাজ')],
      '8-15': [_text('Mid-Shaban', 'শবে বরাত')],
      '9-1': [_text('Start of Ramadan', 'রমজান শুরু')],
      '9-27': [_text('Laylat al-Qadr', 'শবে কদর')],
      '10-1': [_text('Eid al-Fitr', 'ঈদুল ফিতর')],
      '12-9': [_text('Day of Arafah', 'আরাফার দিন')],
      '12-10': [_text('Eid al-Adha', 'ঈদুল আযহা')],
    };
    return map[key] ?? const <String>[];
  }

  List<String> _eventsForDate(DateTime date) {
    if (_isInDisplayedMonth(date)) {
      final google = _googleEventsByDay[date.day] ?? const <String>[];
      final api = _apiEventsByDay[date.day] ?? const <String>[];
      if (google.isNotEmpty || api.isNotEmpty) {
        return <String>{...google, ...api}.toList(growable: false);
      }
    }
    return _fallbackMappedIslamicEvents(date);
  }

  Future<void> _loadMonthEvents() async {
    if (!mounted) return;
    setState(() => _eventsLoading = true);

    var apiMap = <int, List<String>>{};
    var googleMap = <int, List<String>>{};

    try {
      final response = await _calendarApi.get(
        '/calendar/${_displayedMonth.year}/${_displayedMonth.month}',
        queryParameters: {
          'latitude': _dhakaLat,
          'longitude': _dhakaLng,
          'method': 1,
        },
      );
      final root = response.data;
      if (root is! Map) throw const FormatException('Invalid root');
      final data = root['data'];
      if (data is! List) throw const FormatException('Invalid data');

      final map = <int, List<String>>{};
      for (final item in data) {
        if (item is! Map) continue;
        final dateObj = item['date'];
        if (dateObj is! Map) continue;
        final gregorianObj = dateObj['gregorian'];
        final hijriObj = dateObj['hijri'];
        if (gregorianObj is! Map || hijriObj is! Map) continue;

        final day = int.tryParse((gregorianObj['day'] ?? '').toString());
        if (day == null) continue;

        final holidaysRaw = hijriObj['holidays'];
        if (holidaysRaw is! List) continue;

        final cleaned = <String>{
          for (final e in holidaysRaw)
            if (e != null && e.toString().trim().isNotEmpty)
              e.toString().trim(),
        }.toList(growable: false);
        if (cleaned.isNotEmpty) {
          map[day] = cleaned;
        }
      }
      apiMap = map;
    } catch (_) {
      apiMap = const <int, List<String>>{};
    }

    try {
      googleMap = await _googleCalendarEventsService.fetchMonthEvents(
        year: _displayedMonth.year,
        month: _displayedMonth.month,
      );
    } catch (_) {
      googleMap = const <int, List<String>>{};
    }

    if (!mounted) return;
    setState(() {
      _apiEventsByDay = apiMap;
      _googleEventsByDay = googleMap;
      _eventsLoading = false;
    });
    _resetImportantEventsScroll();
    _restartImportantEventsAutoScroll();
  }

  String _eventSourceLabel() {
    if (_eventsLoading) {
      return _text('Syncing events...', 'ইভেন্ট সিঙ্ক হচ্ছে...');
    }
    final hasGoogle = _googleEventsByDay.isNotEmpty;
    final hasApi = _apiEventsByDay.isNotEmpty;
    if (hasGoogle && hasApi) {
      return _text(
        'Events from Google Calendar + API',
        'Google Calendar + API ইভেন্ট',
      );
    }
    if (hasGoogle) {
      return _text(
        'Events from Google Calendar',
        'Google Calendar থেকে ইভেন্ট',
      );
    }
    if (hasApi) {
      return _text('Events from API', 'API থেকে ইভেন্ট');
    }
    return _text('Using offline mapped events', 'অফলাইন ম্যাপ করা ইভেন্ট');
  }

  String _timelineDateLabel(DateTime date) {
    final month = _gregorianMonth(date.month);
    final day = _digits(date.day.toString());
    return '$day $month';
  }

  List<_ImportantEventTimelineItem> _buildNearbyImportantTimeline({
    int dayRadius = 20,
  }) {
    final items = <_ImportantEventTimelineItem>[];
    final start = _selectedDate.subtract(Duration(days: dayRadius));
    final end = _selectedDate.add(Duration(days: dayRadius));

    for (
      var cursor = start;
      !cursor.isAfter(end);
      cursor = cursor.add(const Duration(days: 1))
    ) {
      final events = _eventsForDate(cursor);
      for (final event in events) {
        items.add(
          _ImportantEventTimelineItem(
            date: cursor,
            event: event,
            isSelectedDate: _isSameDate(cursor, _selectedDate),
          ),
        );
      }
    }

    return items;
  }

  PrayerTimes _prayerTimesForDate(DateTime date) {
    final params = CalculationMethodParameters.karachi();
    params.madhab = Madhab.hanafi;
    return PrayerTimes(
      date: DateTime(date.year, date.month, date.day),
      coordinates: Coordinates(_dhakaLat, _dhakaLng),
      calculationParameters: params,
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour12 = (dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12)
        .toString();
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${_digits('$hour12:$minute')} $suffix';
  }

  double _moonProgress() {
    final day = HijriCalendar.fromDate(_selectedDate).hDay;
    return (day / 30).clamp(0.05, 1.0);
  }

  String _moonPhaseLabel() {
    final day = HijriCalendar.fromDate(_selectedDate).hDay;
    if (day <= 2) {
      return _text('New moon', 'নতুন চাঁদ');
    }
    if (day <= 7) {
      return _text('Waxing crescent', 'বাড়ন্ত চাঁদ');
    }
    if (day <= 14) {
      return _text('First half', 'অর্ধেক চাঁদ');
    }
    if (day == 15) {
      return _text('Full moon', 'পূর্ণিমা');
    }
    if (day <= 22) {
      return _text('Waning moon', 'ক্ষয়িষ্ণু চাঁদ');
    }
    return _text('Last crescent', 'শেষ ক্রিসেন্ট');
  }

  String _monthHeaderTitle() {
    final h = HijriCalendar.fromDate(_displayedMonth);
    final raw = '${_hijriMonth(h.longMonthName)} ${h.hYear}';
    return _isBangla ? '${_digits(raw)} হিজরি' : '${_digits(raw)} AH';
  }

  String _monthHeaderSubtitle() =>
      '${_gregorianMonth(_displayedMonth.month)} ${_digits(_displayedMonth.year.toString())}';

  List<BoxShadow> _softShadow(NoorifyGlassTheme glass) {
    return [
      BoxShadow(
        color: glass.isDark ? const Color(0x1F000000) : const Color(0x120E3853),
        blurRadius: 11,
        offset: const Offset(0, 4),
      ),
    ];
  }

  Widget _buildHeader(NoorifyGlassTheme glass) {
    return NoorifyGlassCard(
      radius: BorderRadius.circular(24),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      boxShadow: _softShadow(glass),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushReplacementNamed(RouteNames.discover);
              }
            },
            style: IconButton.styleFrom(
              backgroundColor: glass.isDark
                  ? const Color(0x2B1EA8B8)
                  : const Color(0x1A1EA8B8),
              foregroundColor: glass.accent,
            ),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _text('Hijri Calendar', 'হিজরি ক্যালেন্ডার'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: glass.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            onPressed: () =>
                Navigator.of(context).pushNamed(RouteNames.preferences),
            style: IconButton.styleFrom(
              backgroundColor: glass.isDark
                  ? const Color(0x2B1EA8B8)
                  : const Color(0x1A1EA8B8),
              foregroundColor: glass.accent,
            ),
            icon: const Icon(Icons.settings_rounded),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _text(
                    'Notifications screen coming soon',
                    'নোটিফিকেশন স্ক্রিন শিগগিরই আসছে',
                  ),
                ),
              ),
            ),
            style: IconButton.styleFrom(
              backgroundColor: glass.isDark
                  ? const Color(0x2B1EA8B8)
                  : const Color(0x1A1EA8B8),
              foregroundColor: glass.accent,
            ),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildMoonCard(NoorifyGlassTheme glass) {
    final hijri = HijriCalendar.fromDate(_selectedDate);
    final dayLabel = _isBangla
        ? 'আজ ${_digits(hijri.hDay.toString())}তম দিন'
        : 'Day ${_digits(hijri.hDay.toString())}';

    return NoorifyGlassCard(
      radius: BorderRadius.circular(22),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      boxShadow: _softShadow(glass),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _hijriMonth(hijri.longMonthName),
                  style: TextStyle(
                    color: glass.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dayLabel,
                  style: TextStyle(
                    color: glass.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _moonPhaseLabel(),
                  style: TextStyle(
                    color: glass.accentSoft,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 122,
            height: 122,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 118,
                  height: 118,
                  child: CircularProgressIndicator(
                    value: _moonProgress(),
                    strokeWidth: 8,
                    backgroundColor: glass.isDark
                        ? const Color(0x2A9EE7F4)
                        : const Color(0x2A1EA8B8),
                    valueColor: AlwaysStoppedAnimation<Color>(glass.accent),
                  ),
                ),
                Container(
                  width: 92,
                  height: 92,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: glass.isDark
                          ? const [Color(0xFF435D70), Color(0xFF1A2837)]
                          : const [Color(0xFFF4F9FC), Color(0xFFBED4E0)],
                    ),
                    border: Border.all(
                      color: glass.isDark
                          ? const Color(0x44D4ECF8)
                          : const Color(0x66FFFFFF),
                    ),
                  ),
                  child: Text(
                    _digits(hijri.hDay.toString()),
                    style: TextStyle(
                      color: glass.textPrimary,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard(
    NoorifyGlassTheme glass,
    DateTime today,
    List<DateTime> visibleDays,
  ) {
    return NoorifyGlassCard(
      radius: BorderRadius.circular(22),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      boxShadow: _softShadow(glass),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => _changeMonth(-1),
                icon: Icon(
                  Icons.chevron_left_rounded,
                  color: glass.textPrimary,
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _monthHeaderTitle(),
                      style: TextStyle(
                        color: glass.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      _monthHeaderSubtitle(),
                      style: TextStyle(
                        color: glass.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _changeMonth(1),
                icon: Icon(
                  Icons.chevron_right_rounded,
                  color: glass.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List<Widget>.generate(
              7,
              (i) => Expanded(
                child: Center(
                  child: Text(
                    _weekday(i),
                    style: TextStyle(
                      color: glass.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visibleDays.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1.02,
            ),
            itemBuilder: (context, index) {
              final date = visibleDays[index];
              final selected = _isSameDate(date, _selectedDate);
              final isToday = _isSameDate(date, today);
              final inMonth = _isInDisplayedMonth(date);
              final hasEvent = _eventsForDate(date).isNotEmpty;

              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _onSelectDate(date),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: selected
                        ? LinearGradient(
                            colors: glass.isDark
                                ? const [Color(0xFF2FD8C7), Color(0xFF1B9CAA)]
                                : const [Color(0xFF84EDE0), Color(0xFF45B9C4)],
                          )
                        : null,
                    color: selected
                        ? null
                        : (glass.isDark
                              ? const Color(0x241B3B4E)
                              : const Color(0x66FFFFFF)),
                    border: Border.all(
                      color: isToday
                          ? glass.accent.withValues(alpha: 0.95)
                          : glass.glassBorder.withValues(alpha: 0.7),
                      width: isToday ? 1.5 : 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          _digits(date.day.toString()),
                          style: TextStyle(
                            color: selected
                                ? (glass.isDark
                                      ? const Color(0xFF073036)
                                      : const Color(0xFF0B4A52))
                                : (inMonth
                                      ? glass.textPrimary
                                      : glass.textMuted.withValues(
                                          alpha: 0.58,
                                        )),
                            fontSize: 22,
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w700,
                          ),
                        ),
                      ),
                      if (hasEvent)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Icon(
                            Icons.circle,
                            size: 6,
                            color: selected
                                ? const Color(0xFF0B4A52)
                                : glass.accent,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEventChips(NoorifyGlassTheme glass, List<String> events) {
    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(
          _text(
            'No highlighted event on this date',
            'এই তারিখে উল্লেখযোগ্য ইভেন্ট নেই',
          ),
          style: TextStyle(
            color: glass.textSecondary,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: events
            .take(3)
            .map((event) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: glass.isDark
                      ? const Color(0xFF163244)
                      : const Color(0xFFDDF4FA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: glass.accent.withValues(alpha: 0.55),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.event_available_rounded,
                      size: 14,
                      color: glass.accent,
                    ),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: Text(
                        event,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: glass.textPrimary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }

  Widget _buildPrayerCard(NoorifyGlassTheme glass, PrayerTimes prayers) {
    final sehri = prayers.fajr.toLocal();
    final iftar = prayers.maghrib.toLocal();

    return NoorifyGlassCard(
      radius: BorderRadius.circular(18),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      boxShadow: _softShadow(glass),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _text('Prayer Window', 'নামাজ সময়'),
            style: TextStyle(
              color: glass.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_text('Sehri ends', 'সেহরি শেষ')}: ${_formatTime(sehri)}',
            style: TextStyle(
              color: glass.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_text('Iftar starts', 'ইফতার শুরু')}: ${_formatTime(iftar)}',
            style: TextStyle(
              color: glass.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportantEventsCard(
    NoorifyGlassTheme glass,
    List<String> events,
    List<_ImportantEventTimelineItem> timelineItems,
  ) {
    final timelineHeight = MediaQuery.of(context).size.width < 390
        ? 176.0
        : 148.0;
    return NoorifyGlassCard(
      radius: BorderRadius.circular(18),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      boxShadow: _softShadow(glass),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _text('Important Events', 'গুরুত্বপূর্ণ তারিখসমূহ'),
            style: TextStyle(
              color: glass.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              _eventSourceLabel(),
              style: TextStyle(
                color: glass.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (events.isEmpty)
            Text(
              _text('No major event today', 'আজ বড় কোনো ইভেন্ট নেই'),
              style: TextStyle(
                color: glass.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            ...events
                .take(4)
                .map(
                  (event) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 14,
                          color: glass.accent,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            event,
                            style: TextStyle(
                              color: glass.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          const SizedBox(height: 8),
          Text(
            _text('Nearby Events', 'আগে ও পরের ইভেন্ট'),
            style: TextStyle(
              color: glass.textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          if (timelineItems.isEmpty)
            Text(
              _text(
                'No nearby events in this range',
                'এই সময়ে কাছাকাছি ইভেন্ট নেই',
              ),
              style: TextStyle(
                color: glass.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            SizedBox(
              height: timelineHeight,
              child: ListView.builder(
                controller: _importantEventsController,
                padding: EdgeInsets.zero,
                itemCount: timelineItems.length,
                itemBuilder: (context, index) {
                  final item = timelineItems[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: item.isSelectedDate
                                ? glass.accent
                                : glass.textSecondary.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            '${_timelineDateLabel(item.date)} • ${item.event}',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: item.isSelectedDate
                                  ? glass.textPrimary
                                  : glass.textSecondary,
                              fontSize: 12.7,
                              height: 1.25,
                              fontWeight: item.isSelectedDate
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    final today = DateTime.now();
    final visibleDays = _visibleDays();
    final selectedEvents = _eventsForDate(_selectedDate);
    final timelineItems = _buildNearbyImportantTimeline();
    final prayerTimes = _prayerTimesForDate(_selectedDate);

    return Scaffold(
      backgroundColor: glass.bgBottom,
      body: NoorifyGlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                  children: [
                    _buildHeader(glass),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                      child: Text(
                        _text(
                          'Today: ${_formatGregorian(_selectedDate)} • ${_formatHijri(_selectedDate)}',
                          'আজ: ${_formatGregorian(_selectedDate)} • ${_formatHijri(_selectedDate)}',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: glass.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    _buildMoonCard(glass),
                    const SizedBox(height: 10),
                    _buildCalendarCard(glass, today, visibleDays),
                    _buildEventChips(glass, selectedEvents),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 390;
                        if (compact) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildPrayerCard(glass, prayerTimes),
                              const SizedBox(height: 10),
                              _buildImportantEventsCard(
                                glass,
                                selectedEvents,
                                timelineItems,
                              ),
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 9,
                              child: _buildPrayerCard(glass, prayerTimes),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 11,
                              child: _buildImportantEventsCard(
                                glass,
                                selectedEvents,
                                timelineItems,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    NoorifyGlassCard(
                      radius: BorderRadius.circular(16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      boxShadow: _softShadow(glass),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DateInfoRow(
                            label: _text('Gregorian', 'ইংরেজি'),
                            value: _formatGregorian(_selectedDate),
                          ),
                          const SizedBox(height: 6),
                          _DateInfoRow(
                            label: _text('Hijri', 'হিজরি'),
                            value: _formatHijri(_selectedDate),
                          ),
                          const SizedBox(height: 6),
                          _DateInfoRow(
                            label: _text('Bangla', 'বাংলা'),
                            value: _formatBanglaDate(_selectedDate),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              bottomNav(context, 1),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateInfoRow extends StatelessWidget {
  const _DateInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    return Row(
      children: [
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: TextStyle(
              color: glass.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: glass.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ImportantEventTimelineItem {
  const _ImportantEventTimelineItem({
    required this.date,
    required this.event,
    required this.isSelectedDate,
  });

  final DateTime date;
  final String event;
  final bool isSelectedDate;
}
