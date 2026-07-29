import 'package:flutter/material.dart';
import 'package:flutter_application_practice/screens/signup_screen/signup_widget.dart';

import '../../auth/user_model.dart';
import 'password_screen.dart';

class PhoneScreen extends StatefulWidget {
  final UserModel user;

  const PhoneScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final phoneController = TextEditingController();

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  String get _title =>
      widget.user.isBeautician ? 'Beautician Sign up' : 'Client Sign up';

  void _continue() {
    final phone = phoneController.text.trim();
    if (phone.length < 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid mobile number.')),
      );
      return;
    }

    widget.user.phone = phone;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PasswordScreen(user: widget.user)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SignupStepScaffold(
      title: _title,
      heading: "What's your mobile number?",
      subheading: "Enter your mobile number. This won't be shown publicly.",
      onContinue: _continue,
      child: TextField(
        controller: phoneController,
        keyboardType: TextInputType.phone,
        decoration: signupInputDecoration('Mobile Number'),
      ),
    );
  }
}
