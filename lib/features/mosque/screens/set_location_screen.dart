import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:first_project/shared/widgets/bottom_nav.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class LocationSelection {
  const LocationSelection({
    required this.latitude,
    required this.longitude,
    required this.label,
  });

  final double latitude;
  final double longitude;
  final String label;
}

class SetLocationScreen extends StatefulWidget {
  const SetLocationScreen({
    super.key,
    required this.initialLatitude,
    required this.initialLongitude,
    required this.initialLabel,
  });

  final double initialLatitude;
  final double initialLongitude;
  final String initialLabel;

  @override
  State<SetLocationScreen> createState() => _SetLocationScreenState();
}

class _SetLocationScreenState extends State<SetLocationScreen> {
  static final _tileCachingProvider =
      BuiltInMapCachingProvider.getOrCreateInstance(
        maxCacheSize: 300 * 1024 * 1024,
        overrideFreshAge: const Duration(days: 14),
      );

  final TextEditingController _searchController = TextEditingController();
  late final MapController _mapController;
  late LatLng _selectedPoint;
  late String _selectedLabel;
  bool _resolvingLabel = false;
  bool _locatingCurrent = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedPoint = LatLng(widget.initialLatitude, widget.initialLongitude);
    _selectedLabel = widget.initialLabel;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onTapMap(LatLng point) async {
    setState(() => _selectedPoint = point);
    await _resolveLabelFromCoordinates(point);
  }

  Future<void> _resolveLabelFromCoordinates(LatLng point) async {
    if (_searchController.text.trim().isNotEmpty) return;
    setState(() => _resolvingLabel = true);
    try {
      final placemarks = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      if (placemarks.isEmpty) return;
      final place = placemarks.first;
      final city =
          place.locality ??
          place.subAdministrativeArea ??
          place.administrativeArea;
      final country = place.country;
      if (!mounted) return;
      setState(() {
        if (city != null && city.trim().isNotEmpty) {
          _selectedLabel = country == null || country.trim().isEmpty
              ? city.trim()
              : '${city.trim()}, ${country.trim()}';
        }
      });
    } catch (_) {
      // Keep existing label if reverse-geocode fails.
    } finally {
      if (mounted) {
        setState(() => _resolvingLabel = false);
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    if (_locatingCurrent) return;
    setState(() => _locatingCurrent = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enable phone location service.'),
          ),
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission denied on this device.'),
          ),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final point = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() => _selectedPoint = point);
      _mapController.move(point, 15.5);
      await _resolveLabelFromCoordinates(point);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read current location.')),
      );
    } finally {
      if (mounted) {
        setState(() => _locatingCurrent = false);
      }
    }
  }

  void _confirmSelection() {
    final typed = _searchController.text.trim();
    final label = typed.isEmpty ? _selectedLabel : typed;
    Navigator.of(context).pop(
      LocationSelection(
        latitude: _selectedPoint.latitude,
        longitude: _selectedPoint.longitude,
        label: label,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    final latText = _selectedPoint.latitude.toStringAsFixed(3);
    final lngText = _selectedPoint.longitude.toStringAsFixed(3);

    return Scaffold(
      backgroundColor: glass.bgBottom,
      body: NoorifyGlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Row(
                  children: [
                    Material(
                      color: glass.isDark
                          ? const Color(0x332EB8E6)
                          : const Color(0x221EA8B8),
                      shape: const CircleBorder(),
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: glass.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Location',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: glass.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: NoorifyGlassCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  radius: BorderRadius.circular(18),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: glass.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search',
                      hintStyle: TextStyle(color: glass.textMuted),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: glass.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _locatingCurrent ? null : _useCurrentLocation,
                    icon: _locatingCurrent
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.8,
                              color: glass.accent,
                            ),
                          )
                        : Icon(
                            Icons.my_location_rounded,
                            size: 16,
                            color: glass.accent,
                          ),
                    label: Text(
                      'Use current location',
                      style: TextStyle(
                        color: glass.accent,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _selectedPoint,
                            initialZoom: 15.5,
                            minZoom: 3,
                            maxZoom: 19,
                            onTap: (tapPosition, point) => _onTapMap(point),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.noorify.app',
                              tileProvider: NetworkTileProvider(
                                cachingProvider: _tileCachingProvider,
                              ),
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  width: 30,
                                  height: 44,
                                  point: _selectedPoint,
                                  child: const _PinMarker(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 170,
                      child: Center(
                        child: NoorifyGlassCard(
                          radius: BorderRadius.circular(12),
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                          child: SizedBox(
                            width: 196,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_rounded,
                                      size: 14,
                                      color: Color(0xFFF05555),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        _selectedLabel,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: glass.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Lat: $latText, Long:$lngText',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: glass.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (_resolvingLabel)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.8,
                                        color: glass.accent,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 84,
                      child: SizedBox(
                        height: 42,
                        child: FilledButton(
                          onPressed: _confirmSelection,
                          style: FilledButton.styleFrom(
                            backgroundColor: glass.accent,
                            foregroundColor: glass.isDark
                                ? const Color(0xFF072734)
                                : Colors.white,
                            shape: const StadiumBorder(),
                          ),
                          child: const Text(
                            'Choose Location',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16 / 1.15,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 14,
                      bottom: 76,
                      child: Material(
                        color: glass.isDark
                            ? const Color(0xEE112233)
                            : Colors.white.withValues(alpha: 0.96),
                        shape: const CircleBorder(),
                        elevation: 2,
                        child: IconButton(
                          onPressed: _useCurrentLocation,
                          icon: Icon(
                            Icons.my_location_rounded,
                            color: glass.accent,
                            size: 21,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              bottomNav(context, 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinMarker extends StatelessWidget {
  const _PinMarker();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 34,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 0,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Color(0xFFF04444),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.location_on_rounded,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: Container(
              width: 6,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFFF04444),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
