import 'package:flutter/material.dart';
import 'package:flutter_application_practice/pages/bookings/booking_card.dart';
import 'package:flutter_application_practice/pages/bookings/booking_detail_sheet.dart';
import 'package:flutter_application_practice/pages/bookings/booking_models.dart';
import 'package:flutter_application_practice/pages/bookings/bookings_repository.dart';

/// Filters + search + status-colored cards. Used by both roles.
class BookingsPanel extends StatefulWidget {
  final bool isBeautician;
  final BookingsStore? store; // share one with the calendar, or leave null
  final bool embedded; // true inside a parent ListView (no inner scrolling)

  const BookingsPanel({
    super.key,
    required this.isBeautician,
    this.store,
    this.embedded = false,
  });

  @override
  State<BookingsPanel> createState() => _BookingsPanelState();
}

class _BookingsPanelState extends State<BookingsPanel> {
  late final BookingsStore _store;
  final _search = TextEditingController();
  BookingFilter _filter = BookingFilter.all;

  @override
  void initState() {
    super.initState();
    _store = widget.store ?? BookingsStore();
  }

  @override
  void dispose() {
    if (widget.store == null) _store.dispose();
    _search.dispose();
    super.dispose();
  }

  List<BookingItem> _visible() {
    final q = _search.text.trim().toLowerCase();
    final list = _store.items.where((b) {
      if (!_filter.matches(b.status)) return false;
      if (q.isEmpty) return true;
      return b.serviceTitle.toLowerCase().contains(q) ||
          (b.variantName ?? '').toLowerCase().contains(q) ||
          b.otherName.toLowerCase().contains(q);
    }).toList();

    switch (_filter) {
      case BookingFilter.all:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case BookingFilter.requests:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case BookingFilter.ongoing:
      case BookingFilter.upcoming:
        list.sort((a, b) => a.startAt.compareTo(b.startAt));
      case BookingFilter.completed:
      case BookingFilter.cancelled:
        list.sort((a, b) => b.startAt.compareTo(a.startAt));
    }
    return list;
  }

  String get _emptyText => switch (_filter) {
        BookingFilter.all => 'No bookings yet.',
        BookingFilter.requests => 'No booking requests yet.',
        BookingFilter.ongoing => 'No ongoing bookings.',
        BookingFilter.upcoming => 'No upcoming bookings.',
        BookingFilter.completed => 'No completed bookings yet.',
        BookingFilter.cancelled => 'No cancelled bookings.',
      };

  Widget _filterRow() {
    final unseenRequests = widget.isBeautician &&
        _store.items.any((b) => !b.seen && b.status == BookingStatus.pending);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < BookingFilter.values.length; i++) ...[
            if (i > 0)
              const Text('|', style: TextStyle(color: Color(0xFF9CA3AF))),
            InkWell(
              onTap: () => setState(() => _filter = BookingFilter.values[i]),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Text(
                      BookingFilter.values[i].label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: BookingFilter.values[i] == _filter
                            ? Colors.black
                            : const Color(0xFF6B7280),
                      ),
                    ),
                    if (unseenRequests &&
                        BookingFilter.values[i] == BookingFilter.requests)
                      Positioned(
                        right: -7,
                        top: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _searchField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.black87),
      ),
      child: TextField(
        controller: _search,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          hintText: 'Search bookings',
          border: InputBorder.none,
          suffixIcon: Icon(Icons.search, color: Color(0xFF3B9AE1)),
        ),
      ),
    );
  }

  Widget _empty() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text(_emptyText,
              style: const TextStyle(color: Color(0xFF6B7280))),
        ),
      );

  Widget _cards(List<BookingItem> items) {
    return Column(
      children: [
        for (final b in items)
          BookingCard(
            booking: b,
            isBeautician: widget.isBeautician,
            onTap: () => openBooking(
              context,
              booking: b,
              isBeautician: widget.isBeautician,
              store: _store,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final items = _visible();

        Widget body;
        if (_store.loading) {
          body = const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (_store.error != null && _store.items.isEmpty) {
          body = Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Column(
                children: [
                  Text(_store.error!),
                  TextButton(
                      onPressed: _store.load, child: const Text('Retry')),
                ],
              ),
            ),
          );
        } else if (items.isEmpty) {
          body = _empty();
        } else {
          body = _cards(items);
        }

        if (widget.embedded) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _filterRow(),
              const SizedBox(height: 12),
              _searchField(),
              const SizedBox(height: 14),
              body,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              child: _filterRow(),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _searchField(),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _store.load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  children: [body],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
