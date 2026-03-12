import 'dart:collection';

import 'package:dio/dio.dart';

/// Lightweight Google Calendar public ICS reader.
/// No API key and no extra package required.
class GoogleCalendarEventsService {
  GoogleCalendarEventsService();

  static const List<String> _encodedCalendarIds = <String>[
    // Bangladesh public holidays
    'en.bd%23holiday%40group.v.calendar.google.com',
    // Islamic public holidays
    'en.islamic%23holiday%40group.v.calendar.google.com',
  ];

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      sendTimeout: const Duration(seconds: 12),
      responseType: ResponseType.plain,
    ),
  );

  final Map<String, Map<int, List<String>>> _monthCache =
      <String, Map<int, List<String>>>{};

  Future<Map<int, List<String>>> fetchMonthEvents({
    required int year,
    required int month,
  }) async {
    final cacheKey =
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
    final cached = _monthCache[cacheKey];
    if (cached != null) return cached;

    final merged = <int, LinkedHashSet<String>>{};

    for (final id in _encodedCalendarIds) {
      try {
        final map = await _fetchCalendarMonth(
          encodedCalendarId: id,
          year: year,
          month: month,
        );
        for (final entry in map.entries) {
          final bucket = merged.putIfAbsent(entry.key, LinkedHashSet.new);
          bucket.addAll(entry.value);
        }
      } catch (_) {
        // Keep app resilient if one calendar feed is unavailable.
      }
    }

    final normalized = <int, List<String>>{
      for (final entry in merged.entries)
        entry.key: entry.value.toList(growable: false),
    };
    _monthCache[cacheKey] = normalized;
    return normalized;
  }

  Future<Map<int, List<String>>> _fetchCalendarMonth({
    required String encodedCalendarId,
    required int year,
    required int month,
  }) async {
    final url =
        'https://calendar.google.com/calendar/ical/$encodedCalendarId/public/basic.ics';
    final response = await _dio.get<String>(url);
    final raw = (response.data ?? '').trim();
    if (raw.isEmpty) return const <int, List<String>>{};
    return _parseIcsForMonth(raw: raw, year: year, month: month);
  }

  Map<int, List<String>> _parseIcsForMonth({
    required String raw,
    required int year,
    required int month,
  }) {
    final lines = _unfoldIcsLines(raw);
    final result = <int, LinkedHashSet<String>>{};

    var inEvent = false;
    var summary = '';
    DateTime? start;
    DateTime? endExclusive;
    bool startAllDay = false;

    void flushEvent() {
      if (summary.trim().isEmpty || start == null) {
        summary = '';
        start = null;
        endExclusive = null;
        startAllDay = false;
        return;
      }

      final localizedSummary = _decodeIcsText(summary.trim());
      if (localizedSummary.isEmpty) {
        summary = '';
        start = null;
        endExclusive = null;
        startAllDay = false;
        return;
      }

      final startLocal = _dateOnlyLocal(start!);
      final endBase = endExclusive == null
          ? startLocal
          : (startAllDay
                ? _dateOnlyLocal(
                    endExclusive!,
                  ).subtract(const Duration(days: 1))
                : _dateOnlyLocal(endExclusive!));
      final finalEnd = endBase.isBefore(startLocal) ? startLocal : endBase;

      var cursor = startLocal;
      while (!cursor.isAfter(finalEnd)) {
        if (cursor.year == year && cursor.month == month) {
          final bucket = result.putIfAbsent(cursor.day, LinkedHashSet.new);
          bucket.add(localizedSummary);
        }
        cursor = cursor.add(const Duration(days: 1));
      }

      summary = '';
      start = null;
      endExclusive = null;
      startAllDay = false;
    }

    for (final line in lines) {
      if (line == 'BEGIN:VEVENT') {
        inEvent = true;
        summary = '';
        start = null;
        endExclusive = null;
        startAllDay = false;
        continue;
      }
      if (line == 'END:VEVENT') {
        if (inEvent) flushEvent();
        inEvent = false;
        continue;
      }
      if (!inEvent) continue;

      if (line.startsWith('SUMMARY')) {
        final value = _valuePart(line);
        if (value != null) summary = value;
        continue;
      }
      if (line.startsWith('DTSTART')) {
        final value = _valuePart(line);
        if (value == null) continue;
        startAllDay = line.contains('VALUE=DATE');
        start = _parseIcsDate(value, allDay: startAllDay);
        continue;
      }
      if (line.startsWith('DTEND')) {
        final value = _valuePart(line);
        if (value == null) continue;
        final endAllDay = line.contains('VALUE=DATE');
        endExclusive = _parseIcsDate(value, allDay: endAllDay);
      }
    }

    return <int, List<String>>{
      for (final entry in result.entries)
        entry.key: entry.value.toList(growable: false),
    };
  }

  List<String> _unfoldIcsLines(String raw) {
    final source = raw
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n');
    final unfolded = <String>[];
    for (final line in source) {
      if (line.isEmpty) continue;
      if ((line.startsWith(' ') || line.startsWith('\t')) &&
          unfolded.isNotEmpty) {
        unfolded[unfolded.length - 1] += line.substring(1);
      } else {
        unfolded.add(line);
      }
    }
    return unfolded;
  }

  String? _valuePart(String line) {
    final idx = line.indexOf(':');
    if (idx == -1 || idx + 1 >= line.length) return null;
    return line.substring(idx + 1);
  }

  DateTime? _parseIcsDate(String value, {required bool allDay}) {
    final dateOnly = RegExp(r'^(\d{4})(\d{2})(\d{2})$').firstMatch(value);
    if (dateOnly != null) {
      final y = int.parse(dateOnly.group(1)!);
      final m = int.parse(dateOnly.group(2)!);
      final d = int.parse(dateOnly.group(3)!);
      return DateTime(y, m, d);
    }

    final dateTime = RegExp(
      r'^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})Z?$',
    ).firstMatch(value);
    if (dateTime != null) {
      final y = int.parse(dateTime.group(1)!);
      final m = int.parse(dateTime.group(2)!);
      final d = int.parse(dateTime.group(3)!);
      final hh = int.parse(dateTime.group(4)!);
      final mm = int.parse(dateTime.group(5)!);
      final ss = int.parse(dateTime.group(6)!);
      final isUtc = value.endsWith('Z');
      final dt = isUtc
          ? DateTime.utc(y, m, d, hh, mm, ss).toLocal()
          : DateTime(y, m, d, hh, mm, ss);
      if (allDay) return DateTime(dt.year, dt.month, dt.day);
      return dt;
    }

    return null;
  }

  DateTime _dateOnlyLocal(DateTime dateTime) {
    final local = dateTime.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  String _decodeIcsText(String value) {
    return value
        .replaceAll(r'\,', ',')
        .replaceAll(r'\;', ';')
        .replaceAll(r'\n', ' ')
        .replaceAll(r'\\', '\\')
        .trim();
  }
}
