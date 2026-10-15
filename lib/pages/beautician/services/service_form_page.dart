import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_practice/auth/auth_service.dart';
import 'package:flutter_application_practice/screens/signup_screen/signup_widget.dart';
import 'package:flutter_application_practice/pages/beautician/services/service_models.dart';
import 'package:flutter_application_practice/pages/beautician/services/service_repository.dart';
import 'package:image_picker/image_picker.dart';

class _Img {
  final String? url; // already uploaded
  final Uint8List? bytes; // picked, uploaded on save
  final String type;
  const _Img.remote(this.url)
      : bytes = null,
        type = 'image/jpeg';
  const _Img.local(this.bytes, this.type) : url = null;
}

class _VariantRow {
  final int? id;
  final TextEditingController name;
  final TextEditingController price;
  int hours;
  int minutes;
  _VariantRow({
    this.id,
    String name = '',
    String price = '',
    this.hours = 0,
    this.minutes = 0,
  })  : name = TextEditingController(text: name),
        price = TextEditingController(text: price);

  void dispose() {
    name.dispose();
    price.dispose();
  }
}

class ServiceFormPage extends StatefulWidget {
  final ServiceCategory category;
  final BeauticianService? existing;
  const ServiceFormPage({super.key, required this.category, this.existing});

  @override
  State<ServiceFormPage> createState() => _ServiceFormPageState();
}

class _ServiceFormPageState extends State<ServiceFormPage> {
  static const _maxImages = 5;
  static const _maxPrice = 99999999.99;

  static final _moneyFormatter = TextInputFormatter.withFunction(
    (old, next) =>
        RegExp(r'^\d{0,8}(\.\d{0,2})?$').hasMatch(next.text) ? next : old,
  );

  final _repo = ServiceRepository();

  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  late final _description =
      TextEditingController(text: widget.existing?.description ?? '');
  late final _price = TextEditingController(
      text: widget.existing == null
          ? ''
          : widget.existing!.price.toStringAsFixed(2));
  late int _hours = (widget.existing?.durationMinutes ?? 60) ~/ 60;
  late int _minutes = (widget.existing?.durationMinutes ?? 60) % 60;
  late bool _isActive = widget.existing?.isActive ?? true;
  late final List<_Img> _images = (widget.existing?.images ?? <String>[])
      .map((u) => _Img.remote(u))
      .toList();
  late final List<_VariantRow> _variants =
      (widget.existing?.variants ?? <ServiceVariant>[])
          .map((v) => _VariantRow(
                id: v.id,
                name: v.name,
                price: v.addPrice == 0 ? '' : v.addPrice.toStringAsFixed(2),
                hours: v.extraMinutes ~/ 60,
                minutes: v.extraMinutes % 60,
              ))
          .toList();

