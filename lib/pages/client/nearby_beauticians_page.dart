import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_practice/auth/auth_service.dart';
import 'package:flutter_application_practice/location/location_service.dart';
import 'package:flutter_application_practice/location/nearby_beauticians_repository.dart';
import 'package:flutter_application_practice/pages/client/beautician_public_profile_page.dart';
import 'package:flutter_application_practice/pages/beautician/services/service_models.dart';

class NearbyBeauticiansPage extends StatefulWidget {
  const NearbyBeauticiansPage({super.key});

  @override
  State<NearbyBeauticiansPage> createState() => _NearbyBeauticiansPageState();
}

class _NearbyBeauticiansPageState extends State<NearbyBeauticiansPage> {
  final _repo = NearbyBeauticiansRepository();
  final _searchController = TextEditingController();
  Timer? _debounce;
  int _requestId = 0; // ignore answers that arrive after a newer request

  // GPS is read when the page opens and on pull-to-refresh only;
  // searching and changing category reuse it.
  double? _lat;
  double? _lng;
  String _category = 'All';

  List<NearbyBeautician> _items = [];
  bool _loading = true; // first load: full-page spinner
  bool _busy = false; // later searches: thin progress bar
  LocationProblem? _locationProblem;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh(); // opening the page = fresh GPS + fresh ranking
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  bool get _filtering =>
      _searchController.text.trim().isNotEmpty || _category != 'All';

  Future<void> _refresh({bool newGps = true}) async {
    final id = ++_requestId;
    if (!_loading) setState(() => _busy = true);

    try {
      if (newGps || _lat == null || _lng == null) {
        final pos = await LocationService.currentPosition();
        _lat = pos.latitude;
        _lng = pos.longitude;
      }
      final items = await _repo.search(
        _lat!,
        _lng!,
        query: _searchController.text,
        category: _category == 'All' ? null : _category,
      );
      if (!mounted || id != _requestId) return;
      setState(() {
        _items = items;
        _loading = false;
        _busy = false;
        _locationProblem = null;
        _error = null;
      });
    } on LocationProblem catch (e) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _items = [];
        _loading = false;
        _busy = false;
        _locationProblem = e;
      });
    } catch (e) {
      debugPrint('nearby search failed: $e');
      if (!mounted || id != _requestId) return;
      final message = AuthService.friendlyError(e);
      if (_items.isNotEmpty) {
        setState(() {
          _loading = false;
          _busy = false;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      } else {
        setState(() {
          _loading = false;
          _busy = false;
          _error = message;
        });
      }
    }
  }

  void _retry() {
    setState(() {
      _loading = true;
      _locationProblem = null;
      _error = null;
    });
    _refresh();
  }

  void _onSearchChanged(String _) {
    setState(() {}); // shows or hides the clear button
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 450),
      () => _refresh(newGps: false),
    );
  }

  void _searchNow() {
    _debounce?.cancel();
    _refresh(newGps: false);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {});
    _searchNow();
  }

  void _pickCategory(String category) {
    if (category == _category) return;
    setState(() => _category = category);
    _refresh(newGps: false);
  }

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
                  /*const Icon(Icons.filter_list,
                      color: Color(0xFF111827), size: 28),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MessagesPage()),
                    ),
                    child: const SizedBox(
                      width: 42,
                      height: 42,
                      child: Icon(Icons.chat_bubble_outline,
                          color: Colors.black87, size: 28),
                    ),
                  ),*/
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Discover a beautician for your next service.',
                style: TextStyle(fontSize: 16, color: Color(0xFF4B5563)),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onChanged: _onSearchChanged,
                  onSubmitted: (_) => _searchNow(),
                  decoration: InputDecoration(
                    icon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
                    hintText: 'Search a service',
                    border: InputBorder.none,
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: _clearSearch,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _CategoryDropdown(selected: _category, onSelected: _pickCategory),
              const SizedBox(height: 10),
              if (_busy)
                const LinearProgressIndicator(minHeight: 2)
              else
                const SizedBox(height: 2),
              const SizedBox(height: 10),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh, // pull down = fresh GPS + fresh ranking
                  child: _body(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    const physics = AlwaysScrollableScrollPhysics();

    if (_loading) {
      return ListView(
        physics: physics,
        children: const [
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }
    if (_locationProblem != null) {
      final p = _locationProblem!;
      return _message(
        icon: Icons.location_off_outlined,
        text: p.message,
        actions: [
          TextButton(onPressed: _retry, child: const Text('Try again')),
          if (p.canOpenSettings)
            const TextButton(
              onPressed: LocationService.openSettings,
              child: Text('Open settings'),
            ),
        ],
      );
    }
    if (_error != null && _items.isEmpty) {
      return _message(
        icon: Icons.cloud_off_outlined,
        text: _error!,
        actions: [TextButton(onPressed: _retry, child: const Text('Retry'))],
      );
    }
    if (_items.isEmpty) {
      return _message(
        icon: Icons.spa_outlined,
        text: _filtering
            ? 'No beauticians match your search.\nTry another service or category.'
            : 'No beauticians are available near you right now.\nPull down to refresh.',
        actions: const [],
      );
    }

    return ListView.separated(
      physics: physics,
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, i) => _BeauticianCard(b: _items[i]),
    );
  }

  Widget _message({
    required IconData icon,
    required String text,
    required List<Widget> actions,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 70, 16, 0),
      children: [
        Icon(icon, size: 48, color: const Color(0xFF9CA3AF)),
        const SizedBox(height: 12),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF6B7280), height: 1.4),
        ),
        if (actions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: actions,
            ),
          ),
      ],
    );
  }
}

