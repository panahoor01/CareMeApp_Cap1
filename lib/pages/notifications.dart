import 'package:flutter/material.dart';
import 'package:flutter_application_practice/pages/message_page.dart';

class NotificationItem {
  final String name;
  final String message;
  final String time;
  final bool isNew;

  const NotificationItem({
    required this.name,
    required this.message,
    required this.time,
    this.isNew = false,
  });
}

const sampleNotifications = [
  NotificationItem(
    name: 'Aliza Watts',
    message: 'started following you.',
    time: '2h',
    isNew: true,
  ),
  NotificationItem(
    name: 'Adrian Mateo Cruz',
    message: 'commented on your post.',
    time: '10h',
    isNew: true,
  ),
  NotificationItem(
    name: 'Lila Katherine Bennelen',
    message: 'loved your post.',
    time: '12h',
  ),
  NotificationItem(
    name: 'Rafael Tomas Dela Cruz',
    message: 'submitted a booking request.',
    time: '1w',
  ),
  NotificationItem(
    name: 'Rafael Tomas Dela Cruz',
    message: 'started following you.',
    time: '1w',
  ),
];

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 18),
              Row(
                children: [
                  Image.asset('assets/careme_logo.png', height: 34, width: 34),
                  const SizedBox(width: 12),
                  const Text(
                    'CareMe',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const MessagesPage(),
                        ),
                      );
                    },
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.black87,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Notifications',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Latest updates for your account and bookings.',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: sampleNotifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final notification = sampleNotifications[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: const Color(0xFFE0F2FE),
                            child: Text(notification.name[0]),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notification.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Text(notification.time,
                                        style: const TextStyle(
                                            color: Color(0xFF9CA3AF))),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  notification.message,
                                  style:
                                      const TextStyle(color: Color(0xFF4B5563)),
                                ),
                              ],
                            ),
                          ),
                          if (notification.isNew)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Text(
                                'New',
                                style: TextStyle(
                                    color: Color(0xFF22C55E),
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
