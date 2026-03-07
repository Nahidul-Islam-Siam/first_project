import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class MosqueSavedLocation {
  const MosqueSavedLocation({
    required this.latitude,
    required this.longitude,
    required this.label,
  });

  final double latitude;
  final double longitude;
  final String label;
}

class MosqueLocationService {
  MosqueLocationService({BaseCacheManager? cache})
    : _cache = cache ?? DefaultCacheManager();

  static const _cacheKey = 'mosque_selected_location_v1';
  final BaseCacheManager _cache;

  Future<MosqueSavedLocation?> load() async {
    final file = await _cache.getFileFromCache(_cacheKey);
    if (file == null || !await file.file.exists()) return null;

    try {
      final decoded = jsonDecode(await file.file.readAsString());
      if (decoded is! Map) return null;
      final latitude = (decoded['latitude'] as num?)?.toDouble();
      final longitude = (decoded['longitude'] as num?)?.toDouble();
      if (latitude == null || longitude == null) return null;
      final label = (decoded['label'] ?? 'Selected location').toString().trim();
      return MosqueSavedLocation(
        latitude: latitude,
        longitude: longitude,
        label: label.isEmpty ? 'Selected location' : label,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save({
    required double latitude,
    required double longitude,
    required String label,
  }) async {
    final payload = jsonEncode({
      'latitude': latitude,
      'longitude': longitude,
      'label': label,
      'updated_at': DateTime.now().toIso8601String(),
    });

    await _cache.putFile(
      _cacheKey,
      Uint8List.fromList(utf8.encode(payload)),
      key: _cacheKey,
      fileExtension: 'json',
    );
  }
}
