import 'package:flutter/material.dart';
import 'package:flutter_application_practice/screens/signup_screen/signup_widget.dart';
import 'package:flutter_application_practice/auth/auth_navigation.dart';
import 'package:flutter_application_practice/auth/auth_service.dart';

import '../../auth/user_model.dart';
import 'professional_profile_screen.dart';

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
  bool _loading = false;
  final _auth = AuthService();
  String? _passwordError;
  String? _confirmError;

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

  Future<void> _continue() async {
    final password = passwordController.text;
    final confirm = confirmController.text;

    final passwordError = _isStrongEnough(password)
        ? null
        : 'Password needs 8+ characters, upper & lower case, and a number.';
    final confirmError = password != confirm ? 'Passwords do not match.' : null;

    if (passwordError != null || confirmError != null) {
      setState(() {
        _passwordError = passwordError;
        // Only show the mismatch once the password itself is acceptable,
        // otherwise the user sees two errors for one problem.
        _confirmError = passwordError == null ? confirmError : null;
      });
      return;
    }

    widget.user.password = password;

    if (widget.user.isBeautician) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ProfessionalProfileScreen(user: widget.user)),
      );
      return;
    }
    await _submit();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await _auth.signUpWithPhone(widget.user);
      widget.user.password = null;
      if (!mounted) return;
      goToProfileLandingPage(context, widget.user.role!);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthService.friendlyError(e))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
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
      continueEnabled: !_loading,
      child: Column(
        children: [
          TextField(
            controller: passwordController,
            obscureText: _obscure,
            onChanged: (_) {
              if (_passwordError != null || _confirmError != null) {
                setState(() {
                  _passwordError = null;
                  _confirmError = null;
                });
              }
            },
            decoration: signupInputDecoration('Password').copyWith(
              errorText: _passwordError,
              errorMaxLines: 3,
              suffixIcon: IconButton(
                padding: const EdgeInsets.only(right: 16),
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
            onChanged: (_) {
              if (_confirmError != null) setState(() => _confirmError = null);
            },
            decoration:
                signupInputDecoration('Re-enter your password').copyWith(
              errorText: _confirmError,
              suffixIcon: IconButton(
                padding: const EdgeInsets.only(right: 16),
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
