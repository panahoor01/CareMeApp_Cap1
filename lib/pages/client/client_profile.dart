import 'package:flutter/material.dart';
import 'package:flutter_application_practice/auth/auth_service.dart';
import 'package:flutter_application_practice/pages/bookings/bookings_panel.dart';
import 'package:flutter_application_practice/pages/bookings/booking_calendar_view.dart';
import 'package:flutter_application_practice/pages/bookings/bookings_repository.dart';
import 'package:flutter_application_practice/pages/edit_profile_page.dart';
import 'package:flutter_application_practice/profile/profile_service.dart';
import 'package:flutter_application_practice/profile/profile_widgets.dart';

class ClientProfilePage extends StatefulWidget {
  const ClientProfilePage({super.key});

  @override
  State<ClientProfilePage> createState() => _ClientProfilePageState();
}

class _ClientProfilePageState extends State<ClientProfilePage> {
  final _service = ProfileService();
  final _bookingsStore = BookingsStore();
  ProfileData? _profile;
  String? _error;
  int _tab = 1; // 0 = Calendar, 1 = Bookings

  @override
  void dispose() {
    _bookingsStore.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await _service.fetch();
      if (!mounted) return;
      setState(() {
        _profile = p;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (_profile == null) {
        setState(() => _error = AuthService.friendlyError(e));
      }
    }
  }

  Future<void> _refresh() async {
    await Future.wait([_load(), _bookingsStore.load()]);
  }

  Future<void> _openEditProfile(ProfileData p) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditProfilePage(profile: p)),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final p = _profile;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const ProfileHeaderBar(),
            Expanded(child: p == null ? _loadingOrError() : _content(p)),
          ],
        ),
      ),
    );
  }

  Widget _loadingOrError() {
    if (_error == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_error!),
          TextButton(
            onPressed: () {
              setState(() => _error = null);
              _load();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _content(ProfileData p) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SizedBox(height: 6),
          Row(
            children: [
              ProfileAvatar(initial: p.initial, imageUrl: p.profileImage),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            p.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.circle,
                            size: 6, color: Color(0xFF3B9AE1)),
                        const SizedBox(width: 3),
                        const Text('Client',
                            style: TextStyle(
                                fontSize: 11, color: Color(0xFF3B9AE1))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        ProfileStat(value: '0', label: 'Following'),
                        SizedBox(width: 28),
                        ProfileStat(value: '0', label: 'Completed Bookings'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (p.bio != null && p.bio!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(p.bio!, style: const TextStyle(fontSize: 14)),
            ),
          const SizedBox(height: 12),
          ProfileActionRow(
            onEdit: () => _openEditProfile(p),
            onMenu: () => showProfileMenu(context),
          ),
          const SizedBox(height: 8),
          ProfileTabSwitcher(
            tabs: const ['Calendar', 'Bookings'],
            selected: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          const SizedBox(height: 14),
          if (_tab == 0)
            BookingCalendarView(
              store: _bookingsStore,
              isBeautician: false,
              embedded: true,
            )
          else
            BookingsPanel(
              isBeautician: false,
              store: _bookingsStore,
              embedded: true,
            ),
        ],
      ),
    );
  }
}
