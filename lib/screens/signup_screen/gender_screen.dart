import 'package:flutter/material.dart';
import 'package:flutter_application_practice/screens/signup_screen/signup_widget.dart';
import 'package:flutter_application_practice/screens/signup_screen/singup_theme.dart';

import '../../auth/user_model.dart';
import 'phone_screen.dart';

class GenderScreen extends StatefulWidget {
  final UserModel user;

  const GenderScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<GenderScreen> createState() => _GenderScreenState();
}

class _GenderScreenState extends State<GenderScreen> {
  String? _selectedGender;

  static const _options = ['Male', 'Female', 'Others'];

  String get _title =>
      widget.user.isBeautician ? 'Beautician Sign up' : 'Client Sign up';

  void _continue() {
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose your gender.')),
      );
      return;
    }

    widget.user.gender = _selectedGender;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PhoneScreen(user: widget.user)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SignupStepScaffold(
      title: _title,
      heading: "What's your gender?",
      subheading: 'Choose your gender. This will be shown on your profile.',
      onContinue: _continue,
      child: Column(
        children: _options
            .map((option) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _GenderOption(
                    label: option,
                    selected: _selectedGender == option,
                    onTap: () => setState(() => _selectedGender = option),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _GenderOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GenderOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: SignupTheme.fieldFill,
          borderRadius: BorderRadius.circular(SignupTheme.radius),
          border: Border.all(
            color: selected ? SignupTheme.accent : SignupTheme.fieldBorder,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14.5,
                color: SignupTheme.textDark,
              ),
            ),
            Radio<bool>(
              value: true,
              groupValue: selected ? true : false,
              activeColor: SignupTheme.accent,
              onChanged: (_) => onTap(),
            ),
          ],
        ),
      ),
    );
  }
}
