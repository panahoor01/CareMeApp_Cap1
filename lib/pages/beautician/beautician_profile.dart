import 'package:flutter/material.dart';
import 'package:flutter_application_practice/auth/auth_service.dart';
import 'package:flutter_application_practice/pages/edit_profile_page.dart';
import 'package:flutter_application_practice/profile/profile_editors.dart';
import 'package:flutter_application_practice/profile/profile_service.dart';
import 'package:flutter_application_practice/profile/profile_widgets.dart';
import 'package:flutter_application_practice/pages/beautician/services/services_tab.dart';

class BeauticianProfilePage extends StatefulWidget {
  const BeauticianProfilePage({super.key});

  @override
  State<BeauticianProfilePage> createState() => _BeauticianProfilePageState();
}

class _BeauticianProfilePageState extends State<BeauticianProfilePage> {
  final _service = ProfileService();
  ProfileData? _profile;
  String? _error;
  int _tab = 1; // 0 = Services, 1 = Details

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
      if (_profile == null)
        setState(() => _error = AuthService.friendlyError(e));
    }
  }

  Future<void> _openEditProfile(ProfileData p) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditProfilePage(profile: p)),
    );
    if (changed == true) _load();
  }

  Future<void> _openSheet(Widget sheet) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => sheet,
    );
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final p = _profile;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const ProfileHeaderBar(showActive: true),
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
                          value: '${p.servicesCount}', label: 'Services'),
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
          tabs: const ['Services', 'Details'],
          selected: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        const SizedBox(height: 16),
        if (_tab == 0) ServicesTab(onChanged: _load) else _details(p),
      ],
    );
  }

  Widget _details(ProfileData p) {
    final about = p.about ?? '';
    return Column(
      children: [
        ProfileCard(
          title: 'About',
          onMore: () => _openSheet(AboutEditorSheet(initial: about)),
          child: Text(
            about.isEmpty ? 'No description yet.' : about,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
        ),
        const SizedBox(height: 14),
        ProfileCard(
          title: 'Schedule',
          onMore: () => _openSheet(ScheduleEditorSheet(initial: p.schedule)),
          child: _ScheduleList(slots: p.schedule),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _ScheduleList extends StatefulWidget {
  final List<ScheduleSlot> slots;
  const _ScheduleList({required this.slots});

  @override
  State<_ScheduleList> createState() => _ScheduleListState();
}

class _ScheduleListState extends State<_ScheduleList> {
  static const _previewCount = 2;
  bool _expanded = false;

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
                _Pill(s.day),
                const SizedBox(width: 8),
                _Pill('${formatTime(s.start)} - ${formatTime(s.end)}'),
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

class _Pill extends StatelessWidget {
  final String text;
  const _Pill(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFCE4E4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: const TextStyle(fontSize: 15)),
    );
  }
}
