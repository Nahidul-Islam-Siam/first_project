import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class QuranAyahBookmark {
  const QuranAyahBookmark({
    required this.surahNo,
    required this.surahName,
    required this.ayahNo,
    required this.note,
    required this.updatedAtMillis,
  });

  final int surahNo;
  final String surahName;
  final int ayahNo;
  final String note;
  final int updatedAtMillis;

  Map<String, dynamic> toJson() {
    return {
      'surahNo': surahNo,
      'surahName': surahName,
      'ayahNo': ayahNo,
      'note': note,
      'updatedAtMillis': updatedAtMillis,
    };
  }

  factory QuranAyahBookmark.fromJson(Map<String, dynamic> json) {
    final surahNo = (json['surahNo'] as num?)?.toInt() ?? 0;
    final ayahNo = (json['ayahNo'] as num?)?.toInt() ?? 0;
    final surahName = (json['surahName'] ?? '').toString();
    final note = (json['note'] ?? '').toString();
    final updatedAtMillis = (json['updatedAtMillis'] as num?)?.toInt() ?? 0;

    return QuranAyahBookmark(
      surahNo: surahNo,
      surahName: surahName,
      ayahNo: ayahNo,
      note: note,
      updatedAtMillis: updatedAtMillis,
    );
  }
}

class QuranBookmarksService {
  QuranBookmarksService({BaseCacheManager? cacheManager})
    : _cacheManager = cacheManager ?? DefaultCacheManager();

  static const _cacheKey = 'quran_ayah_bookmarks_v1';
  final BaseCacheManager _cacheManager;

  Future<List<QuranAyahBookmark>> readAll() async {
    final cached = await _cacheManager.getFileFromCache(_cacheKey);
    if (cached == null || !await cached.file.exists()) return const [];

    try {
      final raw = await cached.file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      final output = <QuranAyahBookmark>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final bookmark = QuranAyahBookmark.fromJson(map);
        if (bookmark.surahNo <= 0 || bookmark.ayahNo <= 0) continue;
        output.add(bookmark);
      }
      output.sort((a, b) => b.updatedAtMillis.compareTo(a.updatedAtMillis));
      return output;
    } catch (_) {
      return const [];
    }
  }

  Future<List<QuranAyahBookmark>> readBySurah(int surahNo) async {
    final all = await readAll();
    return all
        .where((item) => item.surahNo == surahNo)
        .toList(growable: false)
      ..sort((a, b) => a.ayahNo.compareTo(b.ayahNo));
  }

  Future<void> upsert(QuranAyahBookmark bookmark) async {
    final all = await readAll();
    final updated = List<QuranAyahBookmark>.from(all);
    final index = updated.indexWhere(
      (item) =>
          item.surahNo == bookmark.surahNo && item.ayahNo == bookmark.ayahNo,
    );
    if (index >= 0) {
      updated[index] = bookmark;
    } else {
      updated.add(bookmark);
    }
    await _saveAll(updated);
  }

  Future<void> remove({
    required int surahNo,
    required int ayahNo,
  }) async {
    final all = await readAll();
    final updated = all
        .where((item) => !(item.surahNo == surahNo && item.ayahNo == ayahNo))
        .toList(growable: false);
    await _saveAll(updated);
  }

  Future<void> _saveAll(List<QuranAyahBookmark> bookmarks) async {
    final payload = jsonEncode(bookmarks.map((item) => item.toJson()).toList());
    await _cacheManager.putFile(
      _cacheKey,
      Uint8List.fromList(utf8.encode(payload)),
      key: _cacheKey,
      fileExtension: 'json',
    );
  }
}
