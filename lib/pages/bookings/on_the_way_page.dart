import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_application_practice/auth/auth_service.dart';
import 'package:flutter_application_practice/location/location_service.dart';
import 'package:flutter_application_practice/pages/beautician/services/service_models.dart';
import 'package:flutter_application_practice/pages/bookings/booking_detail_sheet.dart';
import 'package:flutter_application_practice/pages/bookings/booking_models.dart';
import 'package:flutter_application_practice/pages/bookings/bookings_repository.dart';
import 'package:flutter_application_practice/pages/bookings/beautician_arrived_page.dart';
import 'package:flutter_application_practice/pages/bookings/beautician_complete_service.dart';
import 'package:flutter_application_practice/pages/client/booking/mapbox_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnTheWayPage extends StatefulWidget {
  final BookingItem booking;
  final bool isBeautician;
  final BookingsStore store;

  const OnTheWayPage({
    super.key,
    required this.booking,
    required this.isBeautician,
    required this.store,
  });

  @override
  State<OnTheWayPage> createState() => _OnTheWayPageState();
}

class _OnTheWayPageState extends State<OnTheWayPage> {
  final _repo = BookingsRepository();
  final _mapController = MapController();
  Map<String, dynamic>? _trip;
  List<LatLng> _route = const [];
  StreamSubscription<Position>? _location;
  RealtimeChannel? _channel;
  Timer? _clock;
  Timer? _routeTimer;
  Timer? _clientLocationTimer;
  Timer? _phaseTimer;
  DateTime? _lastRouteRequest;
  LatLng? _localPosition;
  bool _loading = true;
  bool _tripBusy = false;
  bool _startingLocationUpdates = false;
  bool _sharingClientLocation = false;
  bool _mapReady = false;
  bool _beauticianGpsCentered = false;
  bool _detailsCollapsed = false;
  bool _phaseNavigationQueued = false;
  bool _phaseCheckBusy = false;
  String? _error;
  String? _locationError;
  int? _etaMinutes;

  String? _text(String key) {
    return _trip?[key]?.toString();
  }

  double? _number(String key) {
    final value = _trip?[key];
    return value is num ? value.toDouble() : null;
  }

  LatLng? get _destination {
    final lat = _number('destination_latitude');
    final lng = _number('destination_longitude');
    if (lat == null || lng == null || !_validCoordinates(lat, lng)) {
      return null;
    }
    return LatLng(lat, lng);
  }

  LatLng? get _beauticianPosition {
    final lat = _number('beautician_latitude');
    final lng = _number('beautician_longitude');
    if (lat == null || lng == null || !_validCoordinates(lat, lng)) {
      return null;
    }
    return LatLng(lat, lng);
  }

  LatLng? get _sharedClientPosition {
    final lat = _number('client_latitude');
    final lng = _number('client_longitude');
    if (lat == null || lng == null || !_validCoordinates(lat, lng)) {
      return null;
    }
    return LatLng(lat, lng);
  }

  static bool _validCoordinates(double latitude, double longitude) =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  LatLng? get _cameraCenter {
    if (widget.isBeautician && _isOnTheWay) {
      return _localPosition;
    }
    return _destination;
  }

  bool get _isOnTheWay => _text('status') == 'on_the_way';
  String get _serviceName => widget.booking.variantName == null
      ? widget.booking.serviceTitle
      : '${widget.booking.serviceTitle} • ${widget.booking.variantName}';

  @override
  void initState() {
    super.initState();
    _loadTrip();
    if (!widget.isBeautician) _loadClientPosition();
    _channel = _repo.subscribeToTrip(widget.booking.id, _loadTrip);
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    if (!widget.isBeautician) {
      _phaseTimer = Timer.periodic(
        const Duration(seconds: 4),
        (_) => _checkPhaseTransition(),
      );
    }
  }

