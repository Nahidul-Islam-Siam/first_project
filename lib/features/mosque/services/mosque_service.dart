import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

import 'package:first_project/features/mosque/models/mosque_item.dart';

enum MosqueLookupErrorType { network, server, format, unknown }

class MosqueLookupException implements Exception {
  const MosqueLookupException({required this.type, required this.message});

  final MosqueLookupErrorType type;
  final String message;

  @override
  String toString() => message;
}

class MosqueService {
  MosqueService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://overpass-api.de/api',
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 20),
              sendTimeout: const Duration(seconds: 15),
              responseType: ResponseType.json,
            ),
          );

  final Dio _dio;

  Future<List<MosqueItem>> fetchNearbyMosques({
    required double latitude,
    required double longitude,
    int radiusMeters = 5000,
    int limit = 30,
  }) async {
    final radius = radiusMeters.clamp(500, 25000);
    final maxItems = limit.clamp(1, 100);
    final query =
        '''
[out:json][timeout:25];
(
  node["amenity"="place_of_worship"]["religion"="muslim"](around:$radius,$latitude,$longitude);
  way["amenity"="place_of_worship"]["religion"="muslim"](around:$radius,$latitude,$longitude);
  relation["amenity"="place_of_worship"]["religion"="muslim"](around:$radius,$latitude,$longitude);
);
out center 80;
''';

    try {
      final response = await _dio.get(
        '/interpreter',
        queryParameters: {'data': query},
      );
      final root = response.data;
      if (root is! Map) {
        throw const MosqueLookupException(
          type: MosqueLookupErrorType.format,
          message: 'Invalid mosque response payload.',
        );
      }

      final elements = root['elements'];
      if (elements is! List) return const [];

      final output = <MosqueItem>[];
      final seen = <String>{};
      var id = 1;

      for (final raw in elements) {
        if (raw is! Map) continue;
        final item = Map<String, dynamic>.from(raw);
        final center = item['center'];
        final centerMap = center is Map
            ? Map<String, dynamic>.from(center)
            : null;
        final lat = _toDouble(item['lat']) ?? _toDouble(centerMap?['lat']);
        final lng = _toDouble(item['lon']) ?? _toDouble(centerMap?['lon']);
        if (lat == null || lng == null) continue;

        final key = '${lat.toStringAsFixed(5)},${lng.toStringAsFixed(5)}';
        if (!seen.add(key)) continue;

        final tagsRaw = item['tags'];
        final tags = tagsRaw is Map
            ? Map<String, dynamic>.from(tagsRaw)
            : const <String, dynamic>{};

        final name = _resolveName(tags);
        final address = _resolveAddress(tags);
        final distanceKm =
            Geolocator.distanceBetween(latitude, longitude, lat, lng) / 1000;

        output.add(
          MosqueItem(
            id: id++,
            name: name,
            latitude: lat,
            longitude: lng,
            distanceKm: distanceKm,
            address: address,
          ),
        );
      }

      output.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      if (output.length <= maxItems) return output;
      return output.sublist(0, maxItems);
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionError:
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          throw const MosqueLookupException(
            type: MosqueLookupErrorType.network,
            message: 'No internet connection. Please check and retry.',
          );
        case DioExceptionType.badResponse:
          throw const MosqueLookupException(
            type: MosqueLookupErrorType.server,
            message: 'Mosque server is not responding right now.',
          );
        default:
          throw MosqueLookupException(
            type: MosqueLookupErrorType.unknown,
            message: 'Could not fetch nearby mosques (${e.type.name}).',
          );
      }
    } on FormatException catch (e) {
      throw MosqueLookupException(
        type: MosqueLookupErrorType.format,
        message: e.message,
      );
    } on MosqueLookupException {
      rethrow;
    } catch (e) {
      throw MosqueLookupException(
        type: MosqueLookupErrorType.unknown,
        message: 'Unexpected mosque lookup error: $e',
      );
    }
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String _resolveName(Map<String, dynamic> tags) {
    final direct = (tags['name'] ?? '').toString().trim();
    if (direct.isNotEmpty) return direct;

    final english = (tags['name:en'] ?? '').toString().trim();
    if (english.isNotEmpty) return english;

    final bn = (tags['name:bn'] ?? '').toString().trim();
    if (bn.isNotEmpty) return bn;

    return 'Mosque';
  }

  String _resolveAddress(Map<String, dynamic> tags) {
    final parts = <String>[];
    final street = (tags['addr:street'] ?? '').toString().trim();
    final suburb = (tags['addr:suburb'] ?? '').toString().trim();
    final city = (tags['addr:city'] ?? tags['addr:town'] ?? '')
        .toString()
        .trim();
    final district = (tags['addr:district'] ?? '').toString().trim();
    final state = (tags['addr:state'] ?? '').toString().trim();

    if (street.isNotEmpty) parts.add(street);
    if (suburb.isNotEmpty) parts.add(suburb);
    if (city.isNotEmpty) parts.add(city);
    if (district.isNotEmpty && district != city) parts.add(district);
    if (state.isNotEmpty && state != city) parts.add(state);

    if (parts.isNotEmpty) return parts.join(', ');

    final isIn = (tags['is_in'] ?? '').toString().trim();
    if (isIn.isNotEmpty) return isIn;

    return 'Nearby area';
  }
}
