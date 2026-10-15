import 'package:flutter/material.dart';
import 'package:flutter_application_practice/auth/auth_service.dart';
import 'package:flutter_application_practice/pages/beautician/services/service_models.dart';
import 'package:flutter_application_practice/pages/bookings/booking_models.dart';
import 'package:flutter_application_practice/pages/bookings/on_the_way_page.dart';
import 'package:flutter_application_practice/pages/bookings/bookings_repository.dart';
import 'package:flutter_application_practice/screens/signup_screen/signup_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Opens the booking details. A beautician opening a request marks it as seen.
Future<void> showBookingDetail(
  BuildContext context, {
  required BookingItem booking,
  required bool isBeautician,
  required BookingsStore store,
}) {
  if (isBeautician && booking.status == BookingStatus.pending) {
    store.markSeen(booking);
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _BookingDetail(
        booking: booking, isBeautician: isBeautician, store: store),
  );
}

Future<void> openBooking(
  BuildContext context, {
  required BookingItem booking,
  required bool isBeautician,
  required BookingsStore store,
}) {
  if (booking.status.isInProgress) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => OnTheWayPage(
          booking: booking,
          isBeautician: isBeautician,
          store: store,
        ),
      ),
    );
  }
  return showBookingDetail(
    context,
    booking: booking,
    isBeautician: isBeautician,
    store: store,
  );
}

class _BookingDetail extends StatefulWidget {
  final BookingItem booking;
  final bool isBeautician;
  final BookingsStore store;

  const _BookingDetail({
    required this.booking,
    required this.isBeautician,
    required this.store,
  });

  @override
  State<_BookingDetail> createState() => _BookingDetailState();
}

class _BookingDetailState extends State<_BookingDetail> {
  int _hours = 0;
  int _minutes = 0;
  bool _busy = false;
  String? _error;

  BookingItem get b => widget.booking;
  int get _additionalMinutes => _hours * 60 + _minutes;
  int get _finalMinutes => b.durationMinutes + _additionalMinutes;
  int get _acceptedAdditionalMinutes => b.effectiveMinutes > b.durationMinutes
      ? b.effectiveMinutes - b.durationMinutes
      : 0;
  int get _newEnd => b.startMinutes + _finalMinutes;

