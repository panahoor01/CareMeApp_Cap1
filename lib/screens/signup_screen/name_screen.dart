import 'package:flutter/material.dart';
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

  @override
  void dispose() {
    firstController.dispose();
    lastController.dispose();
    super.dispose();
  }

  String get _title =>
      widget.user.isBeautician ? 'Beautician Sign up' : 'Client Sign up';

  void _continue() {
    if (firstController.text.trim().isEmpty ||
        lastController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your first and last name.')),
      );
      return;
    }

    widget.user.firstName = firstController.text.trim();
    widget.user.lastName = lastController.text.trim();

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
            decoration: signupInputDecoration('First name'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: lastController,
            decoration: signupInputDecoration('Last name'),
          ),
        ],
      ),
    );
  }
}
