import 'package:flutter/material.dart';
import 'package:flutter_application_practice/profile/profile_service.dart';
import 'package:flutter_application_practice/profile/profile_widgets.dart';
import 'package:flutter_application_practice/pages/beautician/services/service_form_page.dart';
import 'package:flutter_application_practice/pages/beautician/services/service_models.dart';
import 'package:flutter_application_practice/pages/beautician/services/service_repository.dart';
import 'package:flutter_application_practice/pages/bookings/booking_models.dart';
import 'package:flutter_application_practice/pages/client/booking/booking_page.dart';
import 'package:flutter_application_practice/profile/public_profile_repository.dart';

class ServiceOverviewPage extends StatefulWidget {
  final ServiceCategory category;
  final BeauticianService service;

  /// Set when a client is viewing a beautician's service (shows "Book now").
  /// Null means the beautician is viewing their own service ("Edit service").
  final PublicBeauticianProfile? beautician;

  const ServiceOverviewPage({
    super.key,
    required this.category,
    required this.service,
    this.beautician,
  });

  @override
  State<ServiceOverviewPage> createState() => _ServiceOverviewPageState();
}

class _ServiceOverviewPageState extends State<ServiceOverviewPage> {
  final _repo = ServiceRepository();
  final _pageController = PageController();
  late BeauticianService _service = widget.service;
  ProfileData? _owner; // beautician shown under the description
  List<ServiceReview> _reviews = const [];
  bool _reviewsLoading = false;
  String? _reviewsError;
  int _reviewsRequestId = 0;

  bool get _isClient => widget.beautician != null;

  @override
  void initState() {
    super.initState();
    if (!_isClient) _loadOwner(); // a client already has the beautician's info
  }

  Future<void> _loadOwner() async {
    try {
      final p = await ProfileService().fetch();
      if (!mounted) return;
      setState(() => _owner = p);
    } catch (e) {
      debugPrint('load beautician info failed: $e');
    }
  }

  void _changeTab(int index) {
    setState(() => _tab = index);
    if (index == 1) _loadReviews();
  }

  Future<void> _loadReviews() async {
    final requestId = ++_reviewsRequestId;
    setState(() {
      _reviewsLoading = true;
      _reviewsError = null;
    });
    try {
      final reviews = await _repo.fetchReviews(_service.id);
      if (!mounted || requestId != _reviewsRequestId) return;
      setState(() {
        _reviews = reviews;
        _reviewsLoading = false;
      });
    } catch (e) {
      debugPrint('load service reviews failed: $e');
      if (!mounted || requestId != _reviewsRequestId) return;
      setState(() {
        _reviewsLoading = false;
        _reviewsError = 'Could not load reviews. Please try again.';
      });
    }
  }

