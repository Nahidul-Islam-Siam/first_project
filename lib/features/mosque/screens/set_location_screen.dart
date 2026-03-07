import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

import 'package:first_project/shared/widgets/bottom_nav.dart';

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
  final TextEditingController _searchController = TextEditingController();
  late final MapController _mapController;
  late LatLng _selectedPoint;
  late String _selectedLabel;
  bool _resolvingLabel = false;

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

  void _resetToInitial() {
    final initial = LatLng(widget.initialLatitude, widget.initialLongitude);
    setState(() {
      _selectedPoint = initial;
      _selectedLabel = widget.initialLabel;
    });
    _mapController.move(initial, 15.5);
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
    final latText = _selectedPoint.latitude.toStringAsFixed(3);
    final lngText = _selectedPoint.longitude.toStringAsFixed(3);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: Color(0xFF7E98AE),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Location',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F252D),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9EEF2),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search',
                    hintStyle: TextStyle(color: Color(0xFF8AA0B2)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: Color(0xFF8AA0B2),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
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
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 170,
                    child: Center(
                      child: Container(
                        width: 196,
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
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
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1F252D),
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
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF667B8B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_resolvingLabel)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.8,
                                    color: Color(0xFF5DA7B4),
                                  ),
                                ),
                              ),
                          ],
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
                          backgroundColor: const Color(0xFF1D98A9),
                          foregroundColor: Colors.white,
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
                      color: Colors.white.withValues(alpha: 0.96),
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: IconButton(
                        onPressed: _resetToInitial,
                        icon: const Icon(
                          Icons.my_location_rounded,
                          color: Color(0xFF5DA7B4),
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
