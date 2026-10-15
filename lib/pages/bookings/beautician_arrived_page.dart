import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_practice/pages/beautician/services/service_models.dart';
import 'package:flutter_application_practice/pages/beautician/services/service_repository.dart';
import 'package:flutter_application_practice/pages/bookings/booking_models.dart';
import 'package:flutter_application_practice/pages/bookings/bookings_repository.dart';
import 'package:flutter_application_practice/pages/bookings/beautician_complete_service.dart';
import 'package:flutter_application_practice/profile/profile_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BeauticianArrivedPage extends StatefulWidget {
  final BookingItem booking;
  final bool isBeautician;
  final BookingsStore store;

  const BeauticianArrivedPage({
    super.key,
    required this.booking,
    required this.isBeautician,
    required this.store,
  });

  @override
  State<BeauticianArrivedPage> createState() => _BeauticianArrivedPageState();
}

class _BeauticianArrivedPageState extends State<BeauticianArrivedPage> {
  final _bookings = BookingsRepository();
  final _services = ServiceRepository();
  Map<String, dynamic>? _details;
  ServiceRatingSummary? _beauticianRating;
  RealtimeChannel? _channel;
  Timer? _clock;
  Timer? _phaseTimer;
  bool _loading = true;
  bool _checkingPhase = false;
  bool _busy = false;
  bool _completionNavigationQueued = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _channel = _bookings.subscribeToTrip(widget.booking.id, _checkPhase);
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _phaseTimer =
        Timer.periodic(const Duration(seconds: 4), (_) => _checkPhase());
  }

  @override
  void dispose() {
    _clock?.cancel();
    _phaseTimer?.cancel();
    final channel = _channel;
    if (channel != null) _bookings.unsubscribeFromTrip(channel);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final details = await _bookings.fetchServiceDetails(widget.booking.id);
      if (!mounted) return;
      setState(() {
        _details = details;
        _loading = false;
        _error = null;
      });
      if (!widget.isBeautician) {
        final rating = await _services.fetchBeauticianRatingSummary(
          details['beautician_id'] as String,
        );
        if (mounted) setState(() => _beauticianRating = rating);
      }
      await _checkPhase();
    } catch (e) {
      debugPrint('load arrived booking details failed: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load booking details. Please try again.';
      });
    }
  }

  Future<void> _checkPhase() async {
    if (_checkingPhase || _completionNavigationQueued || !mounted) return;
    _checkingPhase = true;
    try {
      final phase = await _bookings.fetchBookingPhase(widget.booking.id);
      if (!mounted || phase['status'] != 'completed') return;
      _completionNavigationQueued = true;
      await widget.store.load();
      if (!mounted) return;
      final completedAt =
          DateTime.parse(phase['completed_at'] as String).toLocal();
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
    } catch (e) {
      debugPrint('check booking completion failed: $e');
    } finally {
      _checkingPhase = false;
    }
  }

  Future<void> _completeService() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Complete this service?'),
        content: const Text(
          'This will finish the booking and stop live location sharing.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep booking open'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Complete service'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    _completionNavigationQueued = true;
    try {
      final completedAt = await _bookings.completeService(widget.booking.id);
      await widget.store.load();
      if (!mounted) return;
      await Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute(
          builder: (_) => BeauticianCompleteServicePage(
            booking: widget.booking,
            isBeautician: true,
            store: widget.store,
            completedAt: completedAt,
          ),
        ),
      );
    } catch (e) {
      debugPrint('complete booking service failed: $e');
      _completionNavigationQueued = false;
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not complete the service. Please try again.';
        });
      }
    }
  }

  String _text(String key, [String fallback = '']) =>
      _details?[key]?.toString() ?? fallback;

  double _amount(String key, double fallback) {
    final value = _details?[key];
    return value is num ? value.toDouble() : fallback;
  }

  int _minutes(String key, int fallback) {
    final value = _details?[key];
    return value is num ? value.toInt() : fallback;
  }

  String get _serviceName =>
      _text('service_title', widget.booking.serviceTitle);

  String get _variantName =>
      _text('variant_name', widget.booking.variantName ?? '');

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      );

  Widget _detailLine(String label, String value, {bool emphasized = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child:
                  Text(label, style: const TextStyle(color: Color(0xFF6B7280))),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontWeight: emphasized ? FontWeight.bold : FontWeight.w600,
                  color: emphasized ? const Color(0xFFCF493D) : Colors.black,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _profileSection() {
    final name = widget.isBeautician
        ? _text('client_name', widget.booking.otherName)
        : _text('beautician_name', widget.booking.otherName);
    final image = widget.isBeautician
        ? _text('client_image', widget.booking.otherImage ?? '')
        : _text('beautician_image', widget.booking.otherImage ?? '');
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          ProfileAvatar(
            initial: initial,
            imageUrl: image.isEmpty ? null : image,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                if (widget.isBeautician) ...[
                  const _RoleBadge(label: 'CLIENT', color: Color(0xFF267A79)),
                  if (_text('client_phone', widget.booking.otherPhone ?? '')
                      .isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(_text('client_phone', widget.booking.otherPhone ?? ''),
                        style: const TextStyle(color: Color(0xFF4B5563))),
                  ],
                ] else
                  Wrap(
                    spacing: 14,
                    runSpacing: 4,
                    children: [
                      const Text('0 followers',
                          style: TextStyle(color: Color(0xFF6B7280))),
                      Text(
                        _beauticianRating?.average == null
                            ? 'No ratings yet'
                            : '★ ${_beauticianRating!.average!.toStringAsFixed(1)} (${_beauticianRating!.count})',
                        style: const TextStyle(color: Color(0xFF8B6412)),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _addressSection() {
    final address = _text('address', widget.booking.address ?? '').trim();
    final landmark =
        _text('landmark_note', widget.booking.landmarkNote ?? '').trim();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F8F8),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.location_on_outlined, color: Color(0xFF267A79)),
                SizedBox(width: 8),
                Text('Service address',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(address.isEmpty ? 'Address unavailable' : address),
            if (landmark.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Landmark: $landmark',
                  style: const TextStyle(color: Color(0xFF6B7280))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _serviceSection() {
    final image = _text('service_image', widget.booking.serviceImage ?? '');
    final basePrice = _amount('service_price', widget.booking.unitPrice);
    final variantPrice = _amount('variant_price', 0);
    final unitPrice = _amount('unit_price', widget.booking.unitPrice);
    final variantMinutes = _minutes('variant_extra_minutes', 0);
    final baseMinutes = _minutes(
      'base_service_minutes',
      widget.booking.durationMinutes - variantMinutes,
    );
    final serviceMinutes =
        _minutes('service_minutes', widget.booking.durationMinutes);
    final additionalMinutes = _minutes(
      'additional_minutes',
      widget.booking.effectiveMinutes - widget.booking.durationMinutes,
    );
    final reservedMinutes =
        _minutes('reserved_minutes', widget.booking.effectiveMinutes);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Service details'),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 58,
                  height: 58,
                  child: image.isEmpty
                      ? const ColoredBox(
                          color: Color(0xFFF3F4F6),
                          child: Icon(Icons.spa_outlined,
                              color: Color(0xFF8B9299)),
                        )
                      : Image.network(
                          image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const ColoredBox(
                            color: Color(0xFFF3F4F6),
                            child: Icon(Icons.broken_image_outlined,
                                color: Color(0xFF8B9299)),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_serviceName,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (_variantName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text('Variant: $_variantName',
                            style: const TextStyle(color: Color(0xFF6B7280))),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          _detailLine('Service price', formatPeso(basePrice)),
          if (_variantName.isNotEmpty)
            _detailLine('Variant price',
                variantPrice > 0 ? '+${formatPeso(variantPrice)}' : 'Included'),
          _detailLine('Price per service', formatPeso(unitPrice)),
          _detailLine('Quantity', '${widget.booking.quantity}'),
          _detailLine('Total price', formatPeso(widget.booking.totalPrice),
              emphasized: true),
          const Divider(height: 1),
          _detailLine('Base service time', formatDuration(baseMinutes)),
          if (_variantName.isNotEmpty)
            _detailLine(
              'Variant added time',
              variantMinutes > 0
                  ? '+${formatDuration(variantMinutes)}'
                  : 'None',
            ),
          _detailLine('Service time', formatDuration(serviceMinutes)),
          _detailLine(
            'Additional reserved time',
            additionalMinutes > 0
                ? '+${formatDuration(additionalMinutes)}'
                : 'None',
          ),
          _detailLine('Total reserved time', formatDuration(reservedMinutes),
              emphasized: true),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final end = widget.booking.startAt
        .add(Duration(minutes: widget.booking.effectiveMinutes));
    final remaining = end.difference(DateTime.now());
    final countdown = remaining.isNegative
        ? 'Service window ended'
        : '${remaining.inHours.toString().padLeft(2, '0')}:'
            '${(remaining.inMinutes % 60).toString().padLeft(2, '0')}:'
            '${(remaining.inSeconds % 60).toString().padLeft(2, '0')} remaining';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text('Beautician arrived'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _details == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error ?? 'Booking details are unavailable.'),
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF153E3D),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('SERVICE WINDOW',
                              style: TextStyle(
                                  color: Color(0xFFB7D9D4),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            '${timeLabel(widget.booking.startMinutes)} - ${timeLabel(widget.booking.endMinutes)}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.timer_outlined,
                                  color: Color(0xFFFFD5C9), size: 19),
                              const SizedBox(width: 7),
                              Text(countdown,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 14)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _sectionTitle(
                        widget.isBeautician ? 'Client' : 'Beautician'),
                    _profileSection(),
                    _addressSection(),
                    const SizedBox(height: 18),
                    _serviceSection(),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(_error!,
                            style: const TextStyle(color: Color(0xFFB42318))),
                      ),
                  ],
                ),
      bottomNavigationBar: widget.isBeautician
          ? SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _completeService,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF267A79),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13)),
                    ),
                    icon: _busy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(_busy ? 'Completing...' : 'Complete Service'),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _RoleBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      );
}