class _BeauticianCard extends StatelessWidget {
  final NearbyBeautician b;
  const _BeauticianCard({required this.b});

  Widget _photo() {
    final url = b.profileImage;
    final fallback = Container(
      color: const Color(0xFF7BB8F0),
      alignment: Alignment.center,
      child: Text(
        b.initial,
        style: const TextStyle(
            fontSize: 50, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    );
    if (url == null || url.isEmpty) return fallback;
    return Image.network(url,
        fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback);
  }

  @override
  Widget build(BuildContext context) {
    final bio = (b.bio ?? '').trim();

    // Fixed height: the services row scrolls sideways, and a scrollable
    // can't be measured by IntrinsicHeight.
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color.fromARGB(255, 51, 51, 51),
          width: 0.8, // Slightly thicker so the bottom is visible
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 118,
              child: _photo(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    if (bio.isNotEmpty)
                      Text(
                        bio,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13.5, color: Color(0xFF4B5563)),
                      ),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 16, color: Color(0xFF22C55E)),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            b.distanceLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF22C55E),
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // shown only once the beautician has ratings
                    if (b.rating != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.star,
                                size: 16, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 2),
                            Text(
                              '${b.rating!.toStringAsFixed(1)}'
                              '${b.ratingCount != null ? ' (${compactCount(b.ratingCount!)})' : ''}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    const Text('Services:', style: TextStyle(fontSize: 13)),
                    Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (final c in b.categories)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: _ServiceChip(
                                        name: c, rating: b.categoryRatings[c]),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  BeauticianPublicProfilePage(beauticianId: b.id),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6AB0E4),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Details',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 14)),
                                Icon(Icons.chevron_right,
                                    size: 22, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      )
    );
  }
}

class _ServiceChip extends StatelessWidget {
  final String name;
  final double? rating; // hidden until the category has ratings
  const _ServiceChip({required this.name, this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE7E7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFAD0D0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name,
              maxLines: 1,
              softWrap: false,
              style: const TextStyle(fontSize: 13)),
          if (rating != null) ...[
            const SizedBox(width: 4),
            const Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
            const SizedBox(width: 2),
            Text(rating!.toStringAsFixed(1),
                style: const TextStyle(fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

/// One button that opens a drop-down with every category.
class _CategoryDropdown extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _CategoryDropdown({required this.selected, required this.onSelected});

  static const _options = ['All', ...categoryOrder];

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1D4ED8);

    return PopupMenuButton<String>(
      onSelected: onSelected,
      offset: const Offset(0, 52),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (_) => [
        for (final o in _options)
          PopupMenuItem<String>(
            value: o,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  o == 'All' ? 'All' : o,
                  style: TextStyle(
                    fontWeight:
                        o == selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (o == selected) ...[
                  const SizedBox(width: 5),
                  const Icon(Icons.check, size: 18, color: blue),
                ],
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFDBEAFE),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF93C5FD)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(selected,
                style:
                    const TextStyle(color: blue, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, color: blue),
          ],
        ),
      ),
    );
  }
}
