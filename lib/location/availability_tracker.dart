import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_application_practice/location/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Owns the beautician's Active state and the periodic location sharing.
/// A singleton, so it keeps running while pages come and go.
class AvailabilityTracker {
  AvailabilityTracker._();
  static final AvailabilityTracker instance = AvailabilityTracker._();

  /// How often the location is sent while Active is ON. Change it here to
  /// trade freshness for battery. The server hides beauticians whose last
  /// update is older than 10 minutes, so keep this well below that.
  static const Duration uploadInterval = Duration(minutes: 2);

  final ValueNotifier<bool> active = ValueNotifier(false);
  final ValueNotifier<bool> busy = ValueNotifier(false);

  SupabaseClient get _db => Supabase.instance.client;

  StreamSubscription<Position>? _stream; // keeps the app alive in background
  Timer? _timer; // sends the position every uploadInterval
  Position? _latest;
  DateTime? _latestAt;
  bool _syncing = false;

  // ── Toggle ────────────────────────────────────────────────────────────
  Future<void> turnOn() async {
    if (busy.value) return;
    busy.value = true;
    try {
      await _activate();
    } finally {
      busy.value = false;
    }
  }

  Future<void> turnOff() async {
    if (busy.value) return;
    busy.value = true;
    try {
      await _db.rpc('set_beautician_active', params: {'p_active': false});
      _stopTracking();
      active.value = false;
    } finally {
      busy.value = false;
    }
  }

  Future<void> _activate() async {
    final pos = await LocationService.currentPosition();
    await _db.rpc('set_beautician_active', params: {
      'p_active': true,
      'p_lat': pos.latitude,
      'p_lng': pos.longitude,
    });
    _latest = pos;
    _latestAt = DateTime.now();
    _startTracking();
    active.value = true;
  }

  // ── Restore the saved state when the beautician's screen appears ──────
  Future<void> sync() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null || busy.value || _syncing) return;
    _syncing = true;
    try {
      final row = await _db
          .from('beauticians')
          .select('is_available')
          .eq('user_id', uid)
          .maybeSingle();
      final saved = row?['is_available'] == true;

      if (saved && _stream == null) {
        // Was Active when the app was closed: resume sharing.
        busy.value = true;
        try {
          await _activate();
        } catch (e) {
          // Can't track any more (permission removed, GPS off...). Don't stay
          // listed with an old location.
          debugPrint('could not resume Active: $e');
          try {
            await _db.rpc('set_beautician_active', params: {'p_active': false});
          } catch (_) {}
          active.value = false;
        } finally {
          busy.value = false;
        }
      } else if (!saved && _stream != null) {
        _stopTracking();
        active.value = false;
      } else {
        active.value = saved;
      }
    } catch (e) {
      debugPrint('availability sync failed: $e');
    } finally {
      _syncing = false;
    }
  }

  /// Call on logout: stop sharing and mark the beautician offline.
  Future<void> shutdown() async {
    _stopTracking();
    active.value = false;
    try {
      await _db.rpc('set_beautician_active', params: {'p_active': false});
    } catch (e) {
      debugPrint('shutdown: $e'); // clients have no beautician row, that's fine
    }
  }

  // ── Tracking ──────────────────────────────────────────────────────────
  void _startTracking() {
    _stopTracking();
    _stream =
        Geolocator.getPositionStream(locationSettings: _settings()).listen(
      (p) {
        _latest = p;
        _latestAt = DateTime.now();
      },
      onError: (Object e) => debugPrint('location stream error: $e'),
    );
    _timer = Timer.periodic(uploadInterval, (_) => _tick());
  }

  void _stopTracking() {
    _stream?.cancel();
    _stream = null;
    _timer?.cancel();
    _timer = null;
    _latest = null;
    _latestAt = null;
  }

  LocationSettings _settings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 0,
        intervalDuration: uploadInterval,
        // The foreground service is what keeps location alive in background.
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'CareMe: Active',
          notificationText:
              'Nearby clients can find you. Turn off Active to stop sharing your location.',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.medium,
        activityType: ActivityType.other,
        distanceFilter: 100,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    }
    return const LocationSettings(
        accuracy: LocationAccuracy.medium, distanceFilter: 100);
  }

  Future<void> _tick() async {
    Position? pos;
    final at = _latestAt;
    if (_latest != null &&
        at != null &&
        DateTime.now().difference(at) <
            uploadInterval + const Duration(seconds: 30)) {
      pos = _latest;
    } else {
      // e.g. iPhone standing still: the stream stays quiet, so ask for a fix
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 20),
          ),
        );
      } catch (e) {
        debugPrint('location fix failed: $e');
        return;
      }
    }

    final p = pos;
    if (p == null) return;

    try {
      await _db.rpc('update_my_location', params: {
        'p_lat': p.latitude,
        'p_lng': p.longitude,
      });
    } on PostgrestException catch (e) {
      if (e.message == 'not_active' || e.message == 'not_authenticated') {
        _stopTracking(); // the server says we're no longer active
        active.value = false;
      } else {
        debugPrint('location upload failed: $e');
      }
    } catch (e) {
      debugPrint(
          'location upload failed: $e'); // network hiccup, retry next tick
    }
  }
}
