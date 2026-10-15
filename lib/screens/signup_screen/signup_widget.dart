import 'package:flutter/material.dart';
import 'package:flutter_application_practice/screens/signup_screen/singup_theme.dart';

/// Top bar shared by every step screen after role selection:
/// "<"  back chevron  ...  centered title  ...  heart logo
class SignupTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const SignupTopBar({Key? key, required this.title}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Row(
                  children: [
                    Icon(
                      Icons.chevron_left_rounded,
                      size: 30,
                      color: Color(0xFF1A1A1A),
                    ),
                    Text(
                      "Back",
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Title
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: SignupTheme.textDark,
                    ),
                  ),
                ),
              ),
              Image.asset(
                'assets/careme_logo.png',
                width: 40,
                height: 40,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.favorite,
                  color: Color(0xFFFF6B81),
                  size: 26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Standard page shell used by every step: top bar, heading, subheading,
/// scrollable form body, and a full-width Continue button pinned to the
/// bottom.
class SignupStepScaffold extends StatelessWidget {
  final String title; // e.g. "Beautician Sign up"
  final String heading; // e.g. "What's your name?"
  final String subheading;
  final Widget child;
  final String continueLabel;
  final VoidCallback onContinue;
  final bool continueEnabled;

  const SignupStepScaffold({
    Key? key,
    required this.title,
    required this.heading,
    required this.subheading,
    required this.child,
    required this.onContinue,
    this.continueLabel = 'Continue',
    this.continueEnabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: SignupTopBar(title: title),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                      child: Text(
                        heading,
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: SignupTheme.textDark,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: Text(
                        subheading,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: child,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: SignupContinueButton(
                label: continueLabel,
                onPressed: continueEnabled ? onContinue : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SignupContinueButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const SignupContinueButton({
    Key? key,
    required this.onPressed,
    this.label = 'Continue',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SignupTheme.radius),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFFB5E8FF), const Color(0xFFFFD4C8)]
                  .map((c) => onPressed == null ? c.withValues(alpha: 0.4) : c)
                  .toList(),
            ),
            borderRadius: BorderRadius.circular(SignupTheme.radius),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration signupInputDecoration(String label, {String? hintText}) {
  return InputDecoration(
    labelText: label,
    hintText: hintText,
    filled: true,
    fillColor: SignupTheme.fieldFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    alignLabelWithHint: true,

    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(SignupTheme.radius),
      borderSide: const BorderSide(color: SignupTheme.fieldBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(SignupTheme.radius),
      borderSide: const BorderSide(color: SignupTheme.fieldBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(SignupTheme.radius),
      borderSide: const BorderSide(color: SignupTheme.accent, width: 1.4),
    ),
    labelStyle: const TextStyle(color: SignupTheme.textGrey, fontSize: 15),
  );
}

/// Small pill-style "Add another ..." button used on the specialty screen.
class SignupAddButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const SignupAddButton(
      {Key? key, required this.label, required this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add_circle_outline_rounded, size: 22, color: Color.fromARGB(255, 1, 170, 249)),
        label: Text(
          label,
          style: const TextStyle(
              fontSize: 16,
              color: SignupTheme.textDark, fontWeight: FontWeight.w400),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color.fromARGB(255, 1, 170, 249)),
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SignupTheme.radius),
          ),
        ),
      ),
    );
  }
}