  bool _saving = false;
  String? _titleError;
  String? _priceError;
  String? _durationError;
  String? _variantError;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    for (final v in _variants) {
      v.dispose();
    }
    super.dispose();
  }

  double? _parseMoney(String s) =>
      double.tryParse(s.trim().replaceAll(',', ''));

  Future<void> _pickImages() async {
    final remaining = _maxImages - _images.length;
    if (remaining <= 0) return;

    final picker = ImagePicker();
    final files = <XFile>[];
    if (remaining == 1) {
      final f = await picker.pickImage(
          source: ImageSource.gallery, maxWidth: 1200, imageQuality: 80);
      if (f != null) files.add(f);
    } else {
      files.addAll(await picker.pickMultiImage(
          maxWidth: 1200, imageQuality: 80, limit: remaining));
    }
    if (files.isEmpty) return;

    final added = <_Img>[];
    for (final f in files.take(remaining)) {
      added.add(_Img.local(await f.readAsBytes(), f.mimeType ?? 'image/jpeg'));
    }
    if (!mounted) return;
    setState(() => _images.addAll(added));
  }

  bool _validate() {
    String? titleError;
    String? priceError;
    String? durationError;
    String? variantError;

    final title = _title.text.trim();
    if (title.isEmpty) {
      titleError = 'Please enter a service title.';
    } else if (title.length > 100) {
      titleError = 'Maximum of 100 characters.';
    }

    final price = _parseMoney(_price.text);
    if (price == null) {
      priceError = 'Please enter a valid price.';
    } else if (price > _maxPrice) {
      priceError = 'Price is too high.';
    }

    final total = _hours * 60 + _minutes;
    if (total <= 0) {
      durationError = 'Please set how long this service takes.';
    } else if (total > 1440) {
      durationError = 'Maximum duration is 24 hours.';
    }

    final seen = <String>{};
    for (final v in _variants) {
      final name = v.name.text.trim();
      if (name.isEmpty) {
        variantError = 'Please name every variant or remove the empty ones.';
        break;
      }
      if (!seen.add(name.toLowerCase())) {
        variantError = 'Variant names must be different from each other.';
        break;
      }
      final raw = v.price.text.trim();
      if (raw.isNotEmpty && _parseMoney(raw) == null) {
        variantError = 'Check the extra price of "$name".';
        break;
      }
      if (v.hours * 60 + v.minutes > 1440) {
        variantError = 'The extra time of "$name" is too long (max 24 hours).';
        break;
      }
    }

    setState(() {
      _titleError = titleError;
      _priceError = priceError;
      _durationError = durationError;
      _variantError = variantError;
    });
    return titleError == null &&
        priceError == null &&
        durationError == null &&
        variantError == null;
  }

  Future<void> _save() async {
    if (!_validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the highlighted fields.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final urls = <String>[];
      for (var i = 0; i < _images.length; i++) {
        final img = _images[i];
        urls.add(img.url ?? await _repo.uploadImage(img.bytes!, img.type, i));
      }

      await _repo.saveService(
        serviceId: widget.existing?.id,
        categoryId: widget.category.id,
        title: _title.text.trim(),
        description: _description.text.trim(),
        images: urls,
        price: _parseMoney(_price.text)!,
        durationMinutes: _hours * 60 + _minutes,
        isActive: _isActive,
        variants: _variants
            .map((v) => ServiceVariant(
                  id: v.id,
                  name: v.name.text.trim(),
                  addPrice: _parseMoney(v.price.text) ?? 0,
                  extraMinutes: v.hours * 60 + v.minutes,
                ))
            .toList(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('save service failed: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthService.friendlyError(e))),
      );
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete service'),
        content: Text(
            'Delete "${widget.existing!.title}" and its variants? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete',
                style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _saving = true);
    try {
      await _repo.deleteService(widget.existing!.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('delete service failed: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthService.friendlyError(e))),
      );
    }
  }

  Widget _label(String text, {String suffix = ''}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text.rich(
          TextSpan(
            text: text,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            children: [
              TextSpan(
                text: suffix,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      );

  Widget _durationDropdown(
      String label, int value, int count, ValueChanged<int> onChanged) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      menuMaxHeight: 280,
      decoration: signupInputDecoration(label),
      items: List.generate(
        count,
        (i) => DropdownMenuItem(value: i, child: Text('$i')),
      ),
      onChanged: (v) {
        if (v == null) return;
        setState(() {
          onChanged(v);
          _durationError = null;
        });
      },
    );
  }

  Widget _variantCard(_VariantRow v) {
    void clearError() {
      if (_variantError != null) setState(() => _variantError = null);
    }

    return Container(
      key: ObjectKey(v),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF6B7280)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: v.name,
                  maxLength: 50,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => clearError(),
                  decoration: signupInputDecoration('Variant name')
                      .copyWith(counterText: ''),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() {
                  _variants.remove(v);
                  v.dispose();
                  _variantError = null;
                }),
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextField(
              controller: v.price,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [_moneyFormatter],
              onChanged: (_) => clearError(),
              decoration: signupInputDecoration('Extra price (optional)')
                  .copyWith(prefixText: '₱ ', hintText: '0.00'),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 12, bottom: 6),
            child: Text('Extra time (optional)',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Expanded(
                  child: _durationDropdown(
                      'Hours', v.hours, 25, (x) => v.hours = x),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _durationDropdown(
                      'Minutes', v.minutes, 60, (x) => v.minutes = x),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return SignupStepScaffold(
      title: isEdit ? 'Edit service' : 'Add a service',
      heading: isEdit
          ? 'Edit your service.'
          : 'New ${widget.category.name} service.',
      subheading:
          'Add photos, pricing, and any variants clients can choose from.',
      continueLabel: _saving ? 'Saving...' : 'Save service',
      continueEnabled: !_saving,
      onContinue: _save,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Photos ───────────────────────────────────────────────
          _label('Photos', suffix: '  (up to $_maxImages)'),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _images.length + (_images.length < _maxImages ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                if (i == _images.length) {
                  return _AddPhotoTile(
                    count: _images.length,
                    max: _maxImages,
                    onTap: _pickImages,
                  );
                }
                return _PhotoThumb(
                  image: _images[i],
                  isCover: i == 0,
                  onRemove: () => setState(() => _images.removeAt(i)),
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('The first photo is shown as the cover.',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          ),
          const SizedBox(height: 20),

          // ── Basics ───────────────────────────────────────────────
          TextField(
            controller: _title,
            maxLength: 100,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) {
              if (_titleError != null) setState(() => _titleError = null);
            },
            decoration: signupInputDecoration('Service title')
                .copyWith(errorText: _titleError),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _description,
            maxLength: 1000,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: signupInputDecoration('Description (optional)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [_moneyFormatter],
            onChanged: (_) {
              if (_priceError != null) setState(() => _priceError = null);
            },
            decoration: signupInputDecoration('Price').copyWith(
              prefixText: '₱ ',
              errorText: _priceError,
            ),
          ),
          const SizedBox(height: 20),

          // ── Duration ─────────────────────────────────────────────
          _label('Duration'),
          Row(
            children: [
              Expanded(
                child:
                    _durationDropdown('Hours', _hours, 25, (v) => _hours = v),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _durationDropdown(
                    'Minutes', _minutes, 60, (v) => _minutes = v),
              ),
            ],
          ),
          if (_durationError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(_durationError!,
                  style: const TextStyle(fontSize: 12, color: Colors.red)),
            ),
          const SizedBox(height: 24),

          // ── Variants ─────────────────────────────────────────────
          _label('Variants', suffix: '  (optional)'),
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Options clients can pick, like Blonde, Red or Black. '
              'Add an extra price if a variant costs more.',
              style: TextStyle(
                  fontSize: 13, color: Color(0xFF6B7280), height: 1.4),
            ),
          ),
          for (final v in _variants) _variantCard(v),
          if (_variantError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10, left: 4),
              child: Text(_variantError!,
                  style: const TextStyle(fontSize: 12, color: Colors.red)),
            ),
          SignupAddButton(
            label: 'Add variant',
            onPressed: () => setState(() => _variants.add(_VariantRow())),
          ),
          const SizedBox(height: 16),

          // ── Visibility ───────────────────────────────────────────
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            title: const Text('Visible to clients'),
            subtitle: const Text(
                'Turn off to hide this service without deleting it.'),
          ),

          if (isEdit) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: _saving ? null : _delete,
                icon:
                    const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                label: const Text('Delete service',
                    style: TextStyle(color: Color(0xFFEF4444))),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  final int count;
  final int max;
  final VoidCallback onTap;
  const _AddPhotoTile(
      {required this.count, required this.max, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_photo_alternate_outlined, size: 28),
            const SizedBox(height: 4),
            Text('$count/$max', style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  final _Img image;
  final bool isCover;
  final VoidCallback onRemove;
  const _PhotoThumb(
      {required this.image, required this.isCover, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final Widget pic = image.bytes != null
        ? Image.memory(image.bytes!, fit: BoxFit.cover)
        : Image.network(
            image.url!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFFF3F4F6),
              child: const Icon(Icons.broken_image_outlined),
            ),
          );

    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(14), child: pic),
          if (isCover)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 2),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(14)),
                ),
                child: const Text('Cover',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                    color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
