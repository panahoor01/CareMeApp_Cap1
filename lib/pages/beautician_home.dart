import 'package:flutter/material.dart';

class BeauticianHomePage extends StatefulWidget {
  const BeauticianHomePage({super.key});

  @override
  State<BeauticianHomePage> createState() => _BeauticianHomePageState();
}

class _BeauticianHomePageState extends State<BeauticianHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _prevMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = "${_monthName(_focusedDay.month)} ${_focusedDay.year}";

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Row(
                children: [
                  Image.asset('assets/logo2.png', width: 34, height: 34),
                  const SizedBox(width: 12),
                  const Text(
                    'CareMe',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  const Text(
                    'Active',
                    style: TextStyle(
                        color: Color(0xFF22C55E), fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.toggle_on,
                      color: Color(0xFF22C55E), size: 32),
                  const SizedBox(width: 12),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.chat_bubble_outline,
                        color: Colors.black87),
                  ),
                ],
              ),
            ),

            // Title and tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Calendar',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Colors.black,
                      indicatorColor: const Color(0xFF2B73E9),
                      unselectedLabelColor: const Color(0xFF6B7280),
                      tabs: const [
                        Tab(text: 'Calendar'),
                        Tab(text: 'Bookings'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Month picker + calendar / bookings view
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Calendar view
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: _prevMonth,
                              child: const Text('<'),
                            ),
                            Text(monthLabel,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            TextButton(
                              onPressed: _nextMonth,
                              child: const Text('>'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            children: [
                              // Simple calendar grid (weekdays + days)
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: _SimpleCalendar(focusedDay: _focusedDay),
                              ),

                              const Divider(height: 1),

                              // Day timeline
                              Expanded(
                                child: _DayTimeline(focusedDay: _focusedDay),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Bookings tab
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        _BookingsList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int m) {
    const names = [
      '',
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
      'December'
    ];
    return names[m];
  }
}

class _SimpleCalendar extends StatelessWidget {
  final DateTime focusedDay;
  const _SimpleCalendar({required this.focusedDay});

  List<Widget> _buildWeekDays() {
    const labels = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    return labels
        .map((l) => Expanded(
            child: Center(
                child:
                    Text(l, style: const TextStyle(color: Color(0xFF6B7280))))))
        .toList();
  }

  List<Widget> _buildDayCells() {
    final first = DateTime(focusedDay.year, focusedDay.month, 1);
    final daysInMonth = DateTime(focusedDay.year, focusedDay.month + 1, 0).day;
    final startWeekday = first.weekday % 7; // convert Mon-Sun to Sun=0

    final cells = <Widget>[];
    for (var i = 0; i < startWeekday; i++) {
      cells.add(Expanded(child: SizedBox()));
    }
    for (var d = 1; d <= daysInMonth; d++) {
      cells.add(Expanded(child: Center(child: Text('$d'))));
    }

    // fill to full weeks
    while (cells.length % 7 != 0) cells.add(Expanded(child: SizedBox()));

    // group into rows
    final rows = <Widget>[];
    for (var i = 0; i < cells.length; i += 7) {
      rows.add(Row(children: cells.sublist(i, i + 7)));
    }

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: _buildWeekDays()),
        const SizedBox(height: 8),
        ..._buildDayCells(),
      ],
    );
  }
}

class _DayTimeline extends StatelessWidget {
  final DateTime focusedDay;
  const _DayTimeline({required this.focusedDay});

  @override
  Widget build(BuildContext context) {
    // Simple labeled timeline from 10am to 1am like the design
    final hours = [
      '10 AM',
      '11 AM',
      '12 PM',
      '1 PM',
      '2 PM',
      '3 PM',
      '4 PM',
      '5 PM',
      '6 PM',
      '7 PM',
      '8 PM',
      '9 PM',
      '10 PM',
      '11 PM',
      '12 AM',
      '1 AM'
    ];

    return ListView.builder(
      itemCount: hours.length,
      itemBuilder: (context, index) {
        final hour = hours[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(hour,
                    style: const TextStyle(color: Color(0xFF6B7280))),
              ),
              Expanded(
                child: Container(
                  height: 60,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: index == 7
                        ? const Color(0xFFFDECF0)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: index == 7
                        ? Border.all(color: const Color(0xFFEF4444))
                        : null,
                  ),
                  child: index == 7
                      ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                              'Rebond • Rebond + Botox Treatment\n5:00 PM - 9:30 PM',
                              style: const TextStyle(color: Color(0xFF6B7280))),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BookingsList extends StatelessWidget {
  const _BookingsList();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView(
        children: [
          const SizedBox(height: 12),
          _BookingCard(
            title: 'Rebond',
            subtitle: 'Rebond + Botox Treatment',
            time: '6:25 PM',
            total: '₱1,650.00',
            statusColor: Color(0xFFFFEDD5),
          ),
          const SizedBox(height: 12),
          _BookingCard(
            title: 'Hair Color',
            subtitle: 'Ash Grey + Cellophane Treatment',
            time: '4:25 PM',
            total: '₱2,600.00',
            statusColor: Color(0xFFE6F8EF),
          ),
          const SizedBox(height: 12),
          _BookingCard(
            title: 'Pedicure',
            subtitle: 'Classic',
            time: '1:00 PM',
            total: '₱300.00',
            statusColor: Color(0xFFFFEBEB),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final String total;
  final Color statusColor;

  const _BookingCard({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.total,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.image, size: 36),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(time,
                        style: const TextStyle(color: Color(0xFF6B7280))),
                  ],
                ),
                const SizedBox(height: 8),
                Text(subtitle,
                    style: const TextStyle(color: Color(0xFF6B7280))),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total: $total',
                        style: const TextStyle(
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.bold)),
                    Text('x1',
                        style: const TextStyle(color: Color(0xFF6B7280))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
