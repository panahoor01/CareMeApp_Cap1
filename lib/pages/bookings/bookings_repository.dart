import 'package:flutter/foundation.dart';
import 'package:flutter_application_practice/auth/auth_service.dart';
import 'package:flutter_application_practice/pages/bookings/booking_models.dart';
import 'package:flutter_application_practice/realtime/app_badges.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingsRepository {
  SupabaseClient get _db => Supabase.instance.client;

  Future<List<BookingItem>> fetch() async {
    final res = await _db.rpc('get_my_bookings');
    return (res as List)
        .map((e) => BookingItem.fromRow(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> respond(String id,
      {required bool accept, int? finalMinutes}) async {
    await _db.rpc('respond_to_booking', params: {
      'p_booking_id': id,
      'p_accept': accept,
      'p_final_minutes': finalMinutes,
    });
  }

  Future<void> cancel(String id) async {
    await _db.rpc('cancel_booking', params: {'p_booking_id': id});
  }

  Future<void> markSeen(String id) async {
    await _db.rpc('mark_booking_seen', params: {'p_booking_id': id});
  }

  Future<void> startOnTheWay(String id) async {
    await _db.rpc('start_booking_trip', params: {'p_booking_id': id});
  }

  Future<Map<String, dynamic>> fetchTrip(String id) async {
    final result = await _db.rpc(
      'get_booking_trip',
      params: {'p_booking_id': id},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> fetchBookingPhase(String id) async {
    final result = await _db.rpc(
      'get_booking_phase',
      params: {'p_booking_id': id},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> fetchServiceDetails(String id) async {
    final result = await _db.rpc(
      'get_booking_service_details',
      params: {'p_booking_id': id},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<void> markArrived(String id) async {
    await _db.rpc('mark_booking_arrived', params: {'p_booking_id': id});
  }

  Future<DateTime> completeService(String id) async {
    final result = await _db.rpc(
      'complete_booking_service',
      params: {'p_booking_id': id},
    );
    final row = Map<String, dynamic>.from(result as Map);
    return DateTime.parse(row['completed_at'] as String).toLocal();
  }

  Future<void> updateTripLocation({
    required String bookingId,
    required double latitude,
    required double longitude,
  }) async {
    await _db.rpc('update_booking_trip_location', params: {
      'p_booking_id': bookingId,
      'p_lat': latitude,
      'p_lng': longitude,
    });
  }

  Future<void> updateClientTripLocation({
    required String bookingId,
    required double? latitude,
    required double? longitude,
  }) async {
    await _db.rpc('update_booking_client_location', params: {
      'p_booking_id': bookingId,
      'p_lat': latitude,
      'p_lng': longitude,
    });
  }

  RealtimeChannel subscribeToTrip(
    String bookingId,
    void Function() onChange,
  ) {
    return _db
        .channel('booking-trip-$bookingId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'booking_trip_locations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'booking_id',
            value: bookingId,
          ),
          callback: (_) => onChange(),
        )
        .subscribe();
  }

  Future<void> unsubscribeFromTrip(RealtimeChannel channel) async {
    await _db.removeChannel(channel);
  }
}

/// Holds the logged-in user's bookings and reloads them when something changes.
class BookingsStore extends ChangeNotifier {
  final _repo = BookingsRepository();
  List<BookingItem> items = const [];
  bool loading = true;
  String? error;
  int _requestId = 0;
  bool _disposed = false;

  BookingsStore() {
    AppBadges.instance.changes.addListener(load);
    load();
  }

  Future<void> load() async {
    final id = ++_requestId;
    try {
      final list = await _repo.fetch();
      if (_disposed || id != _requestId) return;
      items = list;
      loading = false;
      error = null;
      notifyListeners();
    } catch (e) {
      debugPrint('load bookings failed: $e');
      if (_disposed || id != _requestId) return;
      loading = false;
      if (items.isEmpty) error = AuthService.friendlyError(e);
      notifyListeners();
    }
  }

  Future<void> markSeen(BookingItem b) async {
    if (b.seen) return;
    b.seen = true;
    notifyListeners();
    try {
      await _repo.markSeen(b.id);
    } catch (e) {
      debugPrint('mark seen failed: $e');
    }
    AppBadges.instance.refresh();
  }

  Future<void> respond(String id,
      {required bool accept, int? finalMinutes}) async {
    await _repo.respond(id, accept: accept, finalMinutes: finalMinutes);
    await load();
    AppBadges.instance.refresh();
  }

  Future<void> startOnTheWay(String id) async {
    await _repo.startOnTheWay(id);
    await load();
    AppBadges.instance.refresh();
  }

  Future<void> cancel(String id) async {
    await _repo.cancel(id);
    await load();
    AppBadges.instance.refresh();
  }

  @override
  void dispose() {
    _disposed = true;
    AppBadges.instance.changes.removeListener(load);
    super.dispose();
  }
}
