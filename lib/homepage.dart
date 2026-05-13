import 'package:flutter/material.dart';
import 'package:flutter_application_practice/pages/beauticians.dart';
import 'package:flutter_application_practice/pages/feed.dart';
import 'package:flutter_application_practice/pages/notifications.dart';
import 'package:flutter_application_practice/pages/profle.dart';

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _SelctedIndex = 0;
  void navigationBottomBar(int index) {
    setState(() {
      _SelctedIndex = index;
    });
  }

  final List<Widget> _pages = [
    UserHomePage(),
    BeauticiansPage(),
    NotificationPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_SelctedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _SelctedIndex,
        onTap: navigationBottomBar,
        backgroundColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Feed'),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Beauticians',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
