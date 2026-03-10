enum TasbihMode { regular, afterSalah }

const List<String> afterSalahPrayers = <String>[
  'Fajr',
  'Zuhr',
  'Asr',
  'Maghrib',
  'Isha',
];

class TasbihPreset {
  const TasbihPreset({
    required this.id,
    required this.label,
    required this.target,
  });

  final String id;
  final String label;
  final int target;
}

class TasbihCounterState {
  const TasbihCounterState({
    required this.mode,
    required this.regularPresetId,
    required this.regularTarget,
    required this.regularCount,
    required this.selectedPrayer,
    required this.prayerCounts,
    required this.dailyGoal,
    required this.reminderMinutes,
    required this.hapticEnabled,
  });

  static const int schemaVersion = 1;

  factory TasbihCounterState.initial() {
    return TasbihCounterState(
      mode: TasbihMode.regular,
      regularPresetId: 'subhanallah',
      regularTarget: 33,
      regularCount: 0,
      selectedPrayer: 'Fajr',
      prayerCounts: {for (final prayer in afterSalahPrayers) prayer: 0},
      dailyGoal: 100,
      reminderMinutes: 10,
      hapticEnabled: true,
    );
  }

  final TasbihMode mode;
  final String regularPresetId;
  final int regularTarget;
  final int regularCount;
  final String selectedPrayer;
  final Map<String, int> prayerCounts;
  final int dailyGoal;
  final int reminderMinutes;
  final bool hapticEnabled;

  int countForPrayer(String prayer) => prayerCounts[prayer] ?? 0;

  int get currentCount {
    if (mode == TasbihMode.regular) return regularCount;
    return countForPrayer(selectedPrayer);
  }

  int get currentTarget => mode == TasbihMode.regular ? regularTarget : 100;

  String get modeStorageValue =>
      mode == TasbihMode.regular ? 'regular' : 'after_salah';

  TasbihCounterState copyWith({
    TasbihMode? mode,
    String? regularPresetId,
    int? regularTarget,
    int? regularCount,
    String? selectedPrayer,
    Map<String, int>? prayerCounts,
    int? dailyGoal,
    int? reminderMinutes,
    bool? hapticEnabled,
  }) {
    return TasbihCounterState(
      mode: mode ?? this.mode,
      regularPresetId: regularPresetId ?? this.regularPresetId,
      regularTarget: regularTarget ?? this.regularTarget,
      regularCount: regularCount ?? this.regularCount,
      selectedPrayer: selectedPrayer ?? this.selectedPrayer,
      prayerCounts: prayerCounts ?? Map<String, int>.from(this.prayerCounts),
      dailyGoal: dailyGoal ?? this.dailyGoal,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schema_version': schemaVersion,
      'mode': modeStorageValue,
      'regularPresetId': regularPresetId,
      'regularTarget': regularTarget,
      'regularCount': regularCount,
      'selectedPrayer': selectedPrayer,
      'prayerCounts': prayerCounts,
      'dailyGoal': dailyGoal,
      'reminderMinutes': reminderMinutes,
      'hapticEnabled': hapticEnabled,
    };
  }

  factory TasbihCounterState.fromJson(Map<String, dynamic> json) {
    final modeRaw = (json['mode'] ?? '').toString().trim().toLowerCase();
    final mode = modeRaw == 'after_salah'
        ? TasbihMode.afterSalah
        : TasbihMode.regular;

    final rawPrayerCounts = json['prayerCounts'];
    final parsedPrayerCounts = <String, int>{
      for (final prayer in afterSalahPrayers) prayer: 0,
    };
    if (rawPrayerCounts is Map) {
      for (final prayer in afterSalahPrayers) {
        final value = rawPrayerCounts[prayer];
        parsedPrayerCounts[prayer] = (value as num?)?.toInt() ?? 0;
      }
    }

    final selectedPrayer = (json['selectedPrayer'] ?? 'Fajr').toString().trim();
    final safeSelectedPrayer = afterSalahPrayers.contains(selectedPrayer)
        ? selectedPrayer
        : 'Fajr';

    final dailyGoal = (json['dailyGoal'] as num?)?.toInt() ?? 100;
    final reminderMinutes = (json['reminderMinutes'] as num?)?.toInt() ?? 10;

    return TasbihCounterState(
      mode: mode,
      regularPresetId: (json['regularPresetId'] ?? 'subhanallah').toString(),
      regularTarget: (json['regularTarget'] as num?)?.toInt() ?? 33,
      regularCount: (json['regularCount'] as num?)?.toInt() ?? 0,
      selectedPrayer: safeSelectedPrayer,
      prayerCounts: parsedPrayerCounts,
      dailyGoal: dailyGoal <= 0 ? 100 : dailyGoal,
      reminderMinutes: reminderMinutes < 0 ? 0 : reminderMinutes,
      hapticEnabled: json['hapticEnabled'] is bool
          ? json['hapticEnabled'] as bool
          : true,
    );
  }
}

class TasbihHistoryEntry {
  const TasbihHistoryEntry({
    required this.finishedAtMillis,
    required this.mode,
    required this.label,
    required this.count,
    required this.target,
    required this.durationSeconds,
  });

  final int finishedAtMillis;
  final TasbihMode mode;
  final String label;
  final int count;
  final int target;
  final int durationSeconds;

  DateTime get finishedAt =>
      DateTime.fromMillisecondsSinceEpoch(finishedAtMillis, isUtc: false);
  bool get completed => target > 0 && count >= target;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'finishedAtMillis': finishedAtMillis,
      'mode': mode == TasbihMode.regular ? 'regular' : 'after_salah',
      'label': label,
      'count': count,
      'target': target,
      'durationSeconds': durationSeconds,
    };
  }

  factory TasbihHistoryEntry.fromJson(Map<String, dynamic> json) {
    final modeRaw = (json['mode'] ?? '').toString().trim().toLowerCase();
    final mode = modeRaw == 'after_salah'
        ? TasbihMode.afterSalah
        : TasbihMode.regular;
    return TasbihHistoryEntry(
      finishedAtMillis: (json['finishedAtMillis'] as num?)?.toInt() ?? 0,
      mode: mode,
      label: (json['label'] ?? '').toString(),
      count: (json['count'] as num?)?.toInt() ?? 0,
      target: (json['target'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
    );
  }
}
