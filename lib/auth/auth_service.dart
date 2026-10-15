import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_application_practice/auth/phone_utils.dart';
import 'package:flutter_application_practice/auth/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  SupabaseClient? _supabase;

  SupabaseClient get _client {
    _supabase ??= Supabase.instance.client;
    return _supabase!;
  }

  // ── Login: returns the user's role ("client" | "beautician") ───────────
  Future<String> signInWithPhone(String phone, String password) async {
    final res = await _client.auth.signInWithPassword(
      phone: PhoneUtils.normalize(phone),
      password: password,
    );
    final row = await _client
        .from('users')
        .select('role')
        .eq('id', res.user!.id)
        .maybeSingle();
    if (row == null) {
      await signOut();
      throw AuthException('Account setup is incomplete. Please sign up again.');
    }
    return row['role'] as String;
  }

  // ── Signup: creates the auth account, then saves everything atomically ─
  Future<void> signUpWithPhone(UserModel user) async {
    final phone = PhoneUtils.normalize(user.phone!);
    final password = user.password!;

    try {
      final res = await _client.auth.signUp(phone: phone, password: password);
      if (res.session == null) {
        throw AuthException(
            'Turn off "Enable phone confirmations" in Supabase Auth settings.');
      }
    } on AuthException catch (e) {
      if (!e.message.toLowerCase().contains('already')) rethrow;
      // Left over from an earlier attempt that failed after the auth step
      await _client.auth.signInWithPassword(phone: phone, password: password);
    }

    final b = user.birthdayDate!;
    final birthday = '${b.year.toString().padLeft(4, '0')}-'
        '${b.month.toString().padLeft(2, '0')}-'
        '${b.day.toString().padLeft(2, '0')}';

    await _client.rpc('complete_signup', params: {
      'p_role': user.role,
      'p_first_name': user.firstName,
      'p_last_name': user.lastName,
      'p_birthday': birthday,
      'p_gender': user.gender,
      'p_phone': phone,
      'p_about': user.isBeautician ? user.about : null,
      'p_services': user.isBeautician ? user.services : <String>[],
      'p_availability': user.availability
          .where((s) => s.from != null && s.to != null)
          .map((s) => {
                'day': s.day,
                'start': _hms(s.from!),
                'end': _hms(s.to!),
              })
          .toList(),
    });

    await trustDevice(phone);
  }

  String _hms(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  // ── OTP ────────────────────────────────────────────────────────────────
  /// Returns {code, expires_at}. `code` exists only for dev testing while
  /// there is no SMS provider; remove it from the SQL when PhilSMS is wired.
  Future<Map<String, dynamic>> requestOtp(String phone, String purpose) async {
    final res = await _client
        .rpc('request_otp', params: {'p_phone': phone, 'p_purpose': purpose});
    return Map<String, dynamic>.from(res as Map);
  }

  /// status: ok | invalid | expired | locked | none  (+ attempts_left on invalid)
  Future<Map<String, dynamic>> verifyOtp(
      String phone, String purpose, String code) async {
    final res = await _client.rpc('verify_otp',
        params: {'p_phone': phone, 'p_purpose': purpose, 'p_code': code});
    return Map<String, dynamic>.from(res as Map);
  }

  // ── "First login on this device" flag ──────────────────────────────────
  Future<bool> isTrustedDevice(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('trusted_device_$phone') ?? false;
  }

  Future<void> trustDevice(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('trusted_device_$phone', true);
  }

  // ── Error messages for snackbars ───────────────────────────────────────
  static String friendlyError(Object e) {
    if (e is AuthException) {
      final m = e.message.toLowerCase();
      if (m.contains('invalid login')) {
        return 'Incorrect phone number or password.';
      }
      if (m.contains('socketexception') || m.contains('failed host lookup')) {
        return 'Cannot reach the server. Please check your internet connection.';
      }
      return e.message;
    }
    if (e is PostgrestException) {
      switch (e.message) {
        case 'phone_already_registered':
          return 'This mobile number is already registered.';
        case 'phone_not_registered':
          return 'No account found for this mobile number.';
        case 'otp_still_active':
          return 'Please wait ${e.hint ?? 'a moment'}s before requesting a new code.';
        case 'phone_not_verified':
          return 'Please verify your mobile number first.';
        case 'not_authenticated':
          return 'Please log in again.';
      }
    }
    return 'Something went wrong. Please try again.';
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
