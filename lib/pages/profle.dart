import 'package:flutter/material.dart';
import 'package:flutter_application_practice/screens/signup_screen/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset('assets/logo2.png', height: 30),
            ),
            const SizedBox(width: 15),
            const Text('CareMe', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final shouldLogout = await showDialog<bool>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, false);
                      },
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, true);
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                );
              },
            );

            if (shouldLogout == true) {
              await Supabase.instance.client.auth.signOut();

              if (!context.mounted) return;

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            }
          },
          child: const Text('Logout'),
        ),
      ),
    );
  }
}
