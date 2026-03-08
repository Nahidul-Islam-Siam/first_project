import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class QuranLastReadEntry {
  const QuranLastReadEntry({required this.surahNo, required this.ayahNo});

  final int surahNo;
  final int ayahNo;
}

class QuranLastReadService {
  QuranLastReadService({BaseCacheManager? cacheManager})
    : _cacheManager = cacheManager ?? DefaultCacheManager();

  static const _cacheKey = 'quran_last_read_v1';
  final BaseCacheManager _cacheManager;

  Future<void> saveLastRead({required int surahNo, int ayahNo = 1}) async {
    final safeSurah = surahNo <= 0 ? 1 : surahNo;
    final safeAyah = ayahNo <= 0 ? 1 : ayahNo;
    final payload = jsonEncode({'surahNo': safeSurah, 'ayahNo': safeAyah});
    await _cacheManager.putFile(
      _cacheKey,
      Uint8List.fromList(utf8.encode(payload)),
      key: _cacheKey,
      fileExtension: 'json',
    );
  }

  Future<void> saveLastReadSurahNo(int surahNo) async {
    await saveLastRead(surahNo: surahNo, ayahNo: 1);
  }

  Future<QuranLastReadEntry?> readLastRead() async {
    final cached = await _cacheManager.getFileFromCache(_cacheKey);
    if (cached == null || !await cached.file.exists()) return null;

    try {
      final raw = await cached.file.readAsString();
      final json = jsonDecode(raw);
      if (json is! Map) return null;
      final surahRaw = json['surahNo'];
      final ayahRaw = json['ayahNo'];

      final surahNo = surahRaw is int
          ? surahRaw
          : (surahRaw is num
                ? surahRaw.toInt()
                : int.tryParse(surahRaw.toString()));
      if (surahNo == null || surahNo <= 0) return null;

      final ayahNo = ayahRaw is int
          ? ayahRaw
          : (ayahRaw is num ? ayahRaw.toInt() : int.tryParse('$ayahRaw'));

      return QuranLastReadEntry(
        surahNo: surahNo,
        ayahNo: (ayahNo == null || ayahNo <= 0) ? 1 : ayahNo,
      );
    } catch (_) {
      return null;
    }
  }

  Future<int?> readLastReadSurahNo() async {
    final entry = await readLastRead();
    return entry?.surahNo;
  }
}
