import 'package:flutter/material.dart';
import 'package:flutter_application_practice/auth/user_model.dart';
import 'package:flutter_application_practice/screens/signup_screen/name_screen.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.chevron_left,
                          size: 26,
                          color: Color(0xFF1A1A1A),
                        ),
                        Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF1A1A1A),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Title
                  const Text(
                    'Sign up',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),

                  // Logo (top right)
                  Image.asset(
                    'assets/careme_logo.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),

            // ── Welcome Text ─────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 6),
              child: Text(
                'Welcome to CareMe!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Text(
                "Let's create your account.\nPlease select your role to continue.",
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF757575),
                  height: 1.5,
                ),
              ),
            ),

            // ── Role Cards ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Client Card
                  _RoleCard(
                    icon: Icons.person_outline,
                    title: "I'm a client",
                    subtitle: 'Find and book trusted\nbeauticians near you.',
                    onTap: () {
                      final user = UserModel(role: 'client');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NameScreen(user: user),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  // Beautician Card
                  _RoleCard(
                    icon: Icons.spa_outlined,
                    title: "I'm a beautician",
                    subtitle:
                        'Showcase your services and\nconnect with clients.',
                    onTap: () {
                      final user = UserModel(role: 'beautician');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NameScreen(user: user),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable Role Selection Card ────────────────────────────────────────────
class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            // Icon
            Icon(icon, size: 32, color: const Color(0xFF1A1A1A)),
            const SizedBox(width: 16),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF757575),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Chevron
            const Icon(Icons.chevron_right, color: Color(0xFF1A1A1A), size: 22),
          ],
        ),
      ),
    );
  }
}
