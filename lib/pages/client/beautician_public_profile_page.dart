import 'package:flutter/material.dart';
import 'package:flutter_application_practice/auth/auth_service.dart';
import 'package:flutter_application_practice/profile/profile_service.dart';
import 'package:flutter_application_practice/profile/profile_widgets.dart';
import 'package:flutter_application_practice/profile/public_profile_repository.dart';
import 'package:flutter_application_practice/pages/service_overview_page.dart';
import 'package:flutter_application_practice/pages/beautician/services/services_tab.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BeauticianPublicProfilePage extends StatefulWidget {
  final String beauticianId;
  const BeauticianPublicProfilePage({super.key, required this.beauticianId});

  @override
  State<BeauticianPublicProfilePage> createState() =>
      _BeauticianPublicProfilePageState();
}

class _BeauticianPublicProfilePageState
    extends State<BeauticianPublicProfilePage> {
  final _repo = PublicProfileRepository();
  PublicBeauticianProfile? _profile;
  String? _error;
  int _tab = 0; // 0 = Services, 1 = Details

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await _repo.fetch(widget.beauticianId);
      if (!mounted) return;
      setState(() {
        _profile = p;
        _error = null;
      });
    } catch (e) {
      debugPrint('load beautician profile failed: $e');
      if (!mounted || _profile != null) return;
      setState(() {
        _error =
            (e is PostgrestException && e.message == 'beautician_not_found')
                ? 'This beautician is no longer available.'
                : AuthService.friendlyError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _profile;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(child: p == null ? _loadingOrError() : _content(p)),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chevron_left_rounded, size: 30),
                  Text('Beauticians',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const Spacer(),
          Image.asset('assets/careme_logo.png', width: 36, height: 36),
        ],
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
          Text(_error!, textAlign: TextAlign.center),
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

  Widget _content(PublicBeauticianProfile p) {
    final bio = (p.bio ?? '').trim();
    return ListView(
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
                  Text(
                    p.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ProfileStat(
                          value: '${p.services.length}', label: 'Services'),
                      const ProfileStat(value: '0', label: 'Followers'),
                      ProfileStat(
                        value: p.rating == null
                            ? '0'
                            : '${p.rating!.toStringAsFixed(1)} (${p.ratingCount})',
                        label: 'Rating',
                        leading: const Icon(Icons.star,
                            size: 15, color: Color(0xFFF59E0B)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (bio.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(bio, style: const TextStyle(fontSize: 14)),
          ),
        const SizedBox(height: 14),
        ProfileTabSwitcher(
          tabs: const ['Services', 'Details'],
          selected: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        const SizedBox(height: 16),
        if (_tab == 0) _services(p) else _details(p),
      ],
    );
  }

  Widget _services(PublicBeauticianProfile p) {
    final categories = p.categories
        .where((c) => p.services.any((s) => s.categoryId == c.id))
        .toList();
    if (categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text("This beautician hasn't listed any services yet.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6B7280))),
        ),
      );
    }
    return ServicesTab.readOnly(
      categories: categories,
      services: p.services,
      onServiceTap: (category, service) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ServiceOverviewPage(
            category: category,
            service: service,
            beautician: p, // client mode: shows "Book now"
          ),
        ),
      ),
    );
  }

  Widget _details(PublicBeauticianProfile p) {
    final about = (p.about ?? '').trim();
    return Column(
      children: [
        ProfileCard(
          title: 'About',
          child: Text(
            about.isEmpty ? 'No description yet.' : about,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
        ),
        const SizedBox(height: 14),
        ProfileCard(
          title: 'Schedule',
          child: _ScheduleView(slots: p.schedule),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _ScheduleView extends StatefulWidget {
  final List<ScheduleSlot> slots;
  const _ScheduleView({required this.slots});

  @override
  State<_ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<_ScheduleView> {
  static const _previewCount = 2;
  bool _expanded = false;

  Widget _pill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFCE4E4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text, style: const TextStyle(fontSize: 15)),
      );

  @override
  Widget build(BuildContext context) {
    final slots = widget.slots;
    if (slots.isEmpty) {
      return const Text('No availability set yet.',
          style: TextStyle(color: Color(0xFF6B7280)));
    }
    final shown = _expanded ? slots : slots.take(_previewCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                _pill(s.day),
                const SizedBox(width: 8),
                _pill('${formatTime(s.start)} - ${formatTime(s.end)}'),
              ],
            ),
          ),
        if (slots.length > _previewCount)
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_expanded ? 'See less' : 'See more',
                        style: const TextStyle(fontSize: 15)),
                    Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.chevron_right,
                        size: 20),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
