import 'package:flutter/material.dart';
import 'package:flutter_application_practice/pages/bookings/booking_day_timeline_page.dart';
import 'package:flutter_application_practice/pages/bookings/booking_models.dart';
import 'package:flutter_application_practice/pages/bookings/bookings_repository.dart';

class BookingCalendarView extends StatefulWidget {
  final BookingsStore store;
  final bool isBeautician;
  final bool embedded;

  const BookingCalendarView({
    super.key,
    required this.store,
    required this.isBeautician,
    this.embedded = false,
  });

  @override
  State<BookingCalendarView> createState() => _BookingCalendarViewState();
}

class _BookingCalendarViewState extends State<BookingCalendarView> {
  static const _weekdays = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const _blue = Color(0xFF2B73E9);

  late DateTime _month = DateTime.now();

  int _key(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  void _changeMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  void _openDay(DateTime day) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => BookingDayTimelinePage(
          day: day,
          store: widget.store,
          isBeautician: widget.isBeautician,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final store = widget.store;
        if (store.loading && store.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (store.error != null && store.items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(store.error!),
                TextButton(onPressed: store.load, child: const Text('Retry')),
              ],
            ),
          );
        }

        final byDay = <int, List<BookingItem>>{};
        for (final booking in store.items.where((b) => b.status.onCalendar)) {
          byDay.putIfAbsent(_key(booking.date), () => []).add(booking);
        }

        final calendar = Padding(
          padding: EdgeInsets.symmetric(
            horizontal: widget.embedded ? 0 : 24,
            vertical: widget.embedded ? 0 : 8,
          ),
          child: _monthCard(byDay),
        );

        if (widget.embedded) return calendar;
        return RefreshIndicator(
          onRefresh: store.load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [calendar, const SizedBox(height: 24)],
          ),
        );
      },
    );
  }

  Widget _monthCard(Map<int, List<BookingItem>> byDay) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_monthNames[_month.month - 1]} ${_month.year}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _changeMonth(-1),
                icon: const Icon(Icons.chevron_left, color: _blue),
              ),
              IconButton(
                onPressed: () => _changeMonth(1),
                icon: const Icon(Icons.chevron_right, color: _blue),
              ),
            ],
          ),
          Row(
            children: [
              for (final weekday in _weekdays)
                Expanded(
                  child: Center(
                    child: Text(
                      weekday,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          _grid(byDay),
        ],
      ),
    );
  }

  Widget _grid(Map<int, List<BookingItem>> byDay) {
    final first = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final lead = first.weekday % 7;
    final cells = <Widget>[
      for (var i = 0; i < lead; i++)
        const Expanded(child: SizedBox(height: 50)),
      for (var day = 1; day <= daysInMonth; day++)
        Expanded(
          child: _dayCell(DateTime(_month.year, _month.month, day), byDay),
        ),
    ];
    while (cells.length % 7 != 0) {
      cells.add(const Expanded(child: SizedBox(height: 50)));
    }

    return Column(
      children: [
        for (var i = 0; i < cells.length; i += 7)
          Row(children: cells.sublist(i, i + 7)),
      ],
    );
  }

  Widget _dayCell(DateTime day, Map<int, List<BookingItem>> byDay) {
    final count = byDay[_key(day)]?.length ?? 0;
    final today = DateTime.now();
    final isToday = day.year == today.year &&
        day.month == today.month &&
        day.day == today.day;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openDay(day),
      child: SizedBox(
        height: 50,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final diameter =
                constraints.maxWidth < 42 ? constraints.maxWidth : 42.0;
            return Center(
              child: SizedBox(
                width: diameter,
                height: diameter,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: count > 0
                            ? const Color(0xFFFCE4E4)
                            : isToday
                                ? const Color(0xFFDBEAFE)
                                : Colors.transparent,
                      ),
                    ),
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: diameter < 30 ? 13 : 16,
                        fontWeight:
                            count > 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (count > 0)
                      Positioned(
                        top: -3,
                        right: -3,
                        child: Container(
                          constraints:
                              const BoxConstraints(minWidth: 16, minHeight: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
