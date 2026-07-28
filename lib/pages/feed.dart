import 'package:flutter/material.dart';
import 'package:flutter_application_practice/pages/detail_page.dart';

class FeedItem {
  final String name;
  final String title;
  final String distance;
  final String rating;
  final String reviewCount;
  final List<String> services;
  final String imageUrl;

  const FeedItem({
    required this.name,
    required this.title,
    required this.distance,
    required this.rating,
    required this.reviewCount,
    required this.services,
    required this.imageUrl,
  });
}

const sampleFeed = [
  FeedItem(
    name: 'Aliza Watts',
    title: 'Professional Beautician ALL IN',
    distance: '2 km away',
    rating: '4.8',
    reviewCount: '1.2k',
    services: ['Hair', 'Nails'],
    imageUrl:
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=400&q=80',
  ),
  FeedItem(
    name: 'Adrian Mateo Cruz',
    title: 'Professional Beautician ALL IN',
    distance: '3 km away',
    rating: '4.5',
    reviewCount: '510',
    services: ['Lashes', 'Hair'],
    imageUrl:
        'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=400&q=80',
  ),
  FeedItem(
    name: 'Lila Katherine Bennett',
    title: 'Professional Beautician ALL IN',
    distance: '4 km away',
    rating: '5.0',
    reviewCount: '3',
    services: ['Make Up'],
    imageUrl:
        'https://images.unsplash.com/photo-1544723795-3fb6469f5b39?auto=format&fit=crop&w=400&q=80',
  ),
  FeedItem(
    name: 'Rafael Tomas Dela Cruz',
    title: 'Professional Beautician ALL IN',
    distance: '5 km away',
    rating: '4.7',
    reviewCount: '120',
    services: ['Wax', 'Spa'],
    imageUrl:
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=400&q=80',
  ),
];

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  bool _isActive = true;

  @override
  Widget build(BuildContext context) {
    final activeColor =
        _isActive ? const Color(0xFF22C55E) : const Color(0xFF9CA3AF);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Row(
                children: [
                  Image.asset('assets/logo2.png', height: 34, width: 34),
                  const SizedBox(width: 12),
                  const Text(
                    'CareMe',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isActive = !_isActive;
                      });
                    },
                    child: Row(
                      children: [
                        Text(
                          _isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: activeColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _isActive ? Icons.toggle_on : Icons.toggle_off,
                          color: activeColor,
                          size: 32,
                        ),
                      ],
                    ),
                  ),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'All',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        icon: Icon(Icons.search, color: Color(0xFF9CA3AF)),
                        hintText: 'Search a service',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: sampleFeed.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final item = sampleFeed[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 34,
                              backgroundImage: NetworkImage(item.imageUrl),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(item.title,
                                      style: const TextStyle(
                                          color: Color(0xFF6B7280))),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on,
                                          size: 16, color: Color(0xFF22C55E)),
                                      const SizedBox(width: 4),
                                      Text(item.distance,
                                          style: const TextStyle(
                                              color: Color(0xFF22C55E))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: item.services
                              .map(
                                (service) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    service,
                                    style: const TextStyle(
                                        color: Color(0xFF4338CA)),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    size: 18, color: Color(0xFFF59E0B)),
                                const SizedBox(width: 6),
                                Text('${item.rating} (${item.reviewCount})',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ItemDetailPage(
                                      title: item.name,
                                      subtitle: item.title,
                                      imageUrl: item.imageUrl,
                                      description:
                                          'A professional beautician offering quality services near you. Book now or view more details.',
                                      price: 'Starting at ₱1,500',
                                    ),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: const Color(0xFFDBEAFE),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18)),
                              ),
                              child: const Text('Details',
                                  style: TextStyle(color: Color(0xFF1D4ED8))),
                            ),
                          ],
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
    );
  }
}
