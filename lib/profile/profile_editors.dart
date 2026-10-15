import 'package:flutter/material.dart';
import 'package:flutter_application_practice/auth/auth_service.dart';
import 'package:flutter_application_practice/profile/profile_service.dart';
import 'package:flutter_application_practice/screens/signup_screen/signup_widget.dart';

// ── Edit "About" ───────────────────────────────────────────────────────────
class AboutEditorSheet extends StatefulWidget {
  final String initial;
  const AboutEditorSheet({super.key, required this.initial});

  @override
  State<AboutEditorSheet> createState() => _AboutEditorSheetState();
}

class _AboutEditorSheetState extends State<AboutEditorSheet> {
  static const _minLength = 20;
  static const _maxLength = 500;

  final _service = ProfileService();
  late final _controller = TextEditingController(text: widget.initial);
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.length < _minLength) {
      setState(() => _error = 'Please write at least $_minLength characters.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _service.updateAbout(text);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = AuthService.friendlyError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Edit About',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            maxLines: 6,
            maxLength: _maxLength,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            decoration: signupInputDecoration('About')
                .copyWith(errorText: _error, errorMaxLines: 2),
          ),
          const SizedBox(height: 12),
          SignupContinueButton(
            label: _saving ? 'Saving...' : 'Save',
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}

// ── Edit schedule ──────────────────────────────────────────────────────────
class _EditSlot {
  String day;
  TimeOfDay? from;
  TimeOfDay? to;
  _EditSlot(this.day, [this.from, this.to]);
}

class ScheduleEditorSheet extends StatefulWidget {
  final List<ScheduleSlot> initial;
  const ScheduleEditorSheet({super.key, required this.initial});

  @override
  State<ScheduleEditorSheet> createState() => _ScheduleEditorSheetState();
}

class _ScheduleEditorSheetState extends State<ScheduleEditorSheet> {
  final _service = ProfileService();
  late final List<_EditSlot> _slots =
      widget.initial.map((s) => _EditSlot(s.day, s.start, s.end)).toList();
  String? _error;
  bool _saving = false;

  int _mins(TimeOfDay t) => t.hour * 60 + t.minute;

  Future<void> _pick(_EditSlot slot, bool isFrom) async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          (isFrom ? slot.from : slot.to) ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        slot.from = picked;
      } else {
        slot.to = picked;
      }
      _error = null;
    });
  }

  void _addSlot() => setState(() {
        final day = scheduleDays.firstWhere(
          (d) => !_slots.any((s) => s.day == d),
          orElse: () => 'MON',
        );
        _slots.add(_EditSlot(day));
        _error = null;
      });

  String? _validate() {
    for (final s in _slots) {
      if (s.from == null || s.to == null) {
        return 'Please set both start and end time, or remove that slot.';
      }
      if (_mins(s.to!) <= _mins(s.from!)) {
        return 'End time must be after start time.';
      }
    }
    for (final d in scheduleDays) {
      final list = _slots.where((s) => s.day == d).toList()
        ..sort((a, b) => _mins(a.from!).compareTo(_mins(b.from!)));
      for (var i = 1; i < list.length; i++) {
        if (_mins(list[i].from!) < _mins(list[i - 1].to!)) {
          return 'Time slots on the same day cannot overlap.';
        }
      }
    }
    return null;
  }

  Future<void> _save() async {
    final problem = _validate();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _service.saveAvailability(_slots
          .map((s) => ScheduleSlot(day: s.day, start: s.from!, end: s.to!))
          .toList());
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = AuthService.friendlyError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Edit Schedule',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_slots.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text('No availability yet. Add a time slot below.',
                          style: TextStyle(color: Color(0xFF6B7280))),
                    ),
                  for (final slot in _slots)
                    Padding(
                      key: ObjectKey(slot),
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          DropdownButton<String>(
                            value: slot.day,
                            underline: const SizedBox.shrink(),
                            borderRadius: BorderRadius.circular(12),
                            items: scheduleDays
                                .map((d) =>
                                    DropdownMenuItem(value: d, child: Text(d)))
                                .toList(),
                            onChanged: (v) => setState(() {
                              slot.day = v!;
                              _error = null;
                            }),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _TimeButton(
                              label: slot.from == null
                                  ? 'From'
                                  : formatTime(slot.from!),
                              onTap: () => _pick(slot, true),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Text('to'),
                          ),
                          Expanded(
                            child: _TimeButton(
                              label:
                                  slot.to == null ? 'To' : formatTime(slot.to!),
                              onTap: () => _pick(slot, false),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () => setState(() {
                              _slots.remove(slot);
                              _error = null;
                            }),
                            icon: const Icon(Icons.close_rounded, size: 20),
                          ),
                        ],
                      ),
                    ),
                  SignupAddButton(label: 'Add time slot', onPressed: _addSlot),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(_error!,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 13)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SignupContinueButton(
            label: _saving ? 'Saving...' : 'Save',
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TimeButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black,
        side: const BorderSide(color: Colors.black),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child:
          FittedBox(child: Text(label, style: const TextStyle(fontSize: 13))),
    );
  }
}
