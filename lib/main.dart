import 'package:flutter/material.dart';
import 'package:flutter_application_practice/auth/auth_service.dart';
import 'package:flutter_application_practice/config/app_config.dart';
import 'package:flutter_application_practice/pages/main_navbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabasePublishableKey,
  );
  runApp(const CareMeApp());
}

class CareMeApp extends StatelessWidget {
  const CareMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareMe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7BB8F0)),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const _StartGate(),
    );
  }
}

/// Logged-in users on a trusted device skip the login screen.
class _StartGate extends StatelessWidget {
  const _StartGate();

  Future<String?> _role() async {
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      final row = await client
          .from('users')
          .select('role, phone')
          .eq('id', uid)
          .maybeSingle();
      if (row == null) return null;

      // A session without a trusted device means login was abandoned at the OTP step
      final auth = AuthService();
      if (!await auth.isTrustedDevice(row['phone'] as String)) {
        await auth.signOut();
        return null;
      }
      return row['role'] as String;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _role(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final role = snap.data;
        if (role == null) return const LoginScreen();
        return MainNavBar(role: role, initialIndex: 2);
      },
    );
  }
}