  int _page = 0;
  int _tab = 0; // 0 = Overview, 1 = Reviews

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _edit() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ServiceFormPage(category: widget.category, existing: _service),
      ),
    );
    if (changed != true || !mounted) return;

    try {
      final list = await _repo.fetchServices([widget.service.categoryId]);
      if (!mounted) return;
      final i = list.indexWhere((s) => s.id == _service.id);
      if (i == -1) {
        Navigator.pop(context); // the service was deleted
        return;
      }
      setState(() {
        _service = list[i];
        _page = 0;
      });
      if (_pageController.hasClients) _pageController.jumpToPage(0);
    } catch (e) {
      debugPrint('reload service failed: $e');
      if (mounted) Navigator.pop(context);
    }
  }

  void _showVariants() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Variants',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _service.variants.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                itemBuilder: (_, i) {
                  final v = _service.variants[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(v.name,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              v.addPrice > 0
                                  ? '+${formatPeso(v.addPrice)}'
                                  : 'No extra charge',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: v.addPrice > 0
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              v.extraMinutes > 0
                                  ? '+${formatDuration(v.extraMinutes)}'
                                  : 'No extra time',
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF6B7280)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _topBar(),
            _beauticianBar(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _gallery(),
                  ProfileTabSwitcher(
                    tabs: const ['Overview', 'Reviews'],
                    selected: _tab,
                    onChanged: _changeTab,
                  ),
                  if (_tab == 0) _overview() else _reviewsContent(),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              color: Colors.white,
              child: SafeArea(
                top: false,
                child: _isClient
                    ? _ActionButton(
                        icon: Icons.shopping_cart_outlined,
                        label: 'Book now',
                        onPressed: _book,
                      )
                    : _ActionButton(
                        icon: Icons.edit_outlined,
                        label: 'Edit service',
                        onPressed: _edit,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _book() {
    final b = widget.beautician;
    if (b == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingPage(beautician: b, service: _service),
      ),
    );
  }

  /// Compact "who is this beautician" bar, pinned above the photos.
  Widget _beauticianBar() {
    final String name;
    final String initial;
    final String? image;
    final double? rating;
    final int ratingCount;
    if (widget.beautician != null) {
      name = widget.beautician!.fullName;
      initial = widget.beautician!.initial;
      image = widget.beautician!.profileImage;
      rating = widget.beautician!.rating;
      ratingCount = widget.beautician!.ratingCount;
    } else if (_owner != null) {
      name = _owner!.fullName;
      initial = _owner!.initial;
      image = _owner!.profileImage;
      rating = _owner!.rating;
      ratingCount = _owner!.ratingCount;
    } else {
      return const SizedBox(height: 4); // still loading
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB)),
          bottom: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: BeauticianTopBar(
        name: name,
        initial: initial,
        imageUrl: image,
        rating: rating == null
            ? 'No ratings'
            : '${rating.toStringAsFixed(1)} ($ratingCount)',
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chevron_left_rounded, size: 30),
                  Text(
                    widget.category.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
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

  Widget _gallery() {
    final images = _service.images;

    if (images.isEmpty) {
      return AspectRatio(
        aspectRatio: 1,
        child: Container(
          color: const Color(0xFFF3F4F6),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.image_outlined, size: 48, color: Color(0xFF9CA3AF)),
                SizedBox(height: 8),
                Text('No photos yet',
                    style: TextStyle(color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => Image.network(
              images[i],
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : const Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFFF3F4F6),
                child: const Center(
                  child: Icon(Icons.broken_image_outlined,
                      size: 40, color: Color(0xFF9CA3AF)),
                ),
              ),
            ),
          ),
          if (images.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_page + 1} / ${images.length}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required Widget child,
    VoidCallback? onTap,
    bool top = true,
  }) {
    const line = BorderSide(color: Color(0xFFD1D5DB));
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            top: top ? line : BorderSide.none,
            bottom: line,
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _reviewsContent() {
    if (_reviewsLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_reviewsError != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Text(_reviewsError!, textAlign: TextAlign.center),
              TextButton(onPressed: _loadReviews, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_reviews.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text('No reviews for this service yet.',
              style: TextStyle(color: Color(0xFF6B7280))),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${_reviews.length} reviews',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (final review in _reviews)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 17,
                        backgroundImage: review.reviewerImage == null ||
                                review.reviewerImage!.isEmpty
                            ? null
                            : NetworkImage(review.reviewerImage!),
                        child: review.reviewerImage == null ||
                                review.reviewerImage!.isEmpty
                            ? Text(review.reviewerName.isEmpty
                                ? '?'
                                : review.reviewerName[0].toUpperCase())
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(review.reviewerName,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      Text(timeAgo(review.createdAt),
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF6B7280))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(
                      5,
                      (index) => Icon(
                        index < review.rating ? Icons.star : Icons.star_border,
                        size: 17,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                  if (review.review?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Text(review.review!, style: const TextStyle(height: 1.4)),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _overview() {
    final s = _service;
    final desc = (s.description ?? '').trim();
    final n = s.variants.length;
    final hasVariants = n > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatPeso(s.price),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFFEF4444),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  s.title,
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.bold, height: 1.15),
                ),
              ),
              if (_isClient)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Favorites are coming soon.')),
                  ),
                  icon: const Icon(Icons.favorite_border, size: 28),
                ),
            ],
          ),
          if (s.rating != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  const Icon(Icons.star, size: 17, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 4),
                  Text(
                    '${s.rating!.toStringAsFixed(1)} (${s.ratingCount ?? 0} reviews)',
                    style:
                        const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          if (!s.isActive)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Hidden from clients',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ),
            ),
          const SizedBox(height: 14),
          _infoRow(
            onTap: hasVariants ? _showVariants : null,
            child: Row(
              children: [
                const Icon(Icons.grid_view_rounded, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasVariants
                        ? '$n Variant${n == 1 ? '' : 's'}'
                        : 'No variants',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: hasVariants
                          ? const Color(0xFF6AB0E4)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ),
                if (hasVariants)
                  const Icon(Icons.chevron_right, color: Color(0xFF6B7280)),
              ],
            ),
          ),
          _infoRow(
            top: false,
            child: Row(
              children: [
                const Icon(Icons.schedule_outlined, size: 26),
                const SizedBox(width: 12),
                Text(
                  formatDurationRange(s.durationMinutes, s.maxDurationMinutes),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text('Description',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            desc.isEmpty ? 'No description yet.' : desc,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.5,
              color: desc.isEmpty ? const Color(0xFF6B7280) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class BeauticianTopBar extends StatelessWidget {
  final String name;
  final String initial;
  final String? imageUrl;
  final String followers; // display text
  final String rating; // display text

  const BeauticianTopBar({
    super.key,
    required this.name,
    required this.initial,
    this.imageUrl,
    this.followers = '0',
    this.rating = '0',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ProfileAvatar(initial: initial, imageUrl: imageUrl, size: 40),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(followers,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 3),
                      const Text('Followers', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star,
                          size: 14, color: Color(0xFF22C55E)),
                      const SizedBox(width: 3),
                      Text(rating,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB5E8FF), Color(0xFFFFD4C8)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onPressed,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: Colors.black),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
