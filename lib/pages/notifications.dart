import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset('assets/logo2.png', height: 30),
            ),
            const SizedBox(width: 15),
            const Text('CareMe', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      body: const Center(child: Text('Welcome to the Notifications Page!')),
    );
  }
}
