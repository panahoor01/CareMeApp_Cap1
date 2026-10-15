import 'package:flutter/material.dart';
import 'package:flutter_application_practice/pages/calendar_page.dart';
import 'package:flutter_application_practice/pages/client/nearby_beauticians_page.dart';
import 'package:flutter_application_practice/pages/notifications.dart';
import 'package:flutter_application_practice/pages/client/client_profile.dart';
import 'package:flutter_application_practice/pages/beautician/beautician_profile.dart';
import 'package:flutter_application_practice/realtime/app_badges.dart';

class MainNavBar extends StatefulWidget {
  final String role;
  final int initialIndex; // 2 = Profile tab

  const MainNavBar({super.key, this.role = 'client', this.initialIndex = 0});

  @override
  State<MainNavBar> createState() => _MainNavBarState();
}

class _MainNavBarState extends State<MainNavBar> {
  late int _selectedIndex = widget.initialIndex;

  bool get _isBeautician => widget.role.toLowerCase() == 'beautician';

  @override
  void initState() {
    super.initState();
    AppBadges.instance.start(); // live badges (notifications, new bookings)
  }

  List<int> _badges() {
    final b = AppBadges.instance;
    return [
      _isBeautician ? b.unseenBookings.value : 0,
      b.unreadNotifications.value,
      0,
    ];
  }

  List<Widget> get _pages {
    if (widget.role.toLowerCase() == 'beautician') {
      return const [
        CalendarPage(),
        NotificationPage(),
        BeauticianProfilePage(),
      ];
    }

    // The search page only exists while its tab is open, so every visit loads
    // the client's GPS and a fresh ranking (and no GPS is read at app start).
    return [
      _selectedIndex == 0
          ? const NearbyBeauticiansPage()
          : const SizedBox.shrink(),
      const NotificationPage(),
      const ClientProfilePage(),
    ];
  }

  List<BottomNavigationBarItem> get _navItems {
    if (widget.role.toLowerCase() == 'beautician') {
      return const [
        BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month), label: 'Calendar'),
        BottomNavigationBarItem(
            icon: Icon(Icons.notifications), label: 'Notifications'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ];
    }

    return const [
      BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Beauticians'),
      BottomNavigationBarItem(
          icon: Icon(Icons.notifications), label: 'Notifications'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    ];
  }

  void _onTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: ListenableBuilder(
        listenable: Listenable.merge([
          AppBadges.instance.unseenBookings,
          AppBadges.instance.unreadNotifications,
        ]),
        builder: (_, __) => _BottomNav(
          items: _navItems,
          index: _selectedIndex,
          onTap: _onTap,
          badges: _badges(),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final List<BottomNavigationBarItem> items;
  final int index;
  final ValueChanged<int> onTap;
  final List<int> badges; // red number on each tab (0 = none)

  const _BottomNav({
    required this.items,
    required this.index,
    required this.onTap,
    required this.badges,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => onTap(i),
                    child: Column(
                      children: [
                        Container(
                          height: 3,
                          color: i == index ? Colors.black : Colors.transparent,
                        ),
                        const Spacer(),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconTheme(
                              data: const IconThemeData(
                                  color: Colors.black, size: 28),
                              child: items[i].icon,
                            ),
                            if (badges[i] > 0)
                              Positioned(
                                right: -8,
                                top: -4,
                                child: Container(
                                  constraints: const BoxConstraints(
                                      minWidth: 16, minHeight: 16),
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEF4444),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10)),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    badges[i] > 99 ? '99+' : '${badges[i]}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          items[i].label ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black,
                            fontWeight:
                                i == index ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
