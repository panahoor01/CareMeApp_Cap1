import 'package:flutter/material.dart';
import 'package:flutter_application_practice/screens/signup_screen/signup_widget.dart';
import 'package:flutter_application_practice/auth/auth_navigation.dart';
import 'package:flutter_application_practice/auth/auth_service.dart';
import 'package:flutter_application_practice/screens/signup_screen/singup_theme.dart';

import '../../auth/user_model.dart';

const _serviceCategories = [
  'Hair',
  'Nails',
  'Makeup',
  'Lashes & Brows',
  'Wax',
  'Footspa',
];

const _days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

class ProfessionalProfileScreen extends StatefulWidget {
  final UserModel user;

  const ProfessionalProfileScreen({Key? key, required this.user})
      : super(key: key);

  @override
  State<ProfessionalProfileScreen> createState() =>
      _ProfessionalProfileScreenState();
}

class _ProfessionalProfileScreenState extends State<ProfessionalProfileScreen> {
  late TextEditingController _aboutController;
  late List<String?> _services;
  late List<AvailabilitySlot> _availability;
  String? _defaultDay; // the day whose times get copied to newly added days
  String? _aboutError;
  bool _loading = false;
  final _auth = AuthService();
  final _aboutKey = GlobalKey();

  static const int _aboutMinLength = 20;

  @override
  void initState() {
    super.initState();
    _aboutController = TextEditingController(text: widget.user.about);
    _services = widget.user.services.isEmpty
        ? [_serviceCategories.first]
        : List.of(widget.user.services);
    _availability = widget.user.availability.isEmpty
        ? [AvailabilitySlot()]
        : List.of(widget.user.availability);
  }

