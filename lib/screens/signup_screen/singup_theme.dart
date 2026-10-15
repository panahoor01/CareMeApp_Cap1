import 'package:flutter/material.dart';

/// Shared design tokens for the whole sign-up flow so every step
/// (role, name, birthday, gender, phone, password, specialty) looks
/// like one consistent product instead of six different screens.
class SignupTheme {
  SignupTheme._();

  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGrey = Color(0xFF757575);
  static const Color fieldFill = Colors.transparent;
  static const Color fieldBorder = Colors.black;
  static const Color accent = Color(0xFFFF8A80); // coral "Continue" button
  static const Color accentDark = Color(0xFFFF6F61);
  static const Color heart = Color(0xFFFF6B81);

  static const double radius = 28;
}
