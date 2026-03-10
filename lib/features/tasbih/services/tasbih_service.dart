import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'package:first_project/features/tasbih/models/tasbih_models.dart';

class TasbihService {
  TasbihService({BaseCacheManager? cacheManager})
    : _cacheManager = cacheManager ?? DefaultCacheManager();

  static const _stateCacheKey = 'tasbih_counter_state_v1';
  static const _historyCacheKey = 'tasbih_counter_history_v1';
  static const _maxHistory = 200;

  final BaseCacheManager _cacheManager;

  Future<TasbihCounterState> readState() async {
    final cached = await _cacheManager.getFileFromCache(_stateCacheKey);
    if (cached == null || !await cached.file.exists()) {
      return TasbihCounterState.initial();
    }

    try {
      final raw = await cached.file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return TasbihCounterState.initial();
      return TasbihCounterState.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return TasbihCounterState.initial();
    }
  }

  Future<void> saveState(TasbihCounterState state) async {
    final payload = jsonEncode(state.toJson());
    await _cacheManager.putFile(
      _stateCacheKey,
      Uint8List.fromList(utf8.encode(payload)),
      key: _stateCacheKey,
      fileExtension: 'json',
    );
  }

  Future<List<TasbihHistoryEntry>> readHistory() async {
    final cached = await _cacheManager.getFileFromCache(_historyCacheKey);
    if (cached == null || !await cached.file.exists()) return const [];

    try {
      final raw = await cached.file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      final output = <TasbihHistoryEntry>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final entry = TasbihHistoryEntry.fromJson(
          Map<String, dynamic>.from(item),
        );
        if (entry.finishedAtMillis <= 0 || entry.count <= 0) continue;
        output.add(entry);
      }
      output.sort((a, b) => b.finishedAtMillis.compareTo(a.finishedAtMillis));
      return output;
    } catch (_) {
      return const [];
    }
  }

  Future<void> appendHistory(TasbihHistoryEntry entry) async {
    final all = await readHistory();
    final updated = <TasbihHistoryEntry>[entry, ...all];
    if (updated.length > _maxHistory) {
      updated.removeRange(_maxHistory, updated.length);
    }
    await _saveHistory(updated);
  }

  Future<void> clearHistory() async {
    await _saveHistory(const []);
  }

  Future<void> _saveHistory(List<TasbihHistoryEntry> history) async {
    final payload = jsonEncode(history.map((item) => item.toJson()).toList());
    await _cacheManager.putFile(
      _historyCacheKey,
      Uint8List.fromList(utf8.encode(payload)),
      key: _historyCacheKey,
      fileExtension: 'json',
    );
  }
}
