import 'package:flutter/material.dart';
import 'package:flutter_application_practice/screens/signup_screen/singup_theme.dart';

/// Top bar shared by every step screen after role selection:
/// "<"  back chevron  ...  centered title  ...  heart logo
class SignupTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const SignupTopBar({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left,
                  size: 26, color: SignupTheme.textDark),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: SignupTheme.textDark,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.favorite, color: SignupTheme.heart, size: 22),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(52);
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
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 6),
              child: Text(
                heading,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: SignupTheme.textDark,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Text(
                subheading,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: SignupTheme.textGrey,
                  height: 1.4,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: child,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
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
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: SignupTheme.accent,
          disabledBackgroundColor: SignupTheme.accent.withOpacity(0.4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SignupTheme.radius),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Shared decoration so every TextField / dropdown looks identical.
InputDecoration signupInputDecoration(String label, {String? hint}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: SignupTheme.fieldFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
    labelStyle: const TextStyle(color: SignupTheme.textGrey, fontSize: 13.5),
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
        icon: const Icon(Icons.add, size: 18, color: SignupTheme.textDark),
        label: Text(
          label,
          style: const TextStyle(
              color: SignupTheme.textDark, fontWeight: FontWeight.w500),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: SignupTheme.fieldBorder),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SignupTheme.radius),
          ),
        ),
      ),
    );
  }
}
