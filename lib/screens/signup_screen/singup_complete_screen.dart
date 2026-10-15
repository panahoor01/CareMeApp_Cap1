import 'package:flutter/material.dart';
import 'package:flutter_application_practice/screens/signup_screen/singup_theme.dart';

import '../../auth/user_model.dart';

class SignupCompleteScreen extends StatelessWidget {
  final UserModel user;

  const SignupCompleteScreen({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle,
                  color: SignupTheme.accent, size: 72),
              const SizedBox(height: 20),
              Text(
                'Welcome, ${user.firstName ?? ''}!',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: SignupTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user.isBeautician
                    ? 'Your beautician profile is all set up.'
                    : 'Your account is ready to go.',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.popUntil(context, (route) => route.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(SignupTheme.radius),
                    ),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0xFFB5E8FF),
                          Color(0xFFFFD4C8)
                        ],
                      ),
                      borderRadius: BorderRadius.circular(SignupTheme.radius),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: const Text(
                        'Continue to CareMe',
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
