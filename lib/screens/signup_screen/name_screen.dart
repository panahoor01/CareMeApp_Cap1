import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_practice/screens/signup_screen/birthday_screen.dart';

import '../../auth/user_model.dart';
import 'signup_widget.dart';

class NameScreen extends StatefulWidget {
  final UserModel user;

  const NameScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  final firstController = TextEditingController();
  final lastController = TextEditingController();
  String? _firstError;
  String? _lastError;

  static const int _maxNameLength = 40;

  // Letters (including Ñ and accented letters) and spaces only
  static final _nameRegex = RegExp(r'^[\p{L} ]+$', unicode: true);

  // Trim and collapse repeated spaces: "Juan   Dela  Cruz " -> "Juan Dela Cruz"
  String _clean(String value) => value.trim().replaceAll(RegExp(r'\s+'), ' ');

  String? _validateName(String value, String label) {
    if (value.isEmpty) return 'Please enter your $label name.';
    if (value.length > _maxNameLength) {
      return 'Maximum of $_maxNameLength characters only.';
    }
    if (!_nameRegex.hasMatch(value)) {
      return 'Only letters and spaces are allowed.';
    }
    return null;
  }

  @override
  void dispose() {
    firstController.dispose();
    lastController.dispose();
    super.dispose();
  }

  String get _title =>
      widget.user.isBeautician ? 'Beautician Sign up' : 'Client Sign up';

  void _continue() {
    final first = _clean(firstController.text);
    final last = _clean(lastController.text);

    final firstError = _validateName(first, 'first');
    final lastError = _validateName(last, 'last');

    if (firstError != null || lastError != null) {
      setState(() {
        _firstError = firstError;
        _lastError = lastError;
      });
      return;
    }

    widget.user.firstName = first;
    widget.user.lastName = last;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BirthdayScreen(user: widget.user)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SignupStepScaffold(
      title: _title,
      heading: "What's your name?",
      subheading: 'Use your real name.',
      onContinue: _continue,
      child: Column(
        children: [
          TextField(
            controller: firstController,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [
              LengthLimitingTextInputFormatter(_maxNameLength),
            ],
            onChanged: (_) {
              if (_firstError != null) setState(() => _firstError = null);
            },
            decoration: signupInputDecoration('First name').copyWith(
              errorText: _firstError,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: lastController,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [
              LengthLimitingTextInputFormatter(_maxNameLength),
            ],
            onChanged: (_) {
              if (_lastError != null) setState(() => _lastError = null);
            },
            decoration: signupInputDecoration('Last name').copyWith(
              errorText: _lastError,
            ),
          ),
        ],
      ),
    );
  }
}
