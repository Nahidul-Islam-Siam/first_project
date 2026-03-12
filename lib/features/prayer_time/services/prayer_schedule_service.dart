import 'package:adhan_dart/adhan_dart.dart';
import 'package:dio/dio.dart';

class DailyPrayerSchedule {
  const DailyPrayerSchedule({
    required this.date,
    required this.fajr,
    required this.sunrise,
    required this.dzuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  final DateTime date;
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dzuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
}

class PrayerScheduleService {
  PrayerScheduleService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://api.aladhan.com',
              connectTimeout: const Duration(seconds: 12),
              receiveTimeout: const Duration(seconds: 12),
              sendTimeout: const Duration(seconds: 12),
              responseType: ResponseType.json,
            ),
          );

  final Dio _dio;

  static const int _apiMethod = 1; // University of Islamic Sciences, Karachi
  static const int _apiSchool = 1; // Hanafi

  Future<DailyPrayerSchedule> fetchFromApi({
    required DateTime date,
    required double latitude,
    required double longitude,
  }) async {
    final response = await _dio.get(
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
      fajr: _parseApiTime(date, valueFor('Fajr')),
      sunrise: _parseApiTime(date, valueFor('Sunrise')),
      dzuhr: _parseApiTime(date, valueFor('Dhuhr')),
      asr: _parseApiTime(date, valueFor('Asr')),
      maghrib: _parseApiTime(date, valueFor('Maghrib')),
      isha: _parseApiTime(date, valueFor('Isha')),
    );
  }

  DailyPrayerSchedule calculateFallback({
    required DateTime date,
    required double latitude,
    required double longitude,
  }) {
    final params = CalculationMethodParameters.karachi();
    params.madhab = Madhab.hanafi;

    final prayers = PrayerTimes(
      date: date,
      coordinates: Coordinates(latitude, longitude),
      calculationParameters: params,
    );

    return DailyPrayerSchedule(
      date: DateTime(date.year, date.month, date.day),
      fajr: prayers.fajr.toLocal(),
      sunrise: prayers.sunrise.toLocal(),
      dzuhr: prayers.dhuhr.toLocal(),
      asr: prayers.asr.toLocal(),
      maghrib: prayers.maghrib.toLocal(),
      isha: prayers.isha.toLocal(),
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
}
