class QuranChapter {
  const QuranChapter({
    required this.surahNo,
    required this.surahName,
    required this.surahNameArabic,
    required this.surahNameArabicLong,
    required this.surahNameTranslation,
    required this.revelationPlace,
    required this.totalAyah,
  });

  final int surahNo;
  final String surahName;
  final String surahNameArabic;
  final String surahNameArabicLong;
  final String surahNameTranslation;
  final String revelationPlace;
  final int totalAyah;

  bool get isMeccan => revelationPlace.toLowerCase().contains('mecca');
  bool get isMedinan => revelationPlace.toLowerCase().contains('medina');

  factory QuranChapter.fromJson(
    Map<String, dynamic> json, {
    required int index,
  }) {
    return QuranChapter(
      surahNo: (json['surahNo'] as num?)?.toInt() ?? index,
      surahName: (json['surahName'] ?? '').toString(),
      surahNameArabic: (json['surahNameArabic'] ?? '').toString(),
      surahNameArabicLong: (json['surahNameArabicLong'] ?? '').toString(),
      surahNameTranslation: (json['surahNameTranslation'] ?? '').toString(),
      revelationPlace: (json['revelationPlace'] ?? '').toString(),
      totalAyah: (json['totalAyah'] as num?)?.toInt() ?? 0,
    );
  }
}

class QuranReciterAudio {
  const QuranReciterAudio({
    required this.id,
    required this.reciter,
    required this.url,
    required this.originalUrl,
  });

  final int id;
  final String reciter;
  final String url;
  final String originalUrl;

  factory QuranReciterAudio.fromJson(int id, Map<String, dynamic> json) {
    return QuranReciterAudio(
      id: id,
      reciter: (json['reciter'] ?? '').toString(),
      url: (json['url'] ?? '').toString(),
      originalUrl: (json['originalUrl'] ?? '').toString(),
    );
  }
}

class QuranSurahDetail extends QuranChapter {
  const QuranSurahDetail({
    required super.surahNo,
    required super.surahName,
    required super.surahNameArabic,
    required super.surahNameArabicLong,
    required super.surahNameTranslation,
    required super.revelationPlace,
    required super.totalAyah,
    required this.arabicAyahs,
    required this.bengaliAyahs,
    required this.englishAyahs,
    required this.audioByReciter,
  });

  final List<String> arabicAyahs;
  final List<String> bengaliAyahs;
  final List<String> englishAyahs;
  final List<QuranReciterAudio> audioByReciter;

  factory QuranSurahDetail.fromJson(Map<String, dynamic> json) {
    final dynamic arabicRaw = json['arabic1'] ?? json['arabic2'];
    final arabicAyahs = arabicRaw is List
        ? arabicRaw.map((e) => e.toString()).toList()
        : <String>[];

    final dynamic bengaliRaw = json['bengali'];
    final bengaliAyahs = bengaliRaw is List
        ? bengaliRaw.map((e) => e.toString()).toList()
        : <String>[];

    final dynamic englishRaw = json['english'];
    final englishAyahs = englishRaw is List
        ? englishRaw.map((e) => e.toString()).toList()
        : <String>[];

    final dynamic audioRaw = json['audio'];
    final audioByReciter = <QuranReciterAudio>[];
    if (audioRaw is Map<String, dynamic>) {
      for (final entry in audioRaw.entries) {
        final id = int.tryParse(entry.key);
        final value = entry.value;
        if (id == null || value is! Map<String, dynamic>) continue;
        audioByReciter.add(QuranReciterAudio.fromJson(id, value));
      }
      audioByReciter.sort((a, b) => a.id.compareTo(b.id));
    }

    return QuranSurahDetail(
      surahNo: (json['surahNo'] as num?)?.toInt() ?? 0,
      surahName: (json['surahName'] ?? '').toString(),
      surahNameArabic: (json['surahNameArabic'] ?? '').toString(),
      surahNameArabicLong: (json['surahNameArabicLong'] ?? '').toString(),
      surahNameTranslation: (json['surahNameTranslation'] ?? '').toString(),
      revelationPlace: (json['revelationPlace'] ?? '').toString(),
      totalAyah: (json['totalAyah'] as num?)?.toInt() ?? bengaliAyahs.length,
      arabicAyahs: arabicAyahs,
      bengaliAyahs: bengaliAyahs,
      englishAyahs: englishAyahs,
      audioByReciter: audioByReciter,
    );
  }
}