  @override
  void dispose() {
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(AvailabilitySlot slot, bool isFrom) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isFrom ? slot.from : slot.to) ?? TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: SignupTheme.textDark,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          slot.from = picked;
        } else {
          slot.to = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay? t) {
    if (t == null) return '';
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  List<String> _availableCategories(String? current) {
    return _serviceCategories
        .where((c) => c == current || !_services.contains(c))
        .toList();
  }

  bool _isRangeInvalid(AvailabilitySlot slot) {
    final from = slot.from;
    final to = slot.to;
    if (from == null || to == null) return false;
    return to.hour * 60 + to.minute <= from.hour * 60 + from.minute;
  }

  // Unique days in the order they were added
  List<String> get _usedDays =>
      _availability.map((s) => s.day).whereType<String>().toSet().toList();

  // A day's dropdown offers its own day plus any day not used yet
  List<String> _availableDays(String current) =>
      _days.where((d) => d == current || !_usedDays.contains(d)).toList();

  void _changeDay(String from, String to) => setState(() {
        for (final s in _availability) {
          if (s.day == from) s.day = to;
        }
        if (_defaultDay == from) _defaultDay = to;
      });

  // Slots of a day that have both times filled and a valid range
  List<AvailabilitySlot> _completeSlots(String day) => _availability
      .where((s) =>
          s.day == day && s.from != null && s.to != null && !_isRangeInvalid(s))
      .toList();

  void _toggleDefault(String day) => setState(
        () => _defaultDay = _defaultDay == day ? null : day,
      );

  void _addDay() => setState(() {
        final next = _days.firstWhere((d) => !_usedDays.contains(d));

        // Copy the default day's times into the new day, if a default is set
        final source = _defaultDay == null
            ? <AvailabilitySlot>[]
            : _completeSlots(_defaultDay!);

        if (source.isEmpty) {
          _availability.add(AvailabilitySlot()..day = next);
        } else {
          _availability.addAll(
            source.map(
              (s) => AvailabilitySlot()
                ..day = next
                ..from = s.from
                ..to = s.to,
            ),
          );
        }
      }
    );

  void _addTime(String day) =>
      setState(() => _availability.add(AvailabilitySlot()..day = day));

  String? _validateAbout(String value) {
    final about = value.trim();
    if (about.isEmpty) return 'Please tell clients about yourself.';
    if (about.length < _aboutMinLength) {
      return 'Please write at least $_aboutMinLength characters.';
    }
    return null;
  }

  Future<void> _continue() async {
    final aboutError = _validateAbout(_aboutController.text);
    if (aboutError != null) {
      setState(() => _aboutError = aboutError);
      // The About field is at the top, so bring it into view
      final ctx = _aboutKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          alignment: 0.2,
        );
      }
      return;
    }

    if (_availability.any(_isRangeInvalid)) return;

    // A slot with only one time set can't be saved
    if (_availability.any((s) => (s.from == null) != (s.to == null))) {
      _snack('Please set both start and end time, or remove that slot.');
      return;
    }
    if (_hasOverlap()) {
      _snack('Time slots on the same day cannot overlap.');
      return;
    }

    widget.user.about = _aboutController.text.trim();
    widget.user.services = _services.whereType<String>().toSet().toList();
    // Empty placeholder slots ("or maybe later") are dropped
    widget.user.availability =
        _availability.where((s) => s.from != null && s.to != null).toList();

    await _submit();
  }

  int _mins(TimeOfDay t) => t.hour * 60 + t.minute;

  bool _hasOverlap() {
    for (final day in _usedDays) {
      final slots = _completeSlots(day)
        ..sort((a, b) => _mins(a.from!).compareTo(_mins(b.from!)));
      for (var i = 1; i < slots.length; i++) {
        if (_mins(slots[i].from!) < _mins(slots[i - 1].to!)) return true;
      }
    }
    return false;
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await _auth.signUpWithPhone(widget.user);
      widget.user.password = null;
      if (!mounted) return;
      goToProfileLandingPage(context, widget.user.role!);
    } catch (e) {
      if (mounted) _snack(AuthService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SignupStepScaffold(
      title: 'Beautician Sign up',
      heading: 'Your professional profile.',
      subheading:
          'Build your professional profile and let clients discover your '
          'beauty services.',
      onContinue: _continue,
      continueEnabled: !_loading,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('About'),
          TextFormField(
            key: _aboutKey,
            controller: _aboutController,
            onChanged: (_) {
              if (_aboutError != null) setState(() => _aboutError = null);
            },
            minLines: 3,
            maxLines: 5,
            maxLength: 1000,
            buildCounter: (context,
                    {required currentLength,
                    required isFocused,
                    required maxLength}) =>
                Text(
              '$currentLength / $maxLength',
              style: TextStyle(
                fontSize: 12,
                color: currentLength >= (maxLength ?? 1000)
                    ? Colors.red
                    : SignupTheme.textGrey,
              ),
            ),
            style: const TextStyle(fontSize: 13, color: SignupTheme.textDark),
            textAlignVertical: TextAlignVertical.top,
            decoration: signupInputDecoration('Tell clients about yourself...')
                .copyWith(
              errorText: _aboutError,
              errorMaxLines: 2,
            ),
          ),
          const _SectionLabel('My service'),
          ..._services.asMap().entries.map(
                (entry) => Padding(
                  key: ValueKey(entry.value),
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: _Dropdown(
                          value: entry.value,
                          options: _availableCategories(entry.value),
                          onChanged: (v) =>
                              setState(() => _services[entry.key] = v),
                        ),
                      ),
                      if (_services.length > 1) ...[
                        const SizedBox(width: 4),
                        _RemoveButton(
                          tooltip: 'Remove service',
                          onPressed: () =>
                              setState(() => _services.removeAt(entry.key)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          if (_services.length < _serviceCategories.length)
            SignupAddButton(
              label: 'Add another service',
              onPressed: () => setState(() {
                final next = _serviceCategories
                    .firstWhere((c) => !_services.contains(c));
                _services.add(next);
              }),
            ),
          const SizedBox(height: 22),
          const _SectionLabel('My availability schedule',
              suffix: ' (or maybe later)'),
                    ..._usedDays.map((day) {
            final slots = _availability.where((s) => s.day == day).toList();
            return Padding(
              key: ValueKey(day),
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(98, 255, 212, 200),
                  borderRadius: BorderRadius.circular(SignupTheme.radius + 4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _Dropdown(
                            value: day,
                            options: _availableDays(day),
                            onChanged: (v) {
                              if (v != null && v != day) _changeDay(day, v);
                            },
                          ),
                        ),
                        const SizedBox(width: 4),
                        _RemoveButton(
                          tooltip: 'Remove this day',
                          onPressed: () => setState(() {
                            _availability.removeWhere((s) => s.day == day);
                            if (_defaultDay == day) _defaultDay = null;
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...slots.map(
                      (slot) => Padding(
                        key: ObjectKey(slot),
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _TimeField(
                                    label: _formatTime(slot.from),
                                    hint: 'From',
                                    onTap: () => _pickTime(slot, true),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  child: Text('To'),
                                ),
                                Expanded(
                                  child: _TimeField(
                                    label: _formatTime(slot.to),
                                    hint: 'To',
                                    onTap: () => _pickTime(slot, false),
                                  ),
                                ),
                                if (slots.length > 1) ...[
                                  const SizedBox(width: 4),
                                  _RemoveButton(
                                    tooltip: 'Remove this time',
                                    onPressed: () => setState(
                                        () => _availability.remove(slot)),
                                  ),
                                ],
                              ],
                            ),
                            if (_isRangeInvalid(slot))
                              const Padding(
                                padding: EdgeInsets.only(top: 6, left: 4),
                                child: Text(
                                  'End time must be after start time.',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.red),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SignupAddButton(
                      label: 'Add another time',
                      onPressed: () => _addTime(day),
                    ),
                    const SizedBox(height: 4),
                    Builder(builder: (context) {
                      final isDefault = _defaultDay == day;
                      final canSet =
                          isDefault || _completeSlots(day).isNotEmpty;
                      return Align(
                        alignment: Alignment.center,
                        child: TextButton.icon(
                          onPressed: canSet ? () => _toggleDefault(day) : null,
                          icon: Icon(
                            isDefault
                                ? Icons.check_circle_rounded
                                : Icons.copy_all_rounded,
                            size: 20,
                          ),
                          label: Text(
                            isDefault
                                ? 'Default time (tap to undo)'
                                : 'Make this time as default',
                          ),
                          style: TextButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            minimumSize: Size.zero,
                            foregroundColor: SignupTheme.textDark,
                            disabledForegroundColor:
                                SignupTheme.textGrey.withValues(alpha: 0.6),
                            textStyle: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          }),
          if (_usedDays.length < _days.length)
            SignupAddButton(
              label: _availability.isEmpty
                  ? 'Add availability'
                  : 'Add another day',
              onPressed: _addDay,
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final String suffix;

  const _SectionLabel(this.text, {this.suffix = ''});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text.rich(
        TextSpan(
          text: text,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: SignupTheme.textDark,
          ),
          children: [
            TextSpan(
              text: suffix,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: Color.fromARGB(255, 40, 39, 39),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const _Dropdown({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      borderRadius: BorderRadius.circular(SignupTheme.radius),
      dropdownColor: const Color.fromARGB(255, 220, 247, 255),
      menuMaxHeight: 280,
      style: const TextStyle(fontSize: 18, color: SignupTheme.textDark),
      decoration: signupInputDecoration(''),
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: SignupTheme.textGrey),
      items: options
          .map((o) => DropdownMenuItem(value: o, child: Text(o)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final String hint;
  final VoidCallback onTap;

  const _TimeField({
    required this.label,
    required this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(SignupTheme.radius);
    final isEmpty = label.isEmpty;

    return Material(
      color: SignupTheme.fieldFill,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: const BorderSide(color: SignupTheme.fieldBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.access_time_rounded,
                  size: 18, color: SignupTheme.textGrey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isEmpty ? hint : label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: isEmpty
                        ? const Color.fromARGB(255, 84, 84, 84)
                        : SignupTheme.textDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String tooltip;

  const _RemoveButton({required this.onPressed, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.close_rounded,
          size: 20, color: SignupTheme.textGrey),
    );
  }
}
