import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_practice/location/location_service.dart';
import 'package:flutter_application_practice/pages/client/booking/mapbox_service.dart';
import 'package:flutter_application_practice/screens/signup_screen/signup_widget.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class PickedLocation {
  final LatLng point;
  final String address;
  final String barangay;
  const PickedLocation(
      {required this.point, required this.address, required this.barangay});
}

class MapPickerPage extends StatefulWidget {
  final LatLng? initialPoint; // an existing pin, when editing
  const MapPickerPage({super.key, this.initialPoint});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  static const _philippines = LatLng(12.8797, 121.7740);

  final _map = MapController();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;
  int _reverseId = 0;

  LatLng? _pin;
  MapboxAddress? _resolved;
  bool _resolving = false;
  bool _locating = false;

  List<MapboxPlace> _results = [];
  bool _searching = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    if (widget.initialPoint != null) {
      _pin = widget.initialPoint;
      _resolving = true;
      _resolve(widget.initialPoint!);
    } else {
      // center the map near the client without dropping a pin
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _useMyLocation(pin: false));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _setPin(LatLng p, {bool move = false, double zoom = 17}) {
    setState(() {
      _pin = p;
      _resolved = null;
      _resolving = true;
      _results = [];
    });
    if (move) _safeMove(p, zoom);
    _resolve(p);
  }

  void _safeMove(LatLng p, double zoom) {
    try {
      _map.move(p, zoom);
    } catch (e) {
      debugPrint('map move failed: $e');
    }
  }

  Future<void> _resolve(LatLng p) async {
    final id = ++_reverseId;
    try {
      final r = await MapboxService.reverse(p);
      if (!mounted || id != _reverseId) return;
      setState(() {
        _resolved = r;
        _resolving = false;
      });
    } catch (e) {
      debugPrint('reverse geocode failed: $e');
      if (!mounted || id != _reverseId) return;
      setState(() {
        _resolved = const MapboxAddress(address: '', barangay: '');
        _resolving = false;
      });
    }
  }

  Future<void> _useMyLocation({required bool pin}) async {
    setState(() => _locating = true);
    try {
      final pos = await LocationService.currentPosition();
      if (!mounted) return;
      final here = LatLng(pos.latitude, pos.longitude);
      if (pin) {
        _setPin(here, move: true);
      } else {
        _safeMove(here, 15);
      }
    } on LocationProblem catch (e) {
      if (mounted && pin) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      debugPrint('locate failed: $e');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _onSearchChanged(String text) {
    _debounce?.cancel();
    if (text.trim().length < 3) {
      setState(() {
        _results = [];
        _searching = false;
        _searchError = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), _runSearch);
  }

  Future<void> _runSearch() async {
    final q = _searchController.text;
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      LatLng? near;
      try {
        near = _map.camera.center;
      } catch (_) {}
      final res = await MapboxService.search(q, near: near);
      if (!mounted || q != _searchController.text) return;
      setState(() {
        _results = res;
        _searching = false;
      });
    } catch (e) {
      debugPrint('place search failed: $e');
      if (!mounted) return;
      setState(() {
        _searching = false;
        _searchError = 'Search failed. Please check your connection.';
      });
    }
  }

  void _pickResult(MapboxPlace place) {
    _searchFocus.unfocus();
    _searchController.text = place.title;
    _setPin(place.point, move: true);
  }

  void _confirm() {
    final r = _resolved;
    Navigator.pop(
      context,
      PickedLocation(
        point: _pin!,
        address: r?.address ?? '',
        barangay: r?.barangay ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _map,
                  options: MapOptions(
                    initialCenter: widget.initialPoint ?? _philippines,
                    initialZoom: widget.initialPoint != null ? 17 : 5.5,
                    onTap: (_, point) {
                      FocusScope.of(context).unfocus();
                      _setPin(point);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: MapboxService.tileUrl,
                      userAgentPackageName:
                          'com.example.flutter_application_practice',
                    ),
                    if (_pin != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _pin!,
                            width: 48,
                            height: 48,
                            alignment: Alignment.topCenter,
                            child: const Icon(Icons.location_on,
                                size: 48, color: Color(0xFFEF4444)),
                          ),
                        ],
                      ),
                    const RichAttributionWidget(
                      alignment: AttributionAlignment.bottomLeft,
                      attributions: [
                        TextSourceAttribution('© Mapbox'),
                        TextSourceAttribution('© OpenStreetMap'),
                      ],
                    ),
                  ],
                ),
                if (!MapboxService.hasToken)
                  const Center(
                    child: Card(
                      margin: EdgeInsets.all(24),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Mapbox token is missing.\nSet AppConfig.mapboxToken.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Material(
                              color: Colors.white,
                              elevation: 3,
                              shape: const CircleBorder(),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Material(
                                color: Colors.white,
                                elevation: 3,
                                borderRadius: BorderRadius.circular(28),
                                child: TextField(
                                  controller: _searchController,
                                  focusNode: _searchFocus,
                                  textInputAction: TextInputAction.search,
                                  onChanged: _onSearchChanged,
                                  onSubmitted: (_) => _runSearch(),
                                  decoration: InputDecoration(
                                    hintText: 'Search a place or address',
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 14),
                                    suffixIcon: _searching
                                        ? const Padding(
                                            padding: EdgeInsets.all(14),
                                            child: SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2),
                                            ),
                                          )
                                        : const Icon(Icons.search),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_results.isNotEmpty || _searchError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, left: 52),
                            child: Material(
                              color: Colors.white,
                              elevation: 3,
                              borderRadius: BorderRadius.circular(16),
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxHeight: 280),
                                child: _searchError != null
                                    ? Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Text(_searchError!),
                                      )
                                    : ListView.separated(
                                        shrinkWrap: true,
                                        padding: EdgeInsets.zero,
                                        itemCount: _results.length,
                                        separatorBuilder: (_, __) =>
                                            const Divider(height: 1),
                                        itemBuilder: (_, i) {
                                          final r = _results[i];
                                          return ListTile(
                                            dense: true,
                                            leading: const Icon(
                                                Icons.place_outlined),
                                            title: Text(r.title,
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                            subtitle: r.subtitle.isEmpty
                                                ? null
                                                : Text(r.subtitle,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis),
                                            onTap: () => _pickResult(r),
                                          );
                                        },
                                      ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 28,
                  child: FloatingActionButton.small(
                    heroTag: null,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    onPressed:
                        _locating ? null : () => _useMyLocation(pin: true),
                    child: _locating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 10,
                    offset: Offset(0, -2)),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_pin == null)
                    const Text(
                      'Tap the map to drop a pin on the exact place where the service will take place.',
                      style: TextStyle(color: Color(0xFF6B7280), height: 1.4),
                    )
                  else if (_resolving)
                    const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 10),
                        Text('Finding the address...'),
                      ],
                    )
                  else ...[
                    Text(
                      (_resolved?.address ?? '').isEmpty
                          ? 'Pinned location'
                          : _resolved!.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    if ((_resolved?.barangay ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('Barangay ${_resolved!.barangay}',
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF6B7280))),
                      ),
                  ],
                  const SizedBox(height: 12),
                  SignupContinueButton(
                    label: 'Confirm location',
                    onPressed: (_pin == null || _resolving) ? null : _confirm,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
