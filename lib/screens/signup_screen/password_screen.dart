import 'package:flutter/material.dart';
import 'package:flutter_application_practice/screens/signup_screen/signup_widget.dart';
import 'package:flutter_application_practice/screens/signup_screen/singup_complete_screen.dart';

import '../../auth/user_model.dart';
import 'specialty_screen.dart';

class PasswordScreen extends StatefulWidget {
  final UserModel user;

  const PasswordScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  String get _title =>
      widget.user.isBeautician ? 'Beautician Sign up' : 'Client Sign up';

  bool _isStrongEnough(String value) {
    if (value.length < 8) return false;
    final hasUpper = value.contains(RegExp(r'[A-Z]'));
    final hasLower = value.contains(RegExp(r'[a-z]'));
    final hasDigit = value.contains(RegExp(r'[0-9]'));
    return hasUpper && hasLower && hasDigit;
  }

  void _continue() {
    final password = passwordController.text;
    final confirm = confirmController.text;

    if (!_isStrongEnough(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password needs 8+ characters, upper & lower case, and a number.',
          ),
        ),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    widget.user.password = password;

    if (widget.user.isBeautician) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SpecialtyScreen(user: widget.user)),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => SignupCompleteScreen(user: widget.user)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SignupStepScaffold(
      title: _title,
      heading: 'Create your password.',
      subheading:
          'Create a strong password with at least 8 characters, including '
          'uppercase and lowercase letters and a number.',
      onContinue: _continue,
      child: Column(
        children: [
          TextField(
            controller: passwordController,
            obscureText: _obscure,
            decoration: signupInputDecoration('Password').copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: confirmController,
            obscureText: _obscureConfirm,
            decoration:
                signupInputDecoration('Re-enter your password').copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
