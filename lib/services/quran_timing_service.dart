import 'package:dio/dio.dart';

class QuranTimingSegment {
  const QuranTimingSegment({
    required this.verseKey,
    required this.ayahIndex,
    required this.fromMs,
    required this.toMs,
    required this.wordSegments,
  });

  final String verseKey;
  final int ayahIndex;
  final int fromMs;
  final int toMs;
  final List<QuranWordTimingSegment> wordSegments;
}

class QuranWordTimingSegment {
  const QuranWordTimingSegment({
    required this.wordIndex,
    required this.fromMs,
    required this.toMs,
  });

  final int wordIndex;
  final int fromMs;
  final int toMs;
}

class QuranChapterTiming {
  const QuranChapterTiming({
    required this.recitationId,
    required this.audioUrl,
    required this.segments,
  });

  final int recitationId;
  final String audioUrl;
  final List<QuranTimingSegment> segments;
}

class QuranTimingService {
  QuranTimingService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://api.quran.com/api/v4',
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 20),
              sendTimeout: const Duration(seconds: 15),
              responseType: ResponseType.json,
            ),
          );

  final Dio _dio;

  int? recitationIdForReciterName(String reciterName) {
    final n = reciterName.toLowerCase().trim();

    if (n.contains('mishary') || n.contains('afasy')) return 7;
    if (n.contains('abu bakr') || n.contains('shatri')) return 4;
    if (n.contains('hani') && n.contains('rifai')) return 5;

    return null;
  }

  Future<QuranChapterTiming> fetchChapterTiming({
    required int surahNo,
    required int recitationId,
  }) async {
    final response = await _dio.get(
      '/chapter_recitations/$recitationId/$surahNo',
      queryParameters: {'segments': true},
    );
    final data = response.data;
    if (data is! Map) {
      throw const FormatException('Invalid timing response format.');
    }

    final audioFile = data['audio_file'];
    if (audioFile is! Map) {
      throw const FormatException('Missing audio_file in timing response.');
    }

    final audioUrl = (audioFile['audio_url'] ?? '').toString();
    final timestampsRaw = audioFile['timestamps'];
    if (audioUrl.isEmpty || timestampsRaw is! List) {
      throw const FormatException('Timing payload is incomplete.');
    }

    final segments = <QuranTimingSegment>[];
    for (final entry in timestampsRaw) {
      if (entry is! Map) continue;
      final verseKey = (entry['verse_key'] ?? '').toString();
      final fromMs = (entry['timestamp_from'] as num?)?.toInt();
      final toMs = (entry['timestamp_to'] as num?)?.toInt();
      if (verseKey.isEmpty || fromMs == null || toMs == null) continue;

      final wordSegments = <QuranWordTimingSegment>[];
      final rawWordSegments = entry['segments'];
      if (rawWordSegments is List) {
        for (final seg in rawWordSegments) {
          if (seg is! List || seg.length < 3) continue;
          final rawWordNo = seg[0];
          final rawFrom = seg[1];
          final rawTo = seg[2];
          if (rawWordNo is! num || rawFrom is! num || rawTo is! num) continue;
          final wordNo = rawWordNo.toInt();
          final wordFrom = rawFrom.toInt();
          final wordTo = rawTo.toInt();
          if (wordNo <= 0 || wordTo <= wordFrom) continue;
          wordSegments.add(
            QuranWordTimingSegment(
              wordIndex: wordNo - 1,
              fromMs: wordFrom,
              toMs: wordTo,
            ),
          );
        }
      }
      wordSegments.sort((a, b) => a.fromMs.compareTo(b.fromMs));

      final ayahPart = verseKey.split(':');
      if (ayahPart.length != 2) continue;
      final ayahNo = int.tryParse(ayahPart[1]);
      if (ayahNo == null || ayahNo <= 0) continue;

      segments.add(
        QuranTimingSegment(
          verseKey: verseKey,
          ayahIndex: ayahNo - 1,
          fromMs: fromMs,
          toMs: toMs,
          wordSegments: wordSegments,
        ),
      );
    }

    if (segments.isEmpty) {
      throw const FormatException('No timing segments found.');
    }

    return QuranChapterTiming(
      recitationId: recitationId,
      audioUrl: audioUrl,
      segments: segments,
    );
  }
}
