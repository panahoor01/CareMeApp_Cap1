import 'dart:typed_data';

import 'package:flutter/material.dart' show TimeOfDay, DayPeriod;
import 'package:supabase_flutter/supabase_flutter.dart';

const scheduleDays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

String formatTime(TimeOfDay t) {
  final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
}

int _mins(TimeOfDay t) => t.hour * 60 + t.minute;

TimeOfDay _parseTime(String s) {
  final p = s.split(':');
  return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
}

String _hms(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

class ScheduleSlot {
  final String day; // MON..SUN
  final TimeOfDay start;
  final TimeOfDay end;
  const ScheduleSlot(
      {required this.day, required this.start, required this.end});
}

class ProfileData {
  final String role; // client | beautician
  final String firstName;
  final String lastName;
  final String? profileImage;
  final String? bio;
  final String? about; // beautician only
  final List<ScheduleSlot> schedule; // beautician only
  final int servicesCount; // beautician only: all of their services
  final double? rating;
  final int ratingCount;

  const ProfileData({
    required this.role,
    required this.firstName,
    required this.lastName,
    this.profileImage,
    this.bio,
    this.about,
    this.schedule = const [],
    this.servicesCount = 0,
    this.rating,
    this.ratingCount = 0,
  });

  bool get isBeautician => role == 'beautician';
  String get fullName => '$firstName $lastName'.trim();
  String get initial {
    final f = firstName.trim();
    return f.isEmpty ? '?' : f[0].toUpperCase();
  }
}

class ProfileService {
  SupabaseClient get _db => Supabase.instance.client;

  Future<ProfileData> fetch() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw AuthException('Please log in again.');

    final u = await _db
        .from('users')
        .select('role, first_name, last_name, profile_image, bio')
        .eq('id', uid)
        .single();

    final role = u['role'] as String;
    String? about;
    List<ScheduleSlot> schedule = [];
    int servicesCount = 0;
    double? rating;
    int ratingCount = 0;

    if (role == 'beautician') {
      final b = await _db
          .from('beauticians')
          .select('about')
          .eq('user_id', uid)
          .maybeSingle();
      about = b?['about'] as String?;

      final rows = await _db
          .from('beautician_availability_sched')
          .select('day_of_week, start_time, end_time')
          .eq('beautician_id', uid);

      final slots = rows
          .map((r) => ScheduleSlot(
                day: r['day_of_week'] as String,
                start: _parseTime(r['start_time'] as String),
                end: _parseTime(r['end_time'] as String),
              ))
          .toList();
      slots.sort((a, b) {
        final d =
            scheduleDays.indexOf(a.day).compareTo(scheduleDays.indexOf(b.day));
        return d != 0 ? d : _mins(a.start).compareTo(_mins(b.start));
      });
      schedule = slots;

      // every service across all of this beautician's categories
      final svc = await _db
          .from('services')
          .select(
              'service_id, beautician_service_categories!inner(beautician_id)')
          .eq('beautician_service_categories.beautician_id', uid);
      servicesCount = svc.length;

      final ratingResult = await _db.rpc('get_beautician_rating_summary',
          params: {'p_beautician_id': uid});
      final ratingRow = Map<String, dynamic>.from(ratingResult as Map);
      rating = (ratingRow['average_rating'] as num?)?.toDouble();
      ratingCount = (ratingRow['rating_count'] as num?)?.toInt() ?? 0;
    }

    return ProfileData(
      role: role,
      firstName: u['first_name'] as String,
      lastName: u['last_name'] as String,
      profileImage: u['profile_image'] as String?,
      bio: u['bio'] as String?,
      about: about,
      schedule: schedule,
      servicesCount: servicesCount,
      rating: rating,
      ratingCount: ratingCount,
    );
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String bio,
    required String? profileImage,
  }) async {
    await _db.rpc('update_my_profile', params: {
      'p_first_name': firstName,
      'p_last_name': lastName,
      'p_bio': bio,
      'p_profile_image': profileImage,
    });
  }

  Future<String> uploadAvatar(Uint8List bytes, String contentType) async {
    final uid = _db.auth.currentUser!.id;
    final path = '$uid/avatar';
    await _db.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(upsert: true, contentType: contentType),
        );
    final url = _db.storage.from('avatars').getPublicUrl(path);
    // same path every time, so add a version to bypass the image cache
    return '$url?v=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> updateAbout(String about) async {
    await _db.rpc('update_beautician_about', params: {'p_about': about});
  }

  Future<void> saveAvailability(List<ScheduleSlot> slots) async {
    await _db.rpc('save_my_availability', params: {
      'p_availability': slots
          .map((s) => {
                'day': s.day,
                'start': _hms(s.start),
                'end': _hms(s.end),
              })
          .toList(),
    });
  }
}
