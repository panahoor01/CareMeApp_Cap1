import 'package:flutter/material.dart';
import 'package:flutter_application_practice/pages/main_navbar.dart';

/// Temporary landing page after signup/login. Clears the whole back stack.
void goToProfileLandingPage(BuildContext context, String role) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (_) => MainNavBar(role: role, initialIndex: 2),
    ),
    (route) => false,
  );
}
