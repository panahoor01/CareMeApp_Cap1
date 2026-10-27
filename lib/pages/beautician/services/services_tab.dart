import 'package:flutter/material.dart';
import 'package:flutter_application_practice/auth/auth_service.dart';
import 'package:flutter_application_practice/pages/beautician/services/service_form_page.dart';
import 'package:flutter_application_practice/pages/service_overview_page.dart';
import 'package:flutter_application_practice/pages/beautician/services/service_models.dart';
import 'package:flutter_application_practice/pages/beautician/services/service_repository.dart';

const _pink = Color(0xFFFCE4E4);

class ServicesTab extends StatefulWidget {
  final VoidCallback? onChanged; // called after add / edit / delete
  final List<ServiceCategory>? categories; // set = read-only (someone else's)
  final List<BeauticianService>? services;
  final void Function(ServiceCategory, BeauticianService)? onServiceTap;

  /// Your own services (editable).
  const ServicesTab({super.key, this.onChanged})
      : categories = null,
        services = null,
        onServiceTap = null;

  /// A beautician's services as seen by a client (no add / edit).
  const ServicesTab.readOnly({
    super.key,
    required this.categories,
    required this.services,
    this.onServiceTap,
  }) : onChanged = null;

  bool get readOnly => categories != null;

  @override
  State<ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<ServicesTab> {
  final _repo = ServiceRepository();
  List<ServiceCategory> _categories = [];
  List<BeauticianService> _services = [];
  int _selected = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.readOnly) {
      _categories = widget.categories!;
      _services = widget.services!;
      _loading = false;
    } else {
      _load();
    }
  }

  Future<void> _load({String? select}) async {
    try {
      final cats = await _repo.fetchCategories();
      final services =
          await _repo.fetchServices(cats.map((c) => c.id).toList());
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _services = services;
        if (select != null) {
          final i = cats.indexWhere((c) => c.name == select);
          if (i != -1) _selected = i;
        }
        if (_selected >= cats.length) _selected = 0;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      debugPrint('ServicesTab load failed: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AuthService.friendlyError(e);
      });
    }
  }

  Future<void> _openForm(ServiceCategory category,
      [BeauticianService? existing]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceFormPage(category: category, existing: existing),
      ),
    );
    if (changed == true) {
      _load();
      widget.onChanged?.call();
    }
  }

  Future<void> _openOverview(
      ServiceCategory category, BeauticianService service) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ServiceOverviewPage(category: category, service: service),
      ),
    );
    if (mounted) {
      _load(); // pick up edits or deletes made on the overview
      widget.onChanged?.call();
    }
  }

  Future<void> _addCategory() async {
    final owned = _categories.map((c) => c.name).toSet();
    final available = categoryOrder.where((c) => !owned.contains(c)).toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have already added every category.')),
      );
      return;
    }

    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text('Add a category',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            for (final name in available)
              ListTile(
                title: Text(name),
                trailing: const Icon(Icons.add_circle_outline),
                onTap: () => Navigator.pop(sheetContext, name),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked == null) return;

    try {
      await _repo.addCategory(picked);
      await _load(select: picked);
    } catch (e) {
      debugPrint('add category failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthService.friendlyError(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            children: [
              Text(_error!),
              TextButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _load();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text('No service categories yet.',
              style: TextStyle(color: Color(0xFF6B7280))),
        ),
      );
    }

    final category = _categories[_selected];
    final items = _services.where((s) => s.categoryId == category.id).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < _categories.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _CategoryChip(
                    label: _categories[i].name,
                    selected: i == _selected,
                    onTap: () => setState(() => _selected = i),
                  ),
                ),
              if (!widget.readOnly) _AddChip(onTap: _addCategory),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (!widget.readOnly)
          Material(
            color: _pink,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _openForm(category),
              child: SizedBox(
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                          color: Colors.black, shape: BoxShape.circle),
                      child:
                          const Icon(Icons.add, size: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    const Text('Add a service', style: TextStyle(fontSize: 17)),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 36),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.spa_outlined,
                      size: 44, color: Color(0xFF9CA3AF)),
                  const SizedBox(height: 10),
                  Text('No ${category.name} services yet',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  const Text('Tap "Add a service" to showcase your work.',
                      style: TextStyle(color: Color(0xFF6B7280))),
                ],
              ),
            ),
          )
        else
          for (final s in items)
            _ServiceCard(
              service: s,
              onTap: widget.readOnly
                  ? () => widget.onServiceTap?.call(category, s)
                  : () => _openOverview(category, s),
            ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: _pink,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Colors.black : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: selected ? FontWeight.bold : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _AddChip extends StatelessWidget {
  final VoidCallback onTap;
  const _AddChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(color: _pink, shape: BoxShape.circle),
        child: const Icon(Icons.add_circle, size: 24, color: Colors.black),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final BeauticianService service;
  final VoidCallback onTap;
  const _ServiceCard({required this.service, required this.onTap});

  Widget _cover() {
    final url = service.cover;
    Widget placeholder() => Container(
          color: const Color(0xFFF3F4F6),
          child: const Center(
            child:
                Icon(Icons.image_outlined, color: Color(0xFF9CA3AF), size: 32),
          ),
        );
    if (url == null) return placeholder();
    return Image.network(url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => placeholder());
  }

  @override
  Widget build(BuildContext context) {
    final rating = service.rating;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF6B7280)),
        ),
        child: InkWell(
          onTap: onTap,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 420;
              final imageWidth =
                  (constraints.maxWidth * 0.3).clamp(88.0, 116.0).toDouble();

              return SizedBox(
                height: compact ? 144 : 124,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: imageWidth, child: _cover()),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: compact ? 18 : 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 10,
                              runSpacing: 2,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (rating != null)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star,
                                          size: 14, color: Color(0xFFF59E0B)),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${rating.toStringAsFixed(1)}'
                                        '${service.ratingCount != null ? ' (${service.ratingCount})' : ''}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF4B5563)),
                                      ),
                                    ],
                                  ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.schedule,
                                        size: 14, color: Color(0xFF6B7280)),
                                    const SizedBox(width: 2),
                                    Text(
                                      formatDuration(service.durationMinutes),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF4B5563)),
                                    ),
                                  ],
                                ),
                                if (service.variants.isNotEmpty)
                                  Text(
                                    '${service.variants.length} variant'
                                    '${service.variants.length == 1 ? '' : 's'}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Color(0xFF4B5563)),
                                  ),
                              ],
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    formatPeso(service.price),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                if (!service.isActive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text('Hidden',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF6B7280))),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
