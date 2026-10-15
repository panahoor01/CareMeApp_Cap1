import 'package:flutter/material.dart';

enum BookingStatus {
  pending,
  accepted,
  onTheWay,
  ongoing,
  completed,
  cancelled,
  declined,
}

BookingStatus parseBookingStatus(String s) {
  switch (s) {
    case 'pending':
      return BookingStatus.pending;
    case 'accepted':
      return BookingStatus.accepted;
    case 'on_the_way':
      return BookingStatus.onTheWay;
    case 'ongoing':
      return BookingStatus.ongoing;
    case 'completed':
      return BookingStatus.completed;
    case 'cancelled':
      return BookingStatus.cancelled;
    default:
      return BookingStatus.declined;
  }
}

extension BookingStatusX on BookingStatus {
  Color get color => switch (this) {
        BookingStatus.pending => const Color(0xFFF59E0B),
        BookingStatus.accepted => const Color(0xFF3B82F6),
        BookingStatus.completed => const Color(0xFF22C55E),
        _ => const Color(0xFFEF4444),
      };

  IconData get icon => switch (this) {
        BookingStatus.pending => Icons.schedule,
        BookingStatus.accepted => Icons.check_circle_outline,
        BookingStatus.onTheWay || BookingStatus.ongoing => Icons.error_outline,
        BookingStatus.completed => Icons.task_alt,
        BookingStatus.cancelled ||
        BookingStatus.declined =>
          Icons.cancel_outlined,
      };

  String get label => switch (this) {
        BookingStatus.pending => 'Pending',
        BookingStatus.accepted => 'Upcoming',
        BookingStatus.onTheWay => 'On the way',
        BookingStatus.ongoing => 'Ongoing',
        BookingStatus.completed => 'Completed',
        BookingStatus.cancelled => 'Cancelled',
        BookingStatus.declined => 'Declined',
      };

  bool get isInProgress =>
      this == BookingStatus.onTheWay || this == BookingStatus.ongoing;

  /// Shown as an appointment on the beautician's calendar.
  bool get onCalendar => this == BookingStatus.accepted || isInProgress;
}

enum BookingFilter { all, requests, ongoing, upcoming, completed, cancelled }

extension BookingFilterX on BookingFilter {
  String get label => switch (this) {
        BookingFilter.all => 'All',
        BookingFilter.requests => 'Requests',
        BookingFilter.ongoing => 'Ongoing',
        BookingFilter.upcoming => 'Upcoming',
        BookingFilter.completed => 'Completed',
        BookingFilter.cancelled => 'Cancelled',
      };

  bool matches(BookingStatus s) => switch (this) {
        BookingFilter.all => true,
        BookingFilter.requests => s == BookingStatus.pending,
        BookingFilter.ongoing => s.isInProgress,
        BookingFilter.upcoming => s == BookingStatus.accepted,
        BookingFilter.completed => s == BookingStatus.completed,
        BookingFilter.cancelled =>
          s == BookingStatus.cancelled || s == BookingStatus.declined,
      };
}

class BookingItem {
  final String id;
  final String
      otherName; // the client (beautician view) or beautician (client view)
  final String? otherPhone;
  final String? otherImage;
  final String serviceTitle;
  final String? variantName;
  final String? serviceImage;
  final double unitPrice;
  final int quantity;
  final double totalPrice;
  final DateTime date;
  final int startMinutes;
  final int endMinutes;
  final int durationMinutes;
  final int? finalDurationMinutes;
  final String barangay;
  final double? distanceKm;
  final BookingStatus status;
  bool seen;
  final String? address; // beautician: only after accepting
  final String? landmarkNote;
  final DateTime createdAt;

  BookingItem({
    required this.id,
    required this.otherName,
    this.otherPhone,
    this.otherImage,
    required this.serviceTitle,
    this.variantName,
    this.serviceImage,
    required this.unitPrice,
    required this.quantity,
    required this.totalPrice,
    required this.date,
    required this.startMinutes,
    required this.endMinutes,
    required this.durationMinutes,
    this.finalDurationMinutes,
    required this.barangay,
    this.distanceKm,
    required this.status,
    required this.seen,
    this.address,
    this.landmarkNote,
    required this.createdAt,
  });

  static int _mins(String t) {
    final p = t.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }

  factory BookingItem.fromRow(Map<String, dynamic> r) {
    return BookingItem(
      id: r['booking_id'] as String,
      otherName: r['other_name'] as String,
      otherPhone: r['other_phone'] as String?,
      otherImage: r['other_image'] as String?,
      serviceTitle: r['service_title'] as String,
      variantName: r['service_variant_name'] as String?,
      serviceImage: r['service_image'] as String?,
      unitPrice: (r['unit_price'] as num).toDouble(),
      quantity: r['quantity'] as int,
      totalPrice: (r['total_price'] as num).toDouble(),
      date: DateTime.parse(r['booking_date'] as String),
      startMinutes: _mins(r['start_time'] as String),
      endMinutes: _mins(r['end_time'] as String),
      durationMinutes: r['duration_minutes'] as int,
      finalDurationMinutes: r['final_duration_minutes'] as int?,
      barangay: r['barangay'] as String,
      distanceKm: r['distance_km'] == null
          ? null
          : (r['distance_km'] as num).toDouble(),
      status: parseBookingStatus(r['status'] as String),
      seen: r['is_seen'] as bool,
      address: r['address'] as String?,
      landmarkNote: r['landmark_note'] as String?,
      createdAt: DateTime.parse(r['created_at'] as String).toLocal(),
    );
  }

  int get effectiveMinutes => finalDurationMinutes ?? durationMinutes;

  DateTime get startAt => DateTime(
      date.year, date.month, date.day, startMinutes ~/ 60, startMinutes % 60);
}

// ── Formatting helpers ──────────────────────────────────────────────────
const _monthsShort = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
const _weekdaysShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// 1020 -> "5:00 PM"
String timeLabel(int minutes) {
  final h24 = (minutes ~/ 60) % 24;
  final m = minutes % 60;
  final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
  return '$h12:${m.toString().padLeft(2, '0')} ${h24 < 12 ? 'AM' : 'PM'}';
}

String dateShort(DateTime d) => '${_monthsShort[d.month - 1]} ${d.day}';

String dateLong(DateTime d) =>
    '${_weekdaysShort[d.weekday - 1]}, ${_monthsShort[d.month - 1]} ${d.day}, ${d.year}';

/// 2h, 10h, 3d, 1w
String timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'now';
  if (d.inMinutes < 60) return '${d.inMinutes}m';
  if (d.inHours < 24) return '${d.inHours}h';
  if (d.inDays < 7) return '${d.inDays}d';
  return '${(d.inDays / 7).floor()}w';
}
