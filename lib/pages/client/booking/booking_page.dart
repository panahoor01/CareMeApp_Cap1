import 'package:flutter/material.dart';
import 'package:flutter_application_practice/auth/auth_service.dart';
import 'package:flutter_application_practice/location/location_service.dart';
import 'package:flutter_application_practice/pages/beautician/services/service_models.dart';
import 'package:flutter_application_practice/pages/client/booking/booking_repository.dart';
import 'package:flutter_application_practice/pages/client/booking/booking_submitted_page.dart';
import 'package:flutter_application_practice/pages/client/booking/map_picker_page.dart';
import 'package:flutter_application_practice/pages/client/booking/mapbox_service.dart';
import 'package:flutter_application_practice/profile/profile_service.dart';
import 'package:flutter_application_practice/profile/profile_widgets.dart';
import 'package:flutter_application_practice/profile/public_profile_repository.dart';
import 'package:flutter_application_practice/screens/signup_screen/signup_widget.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _red = Color(0xFFEF4444);

class BookingPage extends StatefulWidget {
  final PublicBeauticianProfile beautician;
  final BeauticianService service;

  const BookingPage({
    super.key,
    required this.beautician,
    required this.service,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final _repo = BookingRepository();
  final _noteController = TextEditingController();
  final _barangayController = TextEditingController();

  LatLng? _point;
  String _address = '';
  bool _locating = false;

  ServiceVariant? _variant;
  int _quantity = 1;

  DateTime? _date;
  TimeOfDay? _time;

  double? _distanceKm;
  bool _distanceLoading = false;
  bool _overlaps = false;
  int _overlapRequest = 0;

  bool _showErrors = false; // red highlights appear after the first submit try
  bool _submitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    _barangayController.dispose();
    super.dispose();
  }

  // ── Calculations ────────────────────────────────────────────────────
  bool get _hasVariants => widget.service.variants.isNotEmpty;
  double get _unitPrice => widget.service.price + (_variant?.addPrice ?? 0);
  double get _total => _unitPrice * _quantity;
  int get _unitMinutes =>
      widget.service.durationMinutes + (_variant?.extraMinutes ?? 0);
  int get _totalMinutes => _unitMinutes * _quantity;
  int? get _startMinutes =>
      _time == null ? null : _time!.hour * 60 + _time!.minute;
  int? get _endMinutes =>
      _startMinutes == null ? null : _startMinutes! + _totalMinutes;
  bool get _crossesMidnight => _endMinutes != null && _endMinutes! >= 1440;

  bool get _inPast {
    if (_date == null || _time == null) return false;
    final dt = DateTime(
        _date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);
    return dt.isBefore(DateTime.now());
  }

  bool get _outsideHours {
    if (_date == null || _time == null) return false;
    final day = scheduleDays[_date!.weekday - 1];
    final s = _startMinutes!;
    final e = _endMinutes!;
    return !widget.beautician.schedule.any((x) =>
        x.day == day &&
        x.start.hour * 60 + x.start.minute <= s &&
        x.end.hour * 60 + x.end.minute >= e);
  }

  // ── Validation ──────────────────────────────────────────────────────
  bool get _pinMissing => _point == null;
  bool get _barangayMissing =>
      _point != null && _barangayController.text.trim().isEmpty;
  bool get _variantMissing => _hasVariants && _variant == null;
  bool get _dateMissing => _date == null;
  bool get _timeMissing => _time == null;
  String? get _timeProblem {
    if (_time == null) return null;
    if (_crossesMidnight) {
      return 'This service would run past midnight. Please pick an earlier time.';
    }
    if (_inPast) return 'Please pick a time in the future.';
    return null;
  }

  bool get _valid =>
      !_pinMissing &&
      !_barangayMissing &&
      !_variantMissing &&
      !_dateMissing &&
      !_timeMissing &&
      _timeProblem == null;

  // ── Location ────────────────────────────────────────────────────────
  void _applyLocation(PickedLocation loc) {
    setState(() {
      _point = loc.point;
      _address = loc.address;
      _barangayController.text = loc.barangay;
    });
    _refreshDistance();
  }

  Future<void> _openPicker() async {
    final loc = await Navigator.push<PickedLocation>(
      context,
      MaterialPageRoute(builder: (_) => MapPickerPage(initialPoint: _point)),
    );
    if (loc != null && mounted) _applyLocation(loc);
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final pos = await LocationService.currentPosition();
      final p = LatLng(pos.latitude, pos.longitude);
      var info = const MapboxAddress(address: '', barangay: '');
      try {
        info = await MapboxService.reverse(p);
      } catch (e) {
        debugPrint('reverse geocode failed: $e');
      }
      if (!mounted) return;
      _applyLocation(PickedLocation(
          point: p, address: info.address, barangay: info.barangay));
    } on LocationProblem catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      debugPrint('current location failed: $e');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _refreshDistance() async {
    final p = _point;
    if (p == null) return;
    setState(() => _distanceLoading = true);
    try {
      final km = await _repo.distanceToBeautician(widget.beautician.id, p);
      if (!mounted || p != _point) return;
      setState(() {
        _distanceKm = km;
        _distanceLoading = false;
      });
    } catch (e) {
      debugPrint('distance failed: $e');
      if (!mounted) return;
      setState(() {
        _distanceKm = null;
        _distanceLoading = false;
      });
    }
  }

  // ── Schedule ────────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked == null) return;
    setState(() => _date = picked);
    _refreshOverlap();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked == null) return;
    setState(() => _time = picked);
    _refreshOverlap();
  }

  Future<void> _refreshOverlap() async {
    final id = ++_overlapRequest;
    if (_date == null || _time == null || _crossesMidnight) {
      setState(() => _overlaps = false);
      return;
    }
    try {
      final res = await _repo.overlapsBooking(
        beauticianId: widget.beautician.id,
        date: _date!,
        startMinutes: _startMinutes!,
        endMinutes: _endMinutes!,
      );
      if (!mounted || id != _overlapRequest) return;
      setState(() => _overlaps = res);
    } catch (e) {
      debugPrint('overlap check failed: $e');
      if (mounted && id == _overlapRequest) setState(() => _overlaps = false);
    }
  }

  void _changeQuantity(int delta) {
    setState(() => _quantity = (_quantity + delta).clamp(1, 10));
    _refreshOverlap();
  }

  void _chooseVariant(ServiceVariant v) {
    setState(() => _variant = v);
    _refreshOverlap();
  }

  // ── Labels ──────────────────────────────────────────────────────────
  static const _months = [
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
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  String _dateLabel(DateTime d) =>
      '${_weekdays[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}, ${d.year}';

  String _spanLabel() {
    final s = _time!;
    final end = _endMinutes!;
    final e = TimeOfDay(hour: (end ~/ 60) % 24, minute: end % 60);
    return '${formatTime(s)} – ${formatTime(e)}';
  }

  String _distanceLabel(double km) {
    if (km < 1) return 'Less than 1 km away';
    if (km < 10) return '${km.toStringAsFixed(1)} km away';
    return '${km.round()} km away';
  }

  // ── Submit ──────────────────────────────────────────────────────────
  String _friendly(Object e) {
    if (e is PostgrestException) {
      switch (e.message) {
        case 'booking_in_past':
          return 'That time has already passed. Please pick a later time.';
        case 'booking_crosses_midnight':
          return 'The service would run past midnight. Please pick an earlier time.';
        case 'variant_required':
        case 'invalid_variant':
          return 'Please choose a valid variant.';
        case 'service_unavailable':
          return 'This service is no longer available.';
        case 'client_only':
          return 'Only client accounts can book a service.';
        case 'invalid_quantity':
          return 'Quantity must be between 1 and 10.';
        case 'invalid_location':
        case 'invalid_barangay':
          return 'Please check the pinned location and barangay.';
      }
    }
    return AuthService.friendlyError(e);
  }

  Future<void> _submit() async {
    setState(() => _showErrors = true);
    if (!_valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in the highlighted fields.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await _repo.requestBooking(
        beauticianId: widget.beautician.id,
        serviceId: widget.service.id,
        variantId: _variant?.id,
        quantity: _quantity,
        date: _date!,
        startTime: _time!,
        point: _point!,
        address: _address,
        barangay: _barangayController.text.trim(),
        note: _noteController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BookingSubmittedPage(
            summary: BookingSummary(
              beauticianName: widget.beautician.fullName,
              serviceTitle: widget.service.title,
              variantName: _variant?.name,
              quantity: _quantity,
              dateLabel: _dateLabel(_date!),
              timeSpan: _spanLabel(),
              barangay: _barangayController.text.trim(),
              total: _total,
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('request booking failed: $e');
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_friendly(e))));
    }
  }

  // ── UI helpers ──────────────────────────────────────────────────────
  Widget _section({
    required String title,
    required Widget child,
    bool error = false,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: error ? _red : const Color(0xFFD1D5DB),
          width: error ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _errText(String text) => Padding(
        padding: const EdgeInsets.only(top: 6, left: 4),
        child: Text(text, style: const TextStyle(fontSize: 12, color: _red)),
      );

  InputDecoration _fieldDecoration(String label, {String? error}) {
    final redBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: const BorderSide(color: _red, width: 1.4),
    );
    return signupInputDecoration(label).copyWith(
      errorText: error,
      errorBorder: redBorder,
      focusedErrorBorder: redBorder,
    );
  }

  Widget _badge(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF4B5563)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  // ── Sections ────────────────────────────────────────────────────────
  Widget _locationSection() {
    final pinError = _showErrors && _pinMissing;
    final barangayError = _showErrors && _barangayMissing;

    return _section(
      title: 'Where should the beautician go?',
      error: pinError,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _openPicker,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: pinError ? _red : const Color(0xFF9CA3AF)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: _red),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _point == null
                              ? 'Pin the exact location on the map'
                              : (_address.isEmpty
                                  ? 'Pinned location'
                                  : _address),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        if (_point == null)
                          const Text('Search a place or tap the map',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF6B7280))),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Color(0xFF6B7280)),
                ],
              ),
            ),
          ),
          if (pinError) _errText('Please pin the service location.'),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _locating ? null : _useCurrentLocation,
            icon: _locating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location, size: 18),
            label: const Text('Use my current location'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: const BorderSide(color: Color(0xFF9CA3AF)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
          if (_point != null) ...[
            const SizedBox(height: 14),
            TextField(
              controller: _barangayController,
              maxLength: 100,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              decoration: _fieldDecoration(
                'Barangay',
                error: barangayError ? 'Please enter your barangay.' : null,
              ).copyWith(
                counterText: '',
                helperText:
                    'Only your barangay is shown to the beautician while they review your request.',
                helperMaxLines: 3,
              ),
            ),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: _noteController,
            maxLines: 3,
            maxLength: 300,
            textCapitalization: TextCapitalization.sentences,
            decoration:
                signupInputDecoration('Landmark or directions (optional)')
                    .copyWith(
              hintText:
                  'e.g. Blue gate beside the sari-sari store, 2nd house after the basketball court',
              hintMaxLines: 3,
              helperText:
                  'Helps the beautician find you once your request is accepted.',
              helperMaxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _variantTile(ServiceVariant v) {
    final selected = _variant?.id == v.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _chooseVariant(v),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  selected ? const Color(0xFF6AB0E4) : const Color(0xFFD1D5DB),
              width: selected ? 1.6 : 1,
            ),
            color: selected ? const Color(0xFFF0F9FF) : Colors.white,
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected
                    ? const Color(0xFF6AB0E4)
                    : const Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(v.name,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    v.addPrice > 0
                        ? '+${formatPeso(v.addPrice)}'
                        : 'No extra charge',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: v.addPrice > 0 ? _red : const Color(0xFF6B7280),
                    ),
                  ),
                  if (v.extraMinutes > 0)
                    Text('+${formatDuration(v.extraMinutes)}',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF6B7280))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback? onTap) => InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: onTap == null ? const Color(0xFFD1D5DB) : Colors.black),
          ),
          child: Icon(icon,
              size: 20,
              color: onTap == null ? const Color(0xFFD1D5DB) : Colors.black),
        ),
      );

  Widget _serviceSection() {
    final s = widget.service;
    final variantError = _showErrors && _variantMissing;

    return _section(
      title: 'Service details',
      error: variantError,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.title,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _badge(
            Icons.schedule_outlined,
            _quantity > 1
                ? '${formatDuration(_totalMinutes)}  ($_quantity × ${formatDuration(_unitMinutes)})'
                : formatDuration(_totalMinutes),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Service price',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
              const Spacer(),
              Text(formatPeso(widget.service.price),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, color: _red)),
            ],
          ),
          if (_hasVariants) ...[
            const SizedBox(height: 16),
            const Text('Choose a variant',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            for (final v in s.variants) _variantTile(v),
            if (variantError) _errText('Please choose a variant.'),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: Color(0xFFE5E7EB)),
          ),
          Row(
            children: [
              const Text('Quantity',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              _qtyButton(Icons.remove,
                  _quantity > 1 ? () => _changeQuantity(-1) : null),
              SizedBox(
                width: 48,
                child: Center(
                  child: Text('$_quantity',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              _qtyButton(
                  Icons.add, _quantity < 10 ? () => _changeQuantity(1) : null),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Price and duration are multiplied by the quantity.',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text('${formatPeso(_unitPrice)} × $_quantity',
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF6B7280))),
              ),
              const Text('Total  ',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              Text(formatPeso(_total),
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold, color: _red)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _beauticianSection() {
    final b = widget.beautician;

    final Widget distance;
    if (_point == null) {
      distance = const Text(
          'Pin your location to see how far the beautician is.',
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)));
    } else if (_distanceLoading) {
      distance = const Text('Calculating distance...',
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)));
    } else if (_distanceKm == null) {
      distance = const Text(
          'Distance unavailable right now (the beautician is not sharing their location).',
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)));
    } else {
      distance = Row(
        children: [
          const Icon(Icons.location_on, size: 18, color: Color(0xFF22C55E)),
          const SizedBox(width: 2),
          Text(_distanceLabel(_distanceKm!),
              style: const TextStyle(
                  color: Color(0xFF22C55E),
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ],
      );
    }

    return _section(
      title: 'Your beautician',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProfileAvatar(
                  initial: b.initial, imageUrl: b.profileImage, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold)),
                    // ratings aren't available yet
                    const Text('No ratings yet',
                        style:
                            TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          distance,
        ],
      ),
    );
  }

  Widget _pickerField({
    required String label,
    required String? value,
    required IconData icon,
    required VoidCallback onTap,
    String? error,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: InputDecorator(
        isEmpty: value == null,
        decoration: _fieldDecoration(label, error: error).copyWith(
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(icon, size: 20, color: const Color(0xFF6B7280)),
          ),
        ),
        child: Text(value ?? '', style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  void _showAvailability() {
    final slots = widget.beautician.schedule;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Availability schedule',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            for (final day in scheduleDays)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 56,
                      child: Text(day,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: Builder(builder: (_) {
                        final today = slots.where((s) => s.day == day).toList();
                        if (today.isEmpty) {
                          return const Text('Not available',
                              style: TextStyle(color: Color(0xFF9CA3AF)));
                        }
                        return Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            for (final s in today)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFCE4E4),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                    '${formatTime(s.start)} - ${formatTime(s.end)}'),
                              ),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _warningBanner() {
    final messages = <String>[
      if (_outsideHours)
        "Selected time is outside the beautician's working hours.",
      if (_overlaps)
        'Selected time overlaps with another booking of the beautician.',
    ];
    if (messages.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDBA74)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final m in messages)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('⚠️ $m',
                  style: const TextStyle(
                      color: Color(0xFF9A3412),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      height: 1.3)),
            ),
          const Text('You can still send your request.',
              style: TextStyle(color: Color(0xFF9A3412), fontSize: 12.5)),
          const SizedBox(height: 4),
          InkWell(
            onTap: _showAvailability,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                "See Beautician's Availability Schedule",
                style: TextStyle(
                  color: Color(0xFF1D4ED8),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scheduleSection() {
    final dateError = _showErrors && _dateMissing;
    final timeError = (_showErrors && _timeMissing) || _timeProblem != null;
    final timeErrorText = _timeProblem ??
        (_showErrors && _timeMissing ? 'Please select a time.' : null);

    return _section(
      title: 'Schedule',
      error: dateError || timeError,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _pickerField(
            label: 'Date',
            value: _date == null ? null : _dateLabel(_date!),
            icon: Icons.calendar_today_outlined,
            onTap: _pickDate,
            error: dateError ? 'Please select a date.' : null,
          ),
          const SizedBox(height: 14),
          _pickerField(
            label: 'Time',
            value: _time == null ? null : formatTime(_time!),
            icon: Icons.schedule,
            onTap: _pickTime,
            error: timeErrorText,
          ),
          if (_time != null && !_crossesMidnight) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text.rich(
                TextSpan(
                  text: 'Estimated Service Span: ',
                  style: const TextStyle(fontSize: 14),
                  children: [
                    TextSpan(
                      text: _spanLabel(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
          _warningBanner(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SignupStepScaffold(
      title: 'Book a service',
      heading: 'Request a booking.',
      subheading: 'Tell the beautician where and when you need the service.',
      continueLabel: _submitting ? 'Sending...' : 'Request booking',
      continueEnabled: !_submitting,
      onContinue: _submit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _locationSection(),
          _serviceSection(),
          _beauticianSection(),
          _scheduleSection(),
        ],
      ),
    );
  }
}
