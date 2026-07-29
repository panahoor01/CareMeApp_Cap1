import 'package:flutter/material.dart';
import 'package:flutter_application_practice/pages/detail_page.dart';

class Beautician {
  final String name;
  final String imageUrl;
  final String specialty;
  final String distance;
  final String rating;
  final String price;

  const Beautician({
    required this.name,
    required this.imageUrl,
    required this.specialty,
    required this.distance,
    required this.rating,
    required this.price,
  });
}

const sampleBeauticians = [
  Beautician(
    name: 'Aliza Watts',
    imageUrl: 'assets/man1.jpeg',
    specialty: 'Hair',
    distance: '2 km away',
    rating: '4.9',
    price: '₱1,500',
  ),
  Beautician(
    name: 'Adrian Mateo Cruz',
    imageUrl: 'assets/man2.jpeg',
    specialty: 'Lashes',
    distance: '3 km away',
    rating: '4.6',
    price: '₱2,500',
  ),
  Beautician(
    name: 'Lila Katherine Bennett',
    imageUrl: 'assets/man3.jpeg',
    specialty: 'Make Up',
    distance: '4 km away',
    rating: '5.0',
    price: '₱1,200',
  ),
];

class BeauticiansPage extends StatelessWidget {
  const BeauticiansPage({super.key});

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
                  const Icon(Icons.filter_list, color: Color(0xFF111827)),
                ],
              ),
              const SizedBox(height: 22),
              const Text(
                'Discover a beautician for your next service.',
                style: TextStyle(fontSize: 16, color: Color(0xFF4B5563)),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    icon: Icon(Icons.search, color: Color(0xFF9CA3AF)),
                    hintText: 'Search a service',
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _CategoryChip(title: 'All', active: true),
                    _CategoryChip(title: 'Hair'),
                    _CategoryChip(title: 'Nails'),
                    _CategoryChip(title: 'Make Up'),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: ListView.separated(
                  itemCount: sampleBeauticians.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final beautician = sampleBeauticians[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                            child: Image.asset(
                              beautician.imageUrl,
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        beautician.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE0F2FE),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        beautician.specialty,
                                        style: const TextStyle(
                                            color: Color(0xFF0369A1)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        size: 16, color: Color(0xFF22C55E)),
                                    const SizedBox(width: 4),
                                    Text(beautician.distance,
                                        style: const TextStyle(
                                            color: Color(0xFF22C55E))),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.star,
                                        size: 16, color: Color(0xFFF59E0B)),
                                    const SizedBox(width: 4),
                                    Text(beautician.rating,
                                        style: const TextStyle(
                                            color: Color(0xFF111827))),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Starting at ${beautician.price}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ItemDetailPage(
                                              title: beautician.name,
                                              subtitle: beautician.specialty,
                                              imageUrl: beautician.imageUrl,
                                              description:
                                                  'Discover ${beautician.name}, a ${beautician.specialty} specialist with top ratings and nearby availability.',
                                              price: beautician.price,
                                            ),
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFF0F9FF),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16)),
                                      ),
                                      child: const Text('Details',
                                          style: TextStyle(
                                              color: Color(0xFF0369A1))),
                                    ),
                                  ],
                                ),
                              ],
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

class _CategoryChip extends StatelessWidget {
  final String title;
  final bool active;

  const _CategoryChip({required this.title, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFDBEAFE) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: active ? const Color(0xFF93C5FD) : const Color(0xFFE5E7EB)),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: active ? const Color(0xFF1D4ED8) : const Color(0xFF6B7280),
          fontWeight: active ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }
}
