import 'package:flutter/material.dart';
import 'package:flutter_application_practice/screens/signup_screen/signup_widget.dart';
import 'package:flutter_application_practice/screens/signup_screen/singup_theme.dart';

import '../../auth/user_model.dart';
import 'gender_screen.dart';

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String formatBirthday(DateTime date) =>
    '${_months[date.month - 1]} ${date.day}, ${date.year}';

class BirthdayScreen extends StatefulWidget {
  final UserModel user;

  const BirthdayScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<BirthdayScreen> createState() => _BirthdayScreenState();
}

class _BirthdayScreenState extends State<BirthdayScreen> {
  DateTime? _selectedDate;

  String get _title =>
      widget.user.isBeautician ? 'Beautician Sign up' : 'Client Sign up';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: SignupTheme.accent,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _continue() {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your birthday.')),
      );
      return;
    }

    widget.user.birthdayDate = _selectedDate;
    widget.user.birthday = formatBirthday(_selectedDate!);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GenderScreen(user: widget.user)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SignupStepScaffold(
      title: _title,
      heading: "What's your birthday?",
      subheading: 'Enter your birthday. You can keep it private later.',
      onContinue: _continue,
      child: GestureDetector(
        onTap: _pickDate,
        child: AbsorbPointer(
          child: TextField(
            controller: TextEditingController(
              text: _selectedDate == null ? '' : formatBirthday(_selectedDate!),
            ),
            decoration: signupInputDecoration('Birthday').copyWith(
              suffixIcon: const Icon(Icons.calendar_today_outlined,
                  size: 18, color: SignupTheme.textGrey),
            ),
          ),
        ),
      ),
    );
  }
}
