import 'package:flutter/material.dart';
import 'package:flutter_application_practice/auth/auth_service.dart';
import 'package:flutter_application_practice/location/availability_tracker.dart';
import 'package:flutter_application_practice/location/location_service.dart';

/// "Active" label + switch. Every instance shows the same shared state.
class ActiveToggle extends StatefulWidget {
  const ActiveToggle({super.key});

  @override
  State<ActiveToggle> createState() => _ActiveToggleState();
}

class _ActiveToggleState extends State<ActiveToggle> {
  static const _green = Color(0xFF22C55E);
  final _tracker = AvailabilityTracker.instance;

  @override
  void initState() {
    super.initState();
    _tracker.sync(); // restores the saved Active state (and resumes tracking)
  }

  Future<void> _onChanged(bool value) async {
    try {
      if (value) {
        await _tracker.turnOn();
      } else {
        await _tracker.turnOff();
      }
    } on LocationProblem catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          action: e.canOpenSettings
              ? SnackBarAction(
                  label: 'Settings',
                  onPressed: LocationService.openSettings,
                )
              : null,
        ),
      );
    } catch (e) {
      debugPrint('toggle Active failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthService.friendlyError(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _tracker.active,
      builder: (context, active, _) => ValueListenableBuilder<bool>(
        valueListenable: _tracker.busy,
        builder: (context, busy, __) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              active ? 'Active' : 'Inactive',
              style: TextStyle(
                color: active ? _green : const Color(0xFF9CA3AF),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 52,
              height: 32,
              child: Center(
                child: busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: _green),
                      )
                    : Switch(
                        value: active,
                        onChanged: _onChanged,
                        thumbColor: WidgetStateProperty.all(Colors.white),
                        trackColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.selected)
                              ? _green
                              : const Color(0xFFD1D5DB),
                        ),
                        trackOutlineColor:
                            WidgetStateProperty.all(Colors.transparent),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
