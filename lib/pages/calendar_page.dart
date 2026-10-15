import 'package:flutter/material.dart';
import 'package:flutter_application_practice/location/active_toggle.dart';
import 'package:flutter_application_practice/pages/bookings/booking_calendar_view.dart';
import 'package:flutter_application_practice/pages/bookings/bookings_panel.dart';
import 'package:flutter_application_practice/pages/bookings/bookings_repository.dart';
import 'package:flutter_application_practice/realtime/app_badges.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final _store =
      BookingsStore(); // shared by the calendar and the bookings list
  int _tab = 0; // 0 = Calendar, 1 = Bookings

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  Widget _tabButton(int index, String label, {bool dot = false}) {
    final selected = _tab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tab = index),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 6),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  // new bookings not seen yet
                  if (dot)
                    Positioned(
                      right: -10,
                      top: -2,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              height: 3,
              color: selected ? Colors.black : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Row(
                children: [
                  Image.asset('assets/careme_logo.png', width: 34, height: 34),
                  const SizedBox(width: 12),
                  const Text(
                    'CareMe',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  const ActiveToggle(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Calendar',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<int>(
                    valueListenable: AppBadges.instance.unseenBookings,
                    builder: (_, unseen, __) => Stack(
                      children: [
                        const Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Divider(
                              height: 1, thickness: 1, color: Colors.black),
                        ),
                        Row(
                          children: [
                            _tabButton(0, 'Calendar'),
                            _tabButton(1, 'Bookings', dot: unseen > 0),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: [
                  BookingCalendarView(store: _store, isBeautician: true),
                  BookingsPanel(isBeautician: true, store: _store),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
