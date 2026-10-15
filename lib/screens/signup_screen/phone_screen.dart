import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_practice/screens/signup_screen/signup_widget.dart';

import '../../auth/user_model.dart';
import 'package:flutter_application_practice/auth/auth_service.dart';
import 'package:flutter_application_practice/auth/phone_utils.dart';
import 'package:flutter_application_practice/screens/otp_screen.dart';
import 'password_screen.dart';

class PhoneScreen extends StatefulWidget {
  final UserModel user;

  const PhoneScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final phoneController = TextEditingController();
  String? _phoneError;
  final _auth = AuthService();
  bool _loading = false;

  // Accepts: 09XXXXXXXXX, 9XXXXXXXXX, 639XXXXXXXXX, +639XXXXXXXXX
  static final _phMobileRegex = RegExp(r'^(?:\+?63|0)?9\d{9}$');

  bool _isValidPhMobile(String input) {
    // Ignore spaces, dashes, and parentheses the user may type
    final cleaned = input.replaceAll(RegExp(r'[\s\-()]'), '');
    return _phMobileRegex.hasMatch(cleaned);
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  String get _title =>
      widget.user.isBeautician ? 'Beautician Sign up' : 'Client Sign up';

  Future<void> _continue() async {
    final input = phoneController.text.trim();
    if (!_isValidPhMobile(input)) {
      setState(() => _phoneError = 'Please enter a valid mobile number.');
      return;
    }
    setState(() {
      _phoneError = null;
      _loading = true;
    });

    final phone = PhoneUtils.normalize(input);
    try {
      final otp = await _auth.requestOtp(phone, 'signup');
      if (!mounted) return;
      widget.user.phone = phone;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            phoneNumber: phone,
            purpose: 'signup',
            title: _title,
            devCode: otp['code'] as String?,
            onVerified: (ctx) async {
              // replace the OTP screen so Back from Password returns here
              Navigator.pushReplacement(
                ctx,
                MaterialPageRoute(
                    builder: (_) => PasswordScreen(user: widget.user)),
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AuthService.friendlyError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SignupStepScaffold(
      title: _title,
      heading: "What's your mobile number?",
      subheading: "Enter your mobile number. This won't be shown publicly.",
      onContinue: _continue,
      continueEnabled: !_loading,
      child: TextField(
        controller: phoneController,
        keyboardType: TextInputType.phone,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s\-]')),
        ],
        onChanged: (_) {
          // Clear the error as soon as the user starts correcting it
          if (_phoneError != null) setState(() => _phoneError = null);
        },
        decoration: signupInputDecoration('Mobile Number').copyWith(
          errorText: _phoneError,
        ),
      ),
    );
  }
}
