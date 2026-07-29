import 'package:flutter/material.dart';
import 'package:flutter_application_practice/screens/signup_screen/signup_widget.dart';
import 'package:flutter_application_practice/screens/signup_screen/singup_complete_screen.dart';
import 'package:flutter_application_practice/screens/signup_screen/singup_theme.dart';

import '../../auth/user_model.dart';

const _specialtyOptions = [
  'Hair Stylist',
  'Makeup Artist',
  'Nail Technician',
  'Massage Therapist',
  'Esthetician',
  'Lash Technician',
];

const _serviceOptions = [
  'Hair',
  'Makeup',
  'Nails',
  'Massage',
  'Skin Care',
  'Lashes & Brows',
];

const _days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

class SpecialtyScreen extends StatefulWidget {
  final UserModel user;

  const SpecialtyScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<SpecialtyScreen> createState() => _SpecialtyScreenState();
}

class _SpecialtyScreenState extends State<SpecialtyScreen> {
  late List<String?> _specialties;
  late List<String?> _services;
  late List<AvailabilitySlot> _availability;

  @override
  void initState() {
    super.initState();
    _specialties = widget.user.specialties.isEmpty
        ? [_specialtyOptions.first]
        : List.of(widget.user.specialties);
    _services = widget.user.services.isEmpty
        ? [_serviceOptions.first]
        : List.of(widget.user.services);
    _availability = widget.user.availability.isEmpty
        ? [AvailabilitySlot()]
        : List.of(widget.user.availability);
  }

  Future<void> _pickTime(AvailabilitySlot slot, bool isFrom) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isFrom ? slot.from : slot.to,
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

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  void _continue() {
    widget.user.specialties = _specialties.whereType<String>().toSet().toList();
    widget.user.services = _services.whereType<String>().toSet().toList();
    widget.user.availability = _availability;

    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => SignupCompleteScreen(user: widget.user)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SignupStepScaffold(
      title: 'Beautician Sign up',
      heading: 'Enter your professional details.',
      subheading:
          'Build your professional profile and let clients discover your '
          'beauty services.',
      onContinue: _continue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('My specialty'),
          ..._specialties.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _Dropdown(
                    value: entry.value,
                    options: _specialtyOptions,
                    onChanged: (v) =>
                        setState(() => _specialties[entry.key] = v),
                  ),
                ),
              ),
          SignupAddButton(
            label: 'Add another specialty',
            onPressed: () =>
                setState(() => _specialties.add(_specialtyOptions.first)),
          ),
          const SizedBox(height: 22),
          const _SectionLabel('My service'),
          ..._services.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _Dropdown(
                    value: entry.value,
                    options: _serviceOptions,
                    onChanged: (v) => setState(() => _services[entry.key] = v),
                  ),
                ),
              ),
          SignupAddButton(
            label: 'Add another service',
            onPressed: () =>
                setState(() => _services.add(_serviceOptions.first)),
          ),
          const SizedBox(height: 22),
          const _SectionLabel('My availability schedule',
              suffix: ' (optional)'),
          ..._availability.map(
            (slot) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _Dropdown(
                      value: slot.day,
                      options: _days,
                      onChanged: (v) =>
                          setState(() => slot.day = v ?? slot.day),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: _TimeField(
                      label: _formatTime(slot.from),
                      onTap: () => _pickTime(slot, true),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text('to',
                        style: TextStyle(color: SignupTheme.textGrey)),
                  ),
                  Expanded(
                    flex: 4,
                    child: _TimeField(
                      label: _formatTime(slot.to),
                      onTap: () => _pickTime(slot, false),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SignupAddButton(
            label: 'Add another time',
            onPressed: () =>
                setState(() => _availability.add(AvailabilitySlot())),
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
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: SignupTheme.textDark,
          ),
          children: [
            TextSpan(
              text: suffix,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.normal,
                color: SignupTheme.textGrey,
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
      value: value,
      isExpanded: true,
      decoration: signupInputDecoration(''),
      icon: const Icon(Icons.keyboard_arrow_down, color: SignupTheme.textGrey),
      items: options
          .map((o) => DropdownMenuItem(value: o, child: Text(o)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TimeField({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: SignupTheme.fieldFill,
          borderRadius: BorderRadius.circular(SignupTheme.radius),
          border: Border.all(color: SignupTheme.fieldBorder),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: SignupTheme.textDark),
        ),
      ),
    );
  }
}
