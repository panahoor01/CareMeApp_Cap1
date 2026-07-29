import 'package:flutter/material.dart';
import 'package:flutter_application_practice/auth/auth_service.dart';
import 'package:flutter_application_practice/pages/edit_profile_page.dart';
import 'package:flutter_application_practice/screens/signup_screen/login_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isActive = true;

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Do you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await AuthService().signOut();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor =
        _isActive ? const Color(0xFF22C55E) : const Color(0xFF9CA3AF);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 23, vertical: 15),
                child: Row(
                  children: [
                    Image.asset('assets/careme_logo.png',
                        width: 34, height: 34),
                    const SizedBox(width: 11),
                    const Text(
                      'CareMe',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Row(
                      children: [
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
                              const SizedBox(width: 6),
                              Icon(
                                _isActive ? Icons.toggle_on : Icons.toggle_off,
                                color: activeColor,
                                size: 32,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: () => _confirmLogout(context),
                          icon: const Icon(
                            Icons.logout,
                            color: Color.fromARGB(255, 239, 68, 68),
                            size: 26,
                          ),
                          tooltip: 'Logout',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundImage: const AssetImage(
                            'assets/man6.jpeg',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Therry Mae',
                                style: TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 6),
                              Text('Client',
                                  style: TextStyle(color: Colors.blue)),
                            ],
                          ),
                        ),
                        // menu moved next to Edit Profile button
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Yahooow!',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: const [
                        _StatItem(value: '256', label: 'Following'),
                        _StatItem(value: '64', label: 'Completed Bookings'),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const EditProfilePage(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7BB8F0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Edit Profile',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.menu, color: Colors.black87),
                            onPressed: () => (context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const SizedBox(height: 22),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: const TabBar(
                        labelColor: Colors.black,
                        indicatorColor: Color(0xFF2B73E9),
                        unselectedLabelColor: Color(0xFF6B7280),
                        tabs: [
                          Tab(text: 'Posts'),
                          Tab(text: 'Calendar'),
                          Tab(text: 'Bookings'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 640,
                      child: const TabBarView(
                        children: [
                          _PostsTab(),
                          _CalendarTab(),
                          _BookingsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Color(0xFF6B7280))),
      ],
    );
  }
}

class _PostsTab extends StatelessWidget {
  const _PostsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const SizedBox(height: 8),
        _PostCard(
          title: 'Upgrade your look, upgrade your vibe.',
          imageUrl: 'assets/man5.jpeg',
          likes: '1.1K',
          comments: '250',
        ),
      ],
    );
  }
}

class _CalendarTab extends StatelessWidget {
  const _CalendarTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('March 2026',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Text('10 AM'),
              Text('11 AM'),
              Text('12 PM'),
              SizedBox(height: 12),
              Text('5:00 PM • Rebond + Botox Treatment',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}

class _BookingsTab extends StatelessWidget {
  const _BookingsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              _FilterPill(label: 'Requests', isActive: false),
              _FilterPill(label: 'Ongoing', isActive: true),
              _FilterPill(label: 'Upcoming', isActive: false),
              _FilterPill(label: 'Completed', isActive: false),
              _FilterPill(label: 'Cancelled', isActive: false),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: const [
              Icon(Icons.search, color: Color(0xFF9CA3AF)),
              SizedBox(width: 12),
              Expanded(
                child: Text('Search bookings',
                    style: TextStyle(color: Color(0xFF9CA3AF))),
              ),
            ],
          ),
        ),
        _BookingCard(
          title: 'Rebond',
          subtitle: 'Rebond + Botox Treatment',
          status: 'Ongoing',
          total: '₱1,650.00',
          name: 'Therry Mae',
        ),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool isActive;

  const _FilterPill({required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE0F2FE) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? const Color(0xFF0369A1) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? const Color(0xFF0369A1) : const Color(0xFF6B7280),
          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final String likes;
  final String comments;

  const _PostCard({
    required this.title,
    required this.imageUrl,
    required this.likes,
    required this.comments,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xFFE0F2FE),
                    child: Icon(Icons.person, color: Color(0xFF0369A1))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Dirik Ramsi',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 4),
                      Text('25min',
                          style: TextStyle(
                              color: Color(0xFF6B7280), fontSize: 13)),
                    ],
                  ),
                ),
                const Icon(Icons.more_vert, color: Color(0xFF9CA3AF)),
              ],
            ),
          ),
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(22)),
            child: Image.asset(imageUrl, height: 200, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(likes,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                Text('$comments comments',
                    style: const TextStyle(color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final String total;
  final String name;

  const _BookingCard({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.total,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: status == 'Ongoing'
                      ? const Color(0xFFFEE2E2)
                      : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: status == 'Ongoing'
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF0369A1),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(subtitle, style: const TextStyle(color: Color(0xFF4B5563))),
          const SizedBox(height: 12),
          Text('Client: $name',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Qty: 1', style: TextStyle(color: Color(0xFF6B7280))),
              Text('Total: $total',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
