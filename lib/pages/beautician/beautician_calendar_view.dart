import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_application_practice/pages/bookings/booking_detail_sheet.dart';
import 'package:flutter_application_practice/pages/bookings/booking_models.dart';
import 'package:flutter_application_practice/pages/bookings/bookings_repository.dart';

class BeauticianCalendarView extends StatefulWidget {
  final BookingsStore store;
  const BeauticianCalendarView({super.key, required this.store});

  @override
  State<BeauticianCalendarView> createState() => _BeauticianCalendarViewState();
}

class _BeauticianCalendarViewState extends State<BeauticianCalendarView> {
  static const _hourHeight = 60.0;
  static const _gutter = 64.0;
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

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  late DateTime _month = DateTime(_today().year, _today().month);
  late DateTime _selected = _today();
  final _targetKey = GlobalKey();

  int _key(DateTime d) => d.year * 10000 + d.month * 100 + d.day;
  bool _same(DateTime a, DateTime b) => _key(a) == _key(b);

  void _changeMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  void _selectDay(DateTime d) {
    setState(() => _selected = d);
    // wait for the timeline to rebuild, then scroll to the first appointment
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _targetKey.currentContext;
      if (ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
          alignment: 0.2,
        );
      }
    });
  }

  String _hourLabel(int h) {
    final h24 = h % 24;
    final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
    return '$h12 ${h24 < 12 ? 'AM' : 'PM'}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final store = widget.store;
        if (store.loading) {
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

        final active = store.items.where((b) => b.status.onCalendar).toList();
        final byDay = <int, List<BookingItem>>{};
        for (final b in active) {
          byDay.putIfAbsent(_key(b.date), () => []).add(b);
        }
        final hasLater = active
            .any((b) => DateTime(b.date.year, b.date.month).isAfter(_month));

        final day = List<BookingItem>.of(byDay[_key(_selected)] ?? [])
          ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

        return RefreshIndicator(
          onRefresh: store.load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            children: [
              _monthCard(byDay, hasLater),
              const SizedBox(height: 22),
              _dayHeader(day.length),
              _timeline(day),
            ],
          ),
        );
      },
    );
  }

  Widget _monthCard(Map<int, List<BookingItem>> byDay, bool hasLater) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
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
                      fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: () => _changeMonth(-1),
                icon: const Icon(Icons.chevron_left, color: _blue),
              ),
              // highlighted when a later month has appointments
              Container(
                decoration: BoxDecoration(
                  color: hasLater ? _blue : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () => _changeMonth(1),
                  icon: Icon(
                    Icons.chevron_right,
                    color: hasLater ? Colors.white : const Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              for (final w in _weekdays)
                Expanded(
                  child: Center(
                    child: Text(w,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF6B7280))),
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
    final lead = first.weekday % 7; // Sunday first

    final cells = <Widget>[
      for (var i = 0; i < lead; i++)
        const Expanded(child: SizedBox(height: 50)),
      for (var d = 1; d <= daysInMonth; d++)
        Expanded(
          child: _dayCell(DateTime(_month.year, _month.month, d), byDay),
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

  Widget _dayCell(DateTime d, Map<int, List<BookingItem>> byDay) {
    final count = byDay[_key(d)]?.length ?? 0;
    final selected = _same(d, _selected);
    final isToday = _same(d, _today());

    Color? bg;
    var fg = Colors.black;
    if (selected) {
      bg = _blue;
      fg = Colors.white;
    } else if (count > 0) {
      bg = const Color(0xFFFCE4E4);
    } else if (isToday) {
      bg = const Color(0xFFDBEAFE);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _selectDay(d),
      child: SizedBox(
        height: 50,
        child: Center(
          child: SizedBox(
            width: 42,
            height: 42,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
                ),
                Text(
                  '${d.day}',
                  style: TextStyle(
                    fontSize: 16,
                    color: fg,
                    fontWeight: (count > 0 || selected)
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                // how many appointments that day
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
                      child: Text('$count',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dayHeader(int count) {
    return Padding(
      key: count == 0 ? _targetKey : null,
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dateLong(_selected),
              style:
                  const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          Text(
            count == 0
                ? 'No appointments on this day.'
                : '$count appointment${count == 1 ? '' : 's'}',
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _timeline(List<BookingItem> day) {
    var startHour = 10;
    for (final b in day) {
      startHour = math.min(startHour, b.startMinutes ~/ 60);
    }
    final segments = 24 - startHour;
    final totalHeight = 12 + segments * _hourHeight + 24;

    return SizedBox(
      height: totalHeight,
      child: Stack(
        children: [
          for (var i = 0; i <= segments; i++) ...[
            Positioned(
              top: 12 + i * _hourHeight - 9,
              left: 0,
              width: _gutter - 8,
              child: Text(_hourLabel(startHour + i),
                  style: const TextStyle(
                      fontSize: 12.5, color: Color(0xFF6B7280))),
            ),
            Positioned(
              top: 12 + i * _hourHeight,
              left: _gutter,
              right: 0,
              child: Container(height: 1, color: const Color(0xFFE5E7EB)),
            ),
          ],
          for (var i = 0; i < day.length; i++)
            Positioned(
              top: 12 +
                  (day[i].startMinutes - startHour * 60) / 60 * _hourHeight,
              left: _gutter + 8,
              right: 0,
              height: math.max(30.0,
                  (day[i].endMinutes - day[i].startMinutes) / 60 * _hourHeight),
              child: _box(day[i], first: i == 0),
            ),
        ],
      ),
    );
  }

  Widget _box(BookingItem b, {required bool first}) {
    final h = (b.endMinutes - b.startMinutes) / 60 * _hourHeight;
    final compact = h < 58;
    final title = b.variantName == null
        ? b.serviceTitle
        : '${b.serviceTitle} • ${b.variantName}';
    final time = '${timeLabel(b.startMinutes)} - ${timeLabel(b.endMinutes)}';

    return GestureDetector(
      key: first ? _targetKey : null,
      onTap: () => showBookingDetail(
        context,
        booking: b,
        isBeautician: true,
        store: widget.store,
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFFDE8E8),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Container(width: 4, color: const Color(0xFF6AB0E4)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: compact
                    ? Row(
                        children: [
                          Expanded(
                            child: Text(title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 6),
                          Text(time, style: const TextStyle(fontSize: 11)),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(time,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(width: 4),
                              const Icon(Icons.info_outline,
                                  size: 14, color: Color(0xFF6B7280)),
                            ],
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