  String _friendly(Object e) {
    if (e is PostgrestException) {
      switch (e.message) {
        case 'booking_overlap':
          return 'This time conflicts with another accepted booking. Call the client using the number below to agree on another time. The booking time cannot be changed here, so decline this request and ask the client to submit a new request for the agreed time.';
        case 'booking_not_pending':
          return 'This request was already handled.';
        case 'booking_crosses_midnight':
          return 'The service would run past midnight. Please shorten the time.';
        case 'invalid_duration':
          return 'Please set how long the service will take.';
        case 'service_duration_cannot_be_reduced':
          return 'Service duration cannot be reduced. Only additional travel and preparation time may be added.';
        case 'booking_not_ongoing':
          return 'This booking is not ready for travel yet.';
        case 'cannot_cancel':
          return 'This booking can no longer be cancelled.';
        case 'booking_not_found':
          return 'This booking is no longer available.';
      }
    }
    return AuthService.friendlyError(e);
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text(success)));
    } catch (e) {
      debugPrint('booking action failed: $e');
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _friendly(e);
      });
    }
  }

  Future<bool> _confirm(String title, String message, String yes) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Back'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(yes, style: const TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _accept() async {
    if (_newEnd >= 1440) {
      setState(() => _error =
          'The reserved time would run past midnight. Please reduce the additional time.');
      return;
    }
    await _run(
      () =>
          widget.store.respond(b.id, accept: true, finalMinutes: _finalMinutes),
      'Booking accepted.',
    );
  }

  Future<void> _decline() async {
    if (!await _confirm('Decline request',
        'Decline this booking request from ${b.otherName}?', 'Decline')) {
      return;
    }
    await _run(
        () => widget.store.respond(b.id, accept: false), 'Request declined.');
  }

  Future<void> _cancel() async {
    final what = b.status == BookingStatus.pending ? 'request' : 'booking';
    if (!await _confirm(
        'Cancel $what', 'Do you want to cancel this $what?', 'Cancel $what')) {
      return;
    }
    await _run(() => widget.store.cancel(b.id), 'Cancelled.');
  }

  Future<void> _startOnTheWay() async {
    final navigator = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.store.startOnTheWay(b.id);
      if (!mounted) return;
      final updated = widget.store.items.firstWhere(
        (item) => item.id == b.id,
        orElse: () => b,
      );
      Navigator.pop(context);
      await navigator.push<void>(
        MaterialPageRoute(
          builder: (_) => OnTheWayPage(
            booking: updated,
            isBeautician: true,
            store: widget.store,
          ),
        ),
      );
    } catch (e) {
      debugPrint('start booking trip failed: $e');
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _friendly(e);
      });
    }
  }

  Widget _info(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6B7280)),
          const SizedBox(width: 10),
          SizedBox(
            width: 82,
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown(
      String label, int value, int count, ValueChanged<int> onChanged) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      menuMaxHeight: 280,
      decoration: signupInputDecoration(label),
      items: List.generate(
          count, (i) => DropdownMenuItem(value: i, child: Text('$i'))),
      onChanged: (v) {
        if (v == null) return;
        setState(() {
          onChanged(v);
          _error = null;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = b.status;
    final isPending = status == BookingStatus.pending;
    final adjusting = widget.isBeautician && isPending;
    final canCancel = widget.isBeautician
        ? status == BookingStatus.accepted || status == BookingStatus.ongoing
        : (isPending || status == BookingStatus.accepted);
    final endMinutes = adjusting ? _newEnd : b.endMinutes;
    final crosses = endMinutes >= 1440;
    final hasAddress = (b.address ?? '').isNotEmpty;
    final canBeauticianSeeAddress =
        !widget.isBeautician || status == BookingStatus.onTheWay;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(b.serviceTitle,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(status.icon, size: 14, color: status.color),
                    const SizedBox(width: 4),
                    Text(status.label,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: status.color)),
                  ],
                ),
              ),
            ],
          ),
          if (b.variantName != null)
            Text('• ${b.variantName}',
                style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563))),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _info(
                      Icons.person_outline,
                      widget.isBeautician ? 'Client' : 'Beautician',
                      b.otherName),
                  if (widget.isBeautician)
                    _info(
                      Icons.phone_outlined,
                      'Client phone',
                      b.otherPhone ?? 'Not available',
                    ),
                  _info(
                      Icons.calendar_today_outlined, 'Date', dateLong(b.date)),
                  _info(
                    Icons.schedule,
                    'Time',
                    crosses
                        ? '${timeLabel(b.startMinutes)} – past midnight'
                        : '${timeLabel(b.startMinutes)} – ${timeLabel(endMinutes)}',
                    valueColor: crosses ? const Color(0xFFEF4444) : null,
                  ),
                  if (!adjusting)
                    _info(
                      Icons.hourglass_bottom,
                      'Service time',
                      formatDuration(b.durationMinutes),
                    ),
                  if (!adjusting && !isPending)
                    _info(
                      Icons.add_alarm_outlined,
                      'Additional time',
                      '+ ${formatDuration(_acceptedAdditionalMinutes)} · Travel and preparation',
                    ),
                  if (!isPending)
                    _info(
                      Icons.timelapse,
                      'Total reserved',
                      formatDuration(b.effectiveMinutes),
                    ),
                  _info(
                      Icons.shopping_bag_outlined, 'Quantity', '${b.quantity}'),
                  _info(Icons.payments_outlined, 'Price',
                      '${formatPeso(b.unitPrice)} × ${b.quantity}'),
                  _info(Icons.sell_outlined, 'Total', formatPeso(b.totalPrice),
                      valueColor: const Color(0xFFEF4444)),
                  const Divider(height: 24),
                  _info(
                    Icons.location_on_outlined,
                    'Barangay',
                    b.distanceKm == null
                        ? b.barangay
                        : '${b.barangay} • ${b.distanceKm!.toStringAsFixed(1)} km',
                  ),
                  if (hasAddress && canBeauticianSeeAddress)
                    _info(Icons.home_outlined, 'Address', b.address!),
                  if ((b.landmarkNote ?? '').isNotEmpty &&
                      canBeauticianSeeAddress)
                    _info(Icons.flag_outlined, 'Landmark', b.landmarkNote!),
                  if (widget.isBeautician &&
                      status != BookingStatus.onTheWay &&
                      (status == BookingStatus.pending ||
                          status == BookingStatus.accepted ||
                          status == BookingStatus.ongoing))
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        "The full address and landmark are shown only after you tap “On The Way”.",
                        style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF6B7280),
                            height: 1.4),
                      ),
                    ),
                  if (!widget.isBeautician && isPending)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('Waiting for the beautician to respond.',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF6B7280))),
                    ),
                  if (adjusting) ...[
                    const Divider(height: 24),
                    const Text('Before accepting this booking',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const Text(
                      'Service duration cannot be reduced or modified. You may only add extra time to account for travel and preparation. The “On The Way” button will only be available once the booking enters the Ongoing phase. Please ensure that the additional time is sufficient for you to reach the client\'s agreed location.',
                      style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF6B7280),
                          height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    _info(Icons.hourglass_bottom, 'Service time',
                        formatDuration(b.durationMinutes)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                            child: _dropdown(
                                'Extra hours', _hours, 24, (v) => _hours = v)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _dropdown('Extra minutes', _minutes, 60,
                                (v) => _minutes = v)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _info(
                      Icons.add_alarm_outlined,
                      'Additional time',
                      '+ ${formatDuration(_additionalMinutes)} · Travel and preparation',
                    ),
                    _info(
                      Icons.timelapse,
                      'Total reserved',
                      formatDuration(_finalMinutes),
                    ),
                    _info(
                      Icons.schedule,
                      'Scheduled time',
                      crosses
                          ? '${timeLabel(b.startMinutes)} – past midnight'
                          : '${timeLabel(b.startMinutes)} – ${timeLabel(_newEnd)}',
                      valueColor: crosses ? const Color(0xFFEF4444) : null,
                    ),
                  ],
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(_error!,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFFEF4444))),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (adjusting)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: OutlinedButton(
                      onPressed: _busy ? null : _decline,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28)),
                      ),
                      child: const Text('Decline',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SignupContinueButton(
                    label: _busy ? 'Please wait...' : 'Accept',
                    onPressed: _busy ? null : _accept,
                  ),
                ),
              ],
            )
          else if (widget.isBeautician && status == BookingStatus.ongoing)
            Row(
              children: [
                SizedBox(
                  width: 58,
                  height: 58,
                  child: IconButton.filled(
                    onPressed: _busy ? null : _cancel,
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
                      onPressed: _busy ? null : _startOnTheWay,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF3B3B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 8,
                      ),
                      child: Text(
                        _busy ? 'Please wait...' : 'On The Way',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else if (canCancel)
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton(
                onPressed: _busy ? null : _cancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                ),
                child: Text(
                  isPending && !widget.isBeautician
                      ? 'Cancel request'
                      : 'Cancel booking',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          const SafeArea(top: false, child: SizedBox(height: 4)),
        ],
      ),
    );
  }
}