  @override
  void dispose() {
    _location?.cancel();
    if (!widget.isBeautician && _sharingClientLocation) {
      _repo
          .updateClientTripLocation(
        bookingId: widget.booking.id,
        latitude: null,
        longitude: null,
      )
          .catchError((Object e) {
        debugPrint('clear shared client location failed: $e');
      });
    }
    _clock?.cancel();
    _routeTimer?.cancel();
    _clientLocationTimer?.cancel();
    _phaseTimer?.cancel();
    final channel = _channel;
    if (channel != null) _repo.unsubscribeFromTrip(channel);
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadTrip() async {
    try {
      final phase = await _repo.fetchBookingPhase(widget.booking.id);
      if (!mounted) return;
      if (phase['status'] == 'completed') {
        await _navigateToCompleted(
          DateTime.parse(phase['completed_at'] as String).toLocal(),
        );
        return;
      }
      if (!widget.isBeautician && phase['arrived_at'] != null) {
        await _navigateToArrived();
        return;
      }

      final trip = await _repo.fetchTrip(widget.booking.id);
      if (!mounted) return;
      setState(() {
        _trip = trip;
        _loading = false;
        _error = null;
      });
      await _loadRoute();
      if (widget.isBeautician &&
          trip['status'] == 'on_the_way' &&
          phase['arrived_at'] == null) {
        await _startLocationUpdates();
      }
    } catch (e) {
      debugPrint('load booking trip failed: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AuthService.friendlyError(e);
      });
    }
  }

