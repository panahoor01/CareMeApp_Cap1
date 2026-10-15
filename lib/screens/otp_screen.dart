import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_practice/auth/auth_service.dart';
import 'package:flutter_application_practice/screens/signup_screen/signup_widget.dart';
import 'package:flutter_application_practice/screens/signup_screen/singup_theme.dart';


class OtpScreen extends StatefulWidget {
  final String phoneNumber; // normalized, e.g. +639123456789
  final String purpose; // signup | login | change_phone | reset_password
  final String? devCode; // no SMS provider yet: shown in debug builds only
  final Future<void> Function(BuildContext context) onVerified;
  final VoidCallback? onCancel; // runs if the user leaves without verifying
  final String? title; // defaults to a title based on purpose
  final String? role; // "client" | "beautician", used for the signup title

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.purpose,
    required this.onVerified,
    this.devCode,
    this.onCancel,
    this.title,
    this.role,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  final _auth = AuthService();
  Timer? _timer;
  int _secondsLeft = 60; // matches the 1-minute expiry in the database
  bool _busy = false;
  bool _completed = false;
  String? _devCode;

  @override
  void initState() {
    super.initState();
    _devCode = widget.devCode;
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    _secondsLeft = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft <= 1) t.cancel();
      setState(() => _secondsLeft--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (!_completed) widget.onCancel?.call();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  // Modern switch expressions that Returns a default title based on the purpose and role.
  String get _defaultTitle {
    return switch (widget.purpose) {
      'login' => 'Login',
      'signup' => switch (widget.role) {
          'beautician' => 'Beautician Sign up',
          'client' => 'Client Sign up',
          _ => 'Sign up',
        },
      'change_phone' => 'Change phone number',
      'reset_password' => 'Reset password',
      _ => 'Verification',
    };
  }

  void _onDigitEntered(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() {});

    // Auto-verify as soon as all 6 boxes are filled
    if (_otpCode.length == 6) {
      FocusScope.of(context).unfocus(); // hide the keyboard while verifying
      _verifyOtp();
    }
  }

  void _onBackspace(int index) {
    if (_controllers[index].text.isEmpty && index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
      setState(() {});
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpCode.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete 6-digit OTP.'),
          backgroundColor: Color(0xFFF0A0A0),
        ),
      );
      return;
    }

    if (_busy) return;
    setState(() => _busy = true);
    try {
      final res =
          await _auth.verifyOtp(widget.phoneNumber, widget.purpose, _otpCode);
      if (!mounted) return;

      switch (res['status']) {
        case 'ok':
          _completed = true;
          await widget.onVerified(context);
          return;
        case 'invalid':
          final left = (res['attempts_left'] as num?)?.toInt() ?? 0;
          _showError(left == 0
              ? 'Too many attempts. Wait for the code to expire, then request a new one.'
              : 'Incorrect code. $left attempt${left == 1 ? '' : 's'} left.');
          break;
        case 'locked':
          _showError(
              'Too many attempts. Wait for the code to expire, then request a new one.');
          break;
        case 'expired':
          _timer?.cancel();
          setState(() =>
              _secondsLeft = 0); // server says expired, so allow Resend now
          _showError('This code has expired. Tap Resend to get a new one.');
          break;
        default:
          _showError('No active code. Please request a new one.');
      }
      _clearBoxes(); // any non-success result: start over
    } catch (e) {
      if (mounted) _showError(AuthService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    try {
      final res = await _auth.requestOtp(widget.phoneNumber, widget.purpose);
      if (!mounted) return;
      setState(() => _devCode = res['code'] as String?);
      _clearBoxes();
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A new code has been sent.')),
      );
    } catch (e) {
      if (mounted) _showError(AuthService.friendlyError(e));
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFFF0A0A0)),
    );
  }

  void _clearBoxes() {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes.first.requestFocus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: SignupTopBar(title: widget.title ?? _defaultTitle),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Title
              const Text(
                'Verify your number',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: SignupTheme.textDark,
                ),
              ),

              const SizedBox(height: 10),

              // Subtitle with phone number
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF757575),
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: 'We sent a 6-digit code to ',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    TextSpan(
                      text: widget.phoneNumber,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const TextSpan(text: '.\nEnter it below to continue.',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // OTP input boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return _OtpBox(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    onChanged: (val) => _onDigitEntered(index, val),
                    onBackspace: () => _onBackspace(index),
                  );
                }),
              ),

              const SizedBox(height: 5),

              // Resend code (enabled once the 1-minute code has expired)
              Center(
                child: GestureDetector(
                  onTap: _secondsLeft == 0 ? _resend : null,
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF757575)),
                      children: [
                        const TextSpan(text: "Didn't receive a code? "),
                        TextSpan(
                          text: _secondsLeft == 0
                              ? 'Resend'
                              : 'Resend in ${_secondsLeft}s',
                          style: TextStyle(
                            color: _secondsLeft == 0
                                ? const Color(0xFF7BB8F0)
                                : const Color(0xFF9E9E9E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // No Verify button: the code is checked automatically
              SizedBox(
                height: 54,
                child: Center(
                  child: _busy
                      ? const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      : null,
                ),
              ),

              // DEV ONLY: no SMS provider yet, so show the code in debug builds
              if (kDebugMode && _devCode != null) ...[
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'DEV ONLY: your code is $_devCode',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Single OTP digit box ────────────────────────────────────────────────────
class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 54,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace) {
            onBackspace();
          }
        },
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: onChanged,
          decoration: InputDecoration(
            counterText: '',
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.grey,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF7BB8F0), width: 2),
            ),
          ),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ),
    );
  }
}
