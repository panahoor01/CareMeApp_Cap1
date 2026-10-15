import 'package:flutter/material.dart' show TimeOfDay;
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _hms(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}:00';

class BookingRepository {
  SupabaseClient get _db => Supabase.instance.client;

  /// Straight-line km from the beautician's last known position (null = unknown).
  Future<double?> distanceToBeautician(
      String beauticianId, LatLng point) async {
    final res = await _db.rpc('get_distance_to_beautician', params: {
      'p_beautician_id': beauticianId,
      'p_lat': point.latitude,
      'p_lng': point.longitude,
    });
    return res == null ? null : (res as num).toDouble();
  }

  /// True when the time overlaps an accepted booking.
  Future<bool> overlapsBooking({
    required String beauticianId,
    required DateTime date,
    required int startMinutes,
    required int endMinutes,
  }) async {
    final res = await _db.rpc('check_booking_overlap', params: {
      'p_beautician_id': beauticianId,
      'p_date': _ymd(date),
      'p_start': _hms(startMinutes),
      'p_end': _hms(endMinutes),
    });
    return res == true;
  }

  Future<String> requestBooking({
    required String beauticianId,
    required String serviceId,
    required int? variantId,
    required int quantity,
    required DateTime date,
    required TimeOfDay startTime,
    required LatLng point,
    required String address,
    required String barangay,
    required String note,
  }) async {
    final res = await _db.rpc('request_booking', params: {
      'p_beautician_id': beauticianId,
      'p_service_id': serviceId,
      'p_variant_id': variantId,
      'p_quantity': quantity,
      'p_date': _ymd(date),
      'p_start_time': _hms(startTime.hour * 60 + startTime.minute),
      'p_lat': point.latitude,
      'p_lng': point.longitude,
      'p_address': address,
      'p_barangay': barangay,
      'p_note': note,
    });
    return res as String;
  }
}
