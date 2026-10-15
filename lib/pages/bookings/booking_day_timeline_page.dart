import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_application_practice/pages/beautician/services/service_models.dart';
import 'package:flutter_application_practice/pages/bookings/booking_detail_sheet.dart';
import 'package:flutter_application_practice/pages/bookings/booking_models.dart';
import 'package:flutter_application_practice/pages/bookings/bookings_repository.dart';

class BookingDayTimelinePage extends StatefulWidget {
  final DateTime day;
  final BookingsStore store;
  final bool isBeautician;

  const BookingDayTimelinePage({
    super.key,
    required this.day,
    required this.store,
    required this.isBeautician,
  });

  @override
  State<BookingDayTimelinePage> createState() => _BookingDayTimelinePageState();
}

class _BookingDayTimelinePageState extends State<BookingDayTimelinePage> {
  static const _hourHeight = 64.0;
  static const _gutter = 68.0;
  static const _blue = Color(0xFF2B73E9);
  static const _red = Color(0xFFEF4444);

  late DateTime _now = DateTime.now();
  late final ScrollController _scrollController = ScrollController(
    initialScrollOffset: _isToday
        ? math.max(
            0.0, _now.hour * _hourHeight + _now.minute / 60 * _hourHeight - 220)
        : 0,
  );
  Timer? _clock;

  bool get _isToday =>
      widget.day.year == _now.year &&
      widget.day.month == _now.month &&
      widget.day.day == _now.day;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(dateLong(widget.day)),
      ),
      body: ListenableBuilder(
        listenable: widget.store,
        builder: (context, _) {
          final bookings = widget.store.items
              .where((b) =>
                  b.status.onCalendar &&
                  b.date.year == widget.day.year &&
                  b.date.month == widget.day.month &&
                  b.date.day == widget.day.day)
              .toList()
            ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

          return RefreshIndicator(
            onRefresh: widget.store.load,
            child: ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                Text(
                  bookings.isEmpty
                      ? 'No appointments on this day.'
                      : '${bookings.length} appointment${bookings.length == 1 ? '' : 's'}',
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 16),
                _timeline(bookings),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _timeline(List<BookingItem> bookings) {
    const timelineHeight = 24 * _hourHeight;
    final nowMinutes = _now.hour * 60 + _now.minute;

    return SizedBox(
      height: timelineHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var hour = 0; hour < 24; hour++) ...[
            Positioned(
              top: hour * _hourHeight + 4,
              left: 0,
              width: _gutter - 8,
              child: Text(
                timeLabel(hour * 60).replaceAll(':00', ''),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
            Positioned(
              top: hour * _hourHeight,
              left: _gutter,
              right: 0,
              child: const Divider(height: 1, color: Color(0xFFE5E7EB)),
            ),
          ],
          for (final booking in bookings)
            Positioned(
              top: booking.startMinutes / 60 * _hourHeight,
              left: _gutter + 6,
              right: 0,
              height: math.max(
                30.0,
                (booking.endMinutes - booking.startMinutes) / 60 * _hourHeight,
              ),
              child: _bookingBlock(booking),
            ),
          if (_isToday)
            Positioned(
              top: nowMinutes / 60 * _hourHeight,
              left: 0,
              right: 0,
              child: Row(
                children: [
                  SizedBox(
                    width: _gutter - 8,
                    child: Text(
                      timeLabel(nowMinutes),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: _red,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Divider(
                      height: 2,
                      thickness: 2,
                      color: _red,
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                    child: Icon(Icons.circle, size: 8, color: _red),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _bookingBlock(BookingItem booking) {
    final extra = booking.effectiveMinutes > booking.durationMinutes
        ? booking.effectiveMinutes - booking.durationMinutes
        : 0;
    final title = booking.variantName == null
        ? booking.serviceTitle
        : '${booking.serviceTitle} • ${booking.variantName}';

    return GestureDetector(
      onTap: () => openBooking(
        context,
        booking: booking,
        isBeautician: widget.isBeautician,
        store: widget.store,
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF2FF),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _blue.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(width: 4, color: _blue),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${timeLabel(booking.startMinutes)} – ${timeLabel(booking.endMinutes)}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    if (extra > 0)
                      Text(
                        'Service ${formatDuration(booking.durationMinutes)} + ${formatDuration(extra)} travel/prep',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