  Future<void> _navigateToArrived() async {
    if (_phaseNavigationQueued || !mounted) return;
    _phaseNavigationQueued = true;
    await _location?.cancel();
    if (!mounted) return;
    _location = null;
    _routeTimer?.cancel();
    _clientLocationTimer?.cancel();
    await Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute(
        builder: (_) => BeauticianArrivedPage(
          booking: widget.booking,
          isBeautician: widget.isBeautician,
          store: widget.store,
        ),
      ),
    );
  }

  Future<void> _navigateToCompleted(DateTime completedAt) async {
    if (_phaseNavigationQueued || !mounted) return;
    _phaseNavigationQueued = true;
    await _location?.cancel();
    _location = null;
    _routeTimer?.cancel();
    _clientLocationTimer?.cancel();
    await widget.store.load();
    if (!mounted) return;
    await Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute(
        builder: (_) => BeauticianCompleteServicePage(
          booking: widget.booking,
          isBeautician: widget.isBeautician,
          store: widget.store,
          completedAt: completedAt,
        ),
      ),
    );
  }

  Future<void> _checkPhaseTransition() async {
    if (_phaseCheckBusy || _phaseNavigationQueued || !mounted) return;
    _phaseCheckBusy = true;
    try {
      final phase = await _repo.fetchBookingPhase(widget.booking.id);
      if (!mounted) return;
      if (phase['status'] == 'completed') {
        await _navigateToCompleted(
          DateTime.parse(phase['completed_at'] as String).toLocal(),
        );
      } else if (!widget.isBeautician && phase['arrived_at'] != null) {
        await _navigateToArrived();
      }
    } catch (e) {
      debugPrint('check booking phase failed: $e');
    } finally {
      _phaseCheckBusy = false;
    }
  }

  Future<void> _loadRoute() async {
    final origin = _beauticianPosition;
    final destination = _destination;
    if (!_isOnTheWay || origin == null || destination == null) {
      if (mounted) setState(() => _route = const []);
      return;
    }
    final now = DateTime.now();
    if (_lastRouteRequest != null &&
        now.difference(_lastRouteRequest!) < const Duration(seconds: 30)) {
      return;
    }
    _lastRouteRequest = now;
    if (!MapboxService.hasToken) {
      if (mounted) setState(() => _error = 'Map directions are unavailable.');
      return;
    }

    try {
      final coordinates =
          '${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}';
      final uri = Uri.https(
          'api.mapbox.com', '/directions/v5/mapbox/driving/$coordinates', {
        'geometries': 'geojson',
        'overview': 'full',
        'access_token': MapboxService.token,
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw Exception('Mapbox directions failed (${response.statusCode}).');
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = body['routes'] as List;
      if (routes.isEmpty) throw Exception('No driving route was returned.');
      final route = Map<String, dynamic>.from(routes.first as Map);
      final geometry = Map<String, dynamic>.from(route['geometry'] as Map);
      final points = (geometry['coordinates'] as List)
          .map((c) => LatLng(
                (c[1] as num).toDouble(),
                (c[0] as num).toDouble(),
              ))
          .toList();
      if (!mounted) return;
      setState(() {
        _route = points;
        _etaMinutes = ((route['duration'] as num).toDouble() / 60).ceil();
        _error = null;
      });
    } catch (e) {
      debugPrint('load booking route failed: $e');
      if (!mounted) return;
      setState(() => _error = 'Could not load driving directions: $e');
    }
  }

  Future<void> _startLocationUpdates() async {
    if (_location != null || _startingLocationUpdates) return;
    if (mounted) {
      setState(() {
        _startingLocationUpdates = true;
        _locationError = null;
      });
    }
    try {
      await LocationService.ensurePermission();
      if (!mounted) return;
      final initial = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      final point = LatLng(initial.latitude, initial.longitude);
      _setLocalPosition(point);
      await _repo.updateTripLocation(
        bookingId: widget.booking.id,
        latitude: initial.latitude,
        longitude: initial.longitude,
      );
      await _loadTrip();
      _location = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen(
        (position) {
          final point = LatLng(position.latitude, position.longitude);
          _setLocalPosition(point);
          _repo
              .updateTripLocation(
            bookingId: widget.booking.id,
            latitude: position.latitude,
            longitude: position.longitude,
          )
              .catchError((Object e) {
            debugPrint('update booking trip location failed: $e');
          });
          _routeTimer?.cancel();
          _routeTimer = Timer(const Duration(seconds: 5), _loadTrip);
        },
        onError: (Object e) {
          debugPrint('booking trip location stream failed: $e');
          if (mounted) {
            setState(() => _locationError = 'Live location is unavailable: $e');
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _locationError = e is LocationProblem
            ? e.message
            : 'Could not get live location: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _startingLocationUpdates = false);
      } else {
        _startingLocationUpdates = false;
      }
    }
  }

  Future<void> _loadClientPosition() async {
    try {
      final position = await LocationService.currentPosition();
      if (!mounted) return;
      setState(() {
        _localPosition = LatLng(position.latitude, position.longitude);
        _locationError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _locationError = e is LocationProblem
          ? e.message
          : 'Could not get your current location: $e');
    }
  }

  Future<void> _toggleClientLocationSharing() async {
    if (_sharingClientLocation) {
      await _location?.cancel();
      _location = null;
      _clientLocationTimer?.cancel();
      _clientLocationTimer = null;
      try {
        await _repo.updateClientTripLocation(
          bookingId: widget.booking.id,
          latitude: null,
          longitude: null,
        );
      } catch (e) {
        debugPrint('stop client location sharing failed: $e');
      }
      if (mounted) {
        setState(() {
          _sharingClientLocation = false;
          _locationError = null;
        });
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Share live location?'),
        content: const Text(
          'Your beautician can see your current location during this booking.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Share location'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _startingLocationUpdates = true;
      _locationError = null;
    });
    try {
      await LocationService.ensurePermission();
      final initial = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      final point = LatLng(initial.latitude, initial.longitude);
      await _repo.updateClientTripLocation(
        bookingId: widget.booking.id,
        latitude: point.latitude,
        longitude: point.longitude,
      );
      if (!mounted) {
        await _repo.updateClientTripLocation(
          bookingId: widget.booking.id,
          latitude: null,
          longitude: null,
        );
        return;
      }
      setState(() {
        _localPosition = point;
        _sharingClientLocation = true;
      });
      _location = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen(
        (position) {
          final current = LatLng(position.latitude, position.longitude);
          if (mounted) {
            setState(() {
              _localPosition = current;
              _locationError = null;
            });
          }
          _repo
              .updateClientTripLocation(
            bookingId: widget.booking.id,
            latitude: current.latitude,
            longitude: current.longitude,
          )
              .catchError((Object e) {
            debugPrint('update shared client location failed: $e');
          });
        },
        onError: (Object e) {
          debugPrint('client location stream failed: $e');
          if (mounted) {
            setState(() => _locationError = 'Live location is unavailable: $e');
          }
        },
      );
      _clientLocationTimer = Timer.periodic(
        const Duration(minutes: 2),
        (_) => _refreshClientLocation(),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _locationError = e is LocationProblem
            ? e.message
            : 'Could not get live location: $e');
      }
    } finally {
      if (mounted) setState(() => _startingLocationUpdates = false);
    }
  }

  Future<void> _refreshClientLocation() async {
    if (!_sharingClientLocation || !mounted) return;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      final point = LatLng(position.latitude, position.longitude);
      await _repo.updateClientTripLocation(
        bookingId: widget.booking.id,
        latitude: point.latitude,
        longitude: point.longitude,
      );
      if (mounted) {
        setState(() {
          _localPosition = point;
          _locationError = null;
        });
      }
    } catch (e) {
      debugPrint('refresh shared client location failed: $e');
      if (mounted) {
        setState(() => _locationError = 'Live location is unavailable: $e');
      }
    }
  }

  void _recenter() {
    final center = _cameraCenter;
    if (center != null && _mapReady) _mapController.move(center, 15);
  }

  void _collapseDetails() {
    if (_detailsCollapsed) return;
    setState(() => _detailsCollapsed = true);
  }

  void _restoreDetails() {
    if (!_detailsCollapsed) return;
    setState(() => _detailsCollapsed = false);
  }

  void _setLocalPosition(LatLng point) {
    if (!mounted) return;
    setState(() {
      _localPosition = point;
      _locationError = null;
    });
    if (widget.isBeautician &&
        _isOnTheWay &&
        _mapReady &&
        !_beauticianGpsCentered) {
      _mapController.move(point, 15);
      _beauticianGpsCentered = true;
    }
  }

  void _onMapReady() {
    _mapReady = true;
    if (!widget.isBeautician || !_isOnTheWay) return;
    final center = _cameraCenter;
    if (center != null) _mapController.move(center, 15);
    if (_localPosition != null) _beauticianGpsCentered = true;
  }

  Widget _mapUnavailable() {
    final waitingForLocation = _loading ||
        (widget.isBeautician && _isOnTheWay && _startingLocationUpdates);
    final message = waitingForLocation
        ? 'Getting the booking location...'
        : _locationError ??
            (widget.isBeautician && _isOnTheWay
                ? 'Waiting for the beautician’s GPS location.'
                : 'The service location is unavailable for this booking.');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (waitingForLocation)
              const CircularProgressIndicator(strokeWidth: 2)
            else
              const Icon(Icons.location_off_outlined,
                  size: 36, color: Color(0xFF6B7280)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Future<void> _startTrip() async {
    setState(() => _tripBusy = true);
    try {
      await widget.store.startOnTheWay(widget.booking.id);
      await _loadTrip();
    } catch (e) {
      debugPrint('start booking trip failed: $e');
      if (mounted) setState(() => _error = AuthService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _tripBusy = false);
    }
  }

  Future<void> _cancelTrip() async {
    final cancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel booking'),
        content: const Text('Do you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep booking'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );
    if (cancel != true) return;

    try {
      await widget.store.cancel(widget.booking.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('cancel booking failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AuthService.friendlyError(e))),
        );
      }
    }
  }

  Future<void> _arrive() async {
    if (_tripBusy) return;
    setState(() {
      _tripBusy = true;
      _error = null;
    });
    try {
      await _repo.markArrived(widget.booking.id);
      await _location?.cancel();
      _location = null;
      _routeTimer?.cancel();
      await widget.store.load();
      await _navigateToArrived();
    } catch (e) {
      debugPrint('mark booking arrived failed: $e');
      if (mounted) {
        setState(() {
          _tripBusy = false;
          _error = AuthService.friendlyError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final destination = _destination;
    final center = _cameraCenter;
    final beauticianPosition = widget.isBeautician
        ? _localPosition ?? _beauticianPosition
        : _beauticianPosition;
    final clientPosition = widget.isBeautician
        ? _sharedClientPosition
        : _localPosition ?? _sharedClientPosition;
    final isOnTheWay = _isOnTheWay;
    final start = widget.booking.startAt;
    final end = start.add(Duration(minutes: widget.booking.effectiveMinutes));
    final remaining = end.difference(DateTime.now());
    final countdown = remaining.isNegative
        ? 'Service time has ended'
        : '${remaining.inHours.toString().padLeft(2, '0')}:'
            '${(remaining.inMinutes % 60).toString().padLeft(2, '0')}:'
            '${(remaining.inSeconds % 60).toString().padLeft(2, '0')} remaining';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(_serviceName, maxLines: 1),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Column(
              children: [
                Text(
                  isOnTheWay
                      ? 'Service Ongoing  •  ${timeLabel(widget.booking.startMinutes)} – ${timeLabel(widget.booking.endMinutes)}'
                      : 'Ongoing  •  ${timeLabel(widget.booking.startMinutes)} – ${timeLabel(widget.booking.endMinutes)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFFF3B3B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isOnTheWay)
                  Text(countdown,
                      style: const TextStyle(color: Color(0xFFFF3B3B))),
              ],
            ),
          ),
          Expanded(
            child: MapboxService.hasToken
                ? center == null
                    ? _mapUnavailable()
                    : Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: center,
                              initialZoom: 15,
                              onMapReady: _onMapReady,
                              onTap: (_, __) => _collapseDetails(),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: MapboxService.tileUrl,
                                userAgentPackageName: 'com.careme.app',
                              ),
                              if (_route.isNotEmpty)
                                PolylineLayer(
                                  polylines: [
                                    Polyline(
                                      points: _route,
                                      strokeWidth: 6,
                                      color: const Color(0xFF2B73E9),
                                    ),
                                  ],
                                ),
                              MarkerLayer(
                                markers: [
                                  if (destination != null)
                                    Marker(
                                      point: destination,
                                      width: 42,
                                      height: 42,
                                      child: const Icon(
                                        Icons.location_on,
                                        color: Color(0xFF8B5CF6),
                                        size: 40,
                                      ),
                                    ),
                                  if (isOnTheWay && beauticianPosition != null)
                                    Marker(
                                      point: beauticianPosition,
                                      width: 42,
                                      height: 42,
                                      child: const Icon(
                                        Icons.directions_car,
                                        color: Color(0xFFE5484D),
                                        size: 36,
                                      ),
                                    ),
                                  if (clientPosition != null)
                                    Marker(
                                      point: clientPosition,
                                      width: 42,
                                      height: 42,
                                      child: const Icon(
                                        Icons.person_pin_circle,
                                        color: Color(0xFF168A8A),
                                        size: 40,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: IconButton.filledTonal(
                              onPressed: _recenter,
                              tooltip: 'Recenter map',
                              icon: const Icon(Icons.my_location),
                            ),
                          ),
                          if (!widget.isBeautician && isOnTheWay)
                            Positioned(
                              left: 12,
                              bottom: 12,
                              child: FilledButton.tonalIcon(
                                onPressed: _startingLocationUpdates
                                    ? null
                                    : _toggleClientLocationSharing,
                                icon: Icon(_sharingClientLocation
                                    ? Icons.location_off_outlined
                                    : Icons.share_location_outlined),
                                label: Text(_startingLocationUpdates
                                    ? 'Getting location...'
                                    : _sharingClientLocation
                                        ? 'Stop sharing'
                                        : 'Share live location'),
                              ),
                            ),
                          if (_detailsCollapsed)
                            Positioned(
                              right: 12,
                              bottom: 12,
                              child: IconButton.filled(
                                onPressed: _restoreDetails,
                                tooltip: 'Show booking details',
                                icon: const Icon(Icons.arrow_upward_rounded),
                              ),
                            ),
                        ],
                      )
                : const Center(
                    child: Text('Add a Mapbox token to enable the live map.'),
                  ),
          ),
          if (_locationError != null && center != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
              child: Text(
                _locationError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFEF4444)),
              ),
            ),
          if (_loading)
            const LinearProgressIndicator(minHeight: 2)
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                _error!,
                style: const TextStyle(color: Color(0xFFEF4444)),
              ),
            ),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: double.infinity,
              child: _detailsCollapsed
                  ? const SizedBox(height: 0)
                  : _bookingCard(isOnTheWay),
            ),
          ),
          if (widget.isBeautician && !isOnTheWay)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 58,
                      height: 58,
                      child: IconButton.filled(
                        onPressed: _tripBusy ? null : _cancelTrip,
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFF04438),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.close, size: 34),
                        tooltip: 'Cancel booking',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 58,
                        child: FilledButton(
                          onPressed: _tripBusy ? null : _startTrip,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFFF3B3B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 8,
                          ),
                          child: Text(
                            _tripBusy ? 'Please wait...' : 'On The Way',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (widget.isBeautician && isOnTheWay)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: _tripBusy ? null : _arrive,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF3B3B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _tripBusy ? 'Please wait...' : 'Arrived',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bookingCard(bool isOnTheWay) {
    final name =
        _text(widget.isBeautician ? 'client_name' : 'beautician_name') ??
            widget.booking.otherName;
    final image =
        _text(widget.isBeautician ? 'client_image' : 'beautician_image');
    final distanceKm = _number('distance_km')?.toStringAsFixed(1);

    return GestureDetector(
      onTap: () => showBookingDetail(
        context,
        booking: widget.store.items.firstWhere(
          (item) => item.id == widget.booking.id,
          orElse: () => widget.booking,
        ),
        isBeautician: widget.isBeautician,
        store: widget.store,
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
                color: Color(0x24000000), blurRadius: 12, offset: Offset(0, 3))
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundImage:
                  image == null || image.isEmpty ? null : NetworkImage(image),
              child: image == null || image.isEmpty
                  ? const Icon(Icons.person_outline)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    isOnTheWay
                        ? widget.isBeautician
                            ? 'Client'
                            : 'On the way'
                        : widget.isBeautician
                            ? 'Client · Waiting for On The Way'
                            : 'Beautician has not started the trip yet',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                    ),
                  ),
                  if (_text('barangay') case final String barangay)
                    Text(barangay,
                        style: const TextStyle(
                            color: Color(0xFF6B7280), fontSize: 12)),
                  const SizedBox(height: 8),
                  Text(_serviceName,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('×${widget.booking.quantity}'),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (distanceKm != null)
                  Text(
                    'Distance $distanceKm km',
                    style: const TextStyle(
                        color: Color(0xFF22C55E),
                        fontWeight: FontWeight.w600,
                        fontSize: 12),
                  ),
                if (isOnTheWay && _etaMinutes != null)
                  Text(
                    'Arrive in $_etaMinutes min',
                    style: const TextStyle(
                        color: Color(0xFF22C55E),
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                Text(
                  formatPeso(widget.booking.totalPrice),
                  style: const TextStyle(
                    color: Color(0xFFFF3B3B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
