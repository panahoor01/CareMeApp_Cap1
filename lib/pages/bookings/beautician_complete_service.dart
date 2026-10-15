import 'package:flutter/material.dart';
import 'package:flutter_application_practice/pages/beautician/services/service_models.dart';
import 'package:flutter_application_practice/pages/beautician/services/service_repository.dart';
import 'package:flutter_application_practice/pages/bookings/booking_models.dart';
import 'package:flutter_application_practice/pages/bookings/bookings_repository.dart';
import 'package:flutter_application_practice/profile/profile_widgets.dart';

class BeauticianCompleteServicePage extends StatefulWidget {
  final BookingItem booking;
  final bool isBeautician;
  final BookingsStore store;
  final DateTime completedAt;

  const BeauticianCompleteServicePage({
    super.key,
    required this.booking,
    required this.isBeautician,
    required this.store,
    required this.completedAt,
  });

  @override
  State<BeauticianCompleteServicePage> createState() =>
      _BeauticianCompleteServicePageState();
}

class _BeauticianCompleteServicePageState
    extends State<BeauticianCompleteServicePage> {
  final _bookings = BookingsRepository();
  final _services = ServiceRepository();
  final _reviewController = TextEditingController();
  Map<String, dynamic>? _details;
  ServiceRatingSummary? _beauticianRating;
  bool _loading = true;
  bool _submittingReview = false;
  bool _reviewSubmitted = false;
  String? _error;
  int _rating = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final details = await _bookings.fetchServiceDetails(widget.booking.id);
      ServiceRatingSummary? rating;
      if (!widget.isBeautician) {
        rating = await _services.fetchBeauticianRatingSummary(
          details['beautician_id'] as String,
        );
      }
      if (!mounted) return;
      setState(() {
        _details = details;
        _beauticianRating = rating;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      debugPrint('load service completion details failed: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load service details. Please try again.';
      });
    }
  }

  void _retryLoad() {
    setState(() => _loading = true);
    _load();
  }

  Future<void> _submitReview() async {
    if (_rating == 0 || _submittingReview) return;
    setState(() {
      _submittingReview = true;
      _error = null;
    });
    try {
      await _services.submitReview(
        bookingId: widget.booking.id,
        rating: _rating,
        review: _reviewController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _reviewSubmitted = true;
        _submittingReview = false;
      });
      final details = _details;
      if (details != null) {
        try {
          final rating = await _services.fetchBeauticianRatingSummary(
            details['beautician_id'] as String,
          );
          if (mounted) setState(() => _beauticianRating = rating);
        } catch (e) {
          debugPrint('refresh service rating after review failed: $e');
        }
      }
    } catch (e) {
      debugPrint('submit service review failed: $e');
      if (!mounted) return;
      setState(() {
        _submittingReview = false;
        _error = 'Could not submit your rating. Please try again.';
      });
    }
  }

  String _text(String key, [String fallback = '']) =>
      _details?[key]?.toString() ?? fallback;

  String get _serviceName =>
      _text('service_title', widget.booking.serviceTitle);

  String get _variantName =>
      _text('variant_name', widget.booking.variantName ?? '');

  String get _completedIn {
    final value = _details?['arrived_at'];
    final arrivedAt =
        value is String ? DateTime.tryParse(value)?.toLocal() : null;
    if (arrivedAt == null) return 'Unavailable';

    final totalMinutes = widget.completedAt.difference(arrivedAt).inMinutes;
    if (totalMinutes < 1) return 'Less than a minute';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours == 0) return '$minutes min${minutes == 1 ? '' : 's'}';
    if (minutes == 0) return '$hours hr${hours == 1 ? '' : 's'}';
    return '$hours hr${hours == 1 ? '' : 's'} '
        '$minutes min${minutes == 1 ? '' : 's'}';
  }

  Widget _summaryLine(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Expanded(
                child: Text(label,
                    style: const TextStyle(color: Color(0xFF6B7280)))),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _personSection({required bool showClient}) {
    final name = showClient
        ? _text('client_name', widget.booking.otherName)
        : _text('beautician_name', widget.booking.otherName);
    final image = showClient
        ? _text('client_image', widget.booking.otherImage ?? '')
        : _text('beautician_image', widget.booking.otherImage ?? '');
    final phone = showClient
        ? _text('client_phone', widget.booking.otherPhone ?? '')
        : '';
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
              initial: initial, imageUrl: image.isEmpty ? null : image),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                if (showClient) ...[
                  const Text('CLIENT',
                      style: TextStyle(
                          color: Color(0xFF267A79),
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                  if (phone.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(phone,
                          style: const TextStyle(color: Color(0xFF6B7280))),
                    ),
                ] else
                  Text(
                    _beauticianRating?.average == null
                        ? 'No service ratings yet'
                        : '★ ${_beauticianRating!.average!.toStringAsFixed(1)} (${_beauticianRating!.count})',
                    style: const TextStyle(color: Color(0xFFFFC107)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewForm() {
    if (_reviewSubmitted) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF6F3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF267A79)),
            SizedBox(width: 10),
            Expanded(child: Text('Thank you. Your service rating was saved.')),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Rate this service',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        const Text('Your rating applies only to this service.',
            style: TextStyle(color: Color(0xFF6B7280))),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var value = 1; value <= 5; value++)
              IconButton(
                tooltip: 'Rate $value stars',
                visualDensity: VisualDensity.compact,
                onPressed: _submittingReview
                    ? null
                    : () => setState(() => _rating = value),
                icon: Icon(
                  value <= _rating ? Icons.star : Icons.star_border,
                  color: const Color(0xFFFFC107),
                  size: 30,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _reviewController,
          minLines: 2,
          maxLines: 4,
          maxLength: 500,
          decoration: const InputDecoration(
            labelText: 'Review (optional)',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: _rating == 0 || _submittingReview ? null : _submitReview,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF267A79),
              foregroundColor: Colors.white,
            ),
            child: Text(_submittingReview ? 'Submitting...' : 'Submit rating'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final finished =
        timeLabel(widget.completedAt.hour * 60 + widget.completedAt.minute);
    final finishedDate = dateLong(widget.completedAt);
    final image = _text('service_image', widget.booking.serviceImage ?? '');
    final isClient = !widget.isBeautician;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text('Service completed'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
            decoration: BoxDecoration(
              color: const Color.fromARGB(80, 255, 212, 200),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF7BB8F0), size: 48),
                SizedBox(height: 10),
                Text('Service was completed',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: Color(0xFF7BB8F0), fontSize: 21, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: image.isEmpty
                            ? const ColoredBox(
                                color: Color(0xFFF3F4F6),
                                child: Icon(Icons.spa_outlined),
                              )
                            : Image.network(image,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const ColoredBox(
                                      color: Color(0xFFF3F4F6),
                                      child: Icon(Icons.broken_image_outlined),
                                    )),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_serviceName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          if (_variantName.isNotEmpty)
                            Text('Variant: $_variantName',
                                style:
                                    const TextStyle(color: Color(0xFF6B7280))),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 28),
                _summaryLine('Finished', '$finished · $finishedDate'),
                _summaryLine('Total service duration',
                    formatDuration(widget.booking.durationMinutes)),
                const SizedBox(height: 10),
                 Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7BB8F0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.timer_outlined,
                            color: Colors.white, size: 25),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Completed In',
                                style: TextStyle(
                                    color: Colors.black, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(
                              _completedIn,
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_error!,
                      style: const TextStyle(color: Color(0xFFB42318))),
                  TextButton(onPressed: _retryLoad, child: const Text('Retry')),
                ],
              ),
            ),
          if (!_loading && _details != null) ...[
            const SizedBox(height: 18),
            Text(isClient ? 'Beautician' : 'Client',
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _personSection(showClient: !isClient),
            if (isClient) ...[
              const SizedBox(height: 18),
              _reviewForm(),
            ],
          ],
        ],
      ),
    );
  }
}
