import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  SupabaseClient? _supabase;

  SupabaseClient get _client {
    _supabase ??= Supabase.instance.client;
    return _supabase!;
  }

  //Sign in with email and password
  Future<AuthResponse> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  //Sign up with email and password
  Future<AuthResponse> signUpWithEmailPassword(
    String email,
    String password,
  ) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  //Sign out
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      // Ignore Supabase initialization issues when the app is running in demo mode.
    }
  }

  //Get current user
  String? getCurrentUserEmail() {
    final session = _client.auth.currentSession;
    final user = session?.user;
    return user?.email;
  }
}
