import 'package:flutter/material.dart';
import 'package:flutter_application_practice/pages/beautician_home.dart';
import 'package:flutter_application_practice/pages/feed.dart';
import 'package:flutter_application_practice/pages/beauticians.dart';
import 'package:flutter_application_practice/pages/notifications.dart';
import 'package:flutter_application_practice/pages/profle.dart';

class Homepage extends StatefulWidget {
  final String role;

  const Homepage({super.key, this.role = 'client'});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _selectedIndex = 0;

  List<Widget> get _pages {
    if (widget.role.toLowerCase() == 'beautician') {
      return const [
        UserHomePage(),
        BeauticianHomePage(),
        NotificationPage(),
        ProfilePage(),
      ];
    }

    return const [
      UserHomePage(),
      BeauticiansPage(),
      NotificationPage(),
      ProfilePage(),
    ];
  }

  List<BottomNavigationBarItem> get _navItems {
    if (widget.role.toLowerCase() == 'beautician') {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Feed'),
        BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today), label: 'Calendar'),
        BottomNavigationBarItem(
            icon: Icon(Icons.notifications), label: 'Notifications'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ];
    }

    return const [
      BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Feed'),
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
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTap,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2B73E9),
        unselectedItemColor: const Color(0xFF9CA3AF),
        showUnselectedLabels: true,
        items: _navItems,
      ),
    );
  }
}
