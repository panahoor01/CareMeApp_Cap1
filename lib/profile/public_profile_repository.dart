import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_application_practice/profile/profile_service.dart';
import 'package:flutter_application_practice/pages/beautician/services/service_models.dart';
import 'package:flutter_application_practice/pages/beautician/services/service_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PublicBeauticianProfile {
  final String id;
  final String firstName;
  final String lastName;
  final String? profileImage;
  final String? bio;
  final String? about;
  final List<ServiceCategory> categories;
  final List<ScheduleSlot> schedule;
  final List<BeauticianService> services; // only the visible ones
  final double? rating;
  final int ratingCount;

  const PublicBeauticianProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profileImage,
    this.bio,
    this.about,
    this.categories = const [],
    this.schedule = const [],
    this.services = const [],
    this.rating,
    this.ratingCount = 0,
  });

  String get fullName => '$firstName $lastName'.trim();
  String get initial {
    final f = firstName.trim();
    return f.isEmpty ? '?' : f[0].toUpperCase();
  }
}

class PublicProfileRepository {
  SupabaseClient get _db => Supabase.instance.client;
  final _services = ServiceRepository();

  TimeOfDay _time(String s) {
    final p = s.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  Future<PublicBeauticianProfile> fetch(String beauticianId) async {
    final res = await _db.rpc('get_beautician_profile',
        params: {'p_beautician_id': beauticianId});
    final m = Map<String, dynamic>.from(res as Map);

    final categories = ((m['categories'] as List?) ?? []).map((e) {
      final c = Map<String, dynamic>.from(e as Map);
      return ServiceCategory(id: c['id'] as String, name: c['name'] as String);
    }).toList();
    int rank(String n) {
      final i = categoryOrder.indexOf(n);
      return i == -1 ? categoryOrder.length : i;
    }

    categories.sort((a, b) => rank(a.name).compareTo(rank(b.name)));

    final schedule = ((m['schedule'] as List?) ?? []).map((e) {
      final s = Map<String, dynamic>.from(e as Map);
      return ScheduleSlot(
        day: s['day'] as String,
        start: _time(s['start'] as String),
        end: _time(s['end'] as String),
      );
    }).toList();
    schedule.sort((a, b) {
      final d =
          scheduleDays.indexOf(a.day).compareTo(scheduleDays.indexOf(b.day));
      return d != 0
          ? d
          : (a.start.hour * 60 + a.start.minute)
              .compareTo(b.start.hour * 60 + b.start.minute);
    });

    var services = ((m['services'] as List?) ?? []).map((e) {
      final s = Map<String, dynamic>.from(e as Map);
      final variants = ((s['variants'] as List?) ?? []).map((v) {
        final x = Map<String, dynamic>.from(v as Map);
        return ServiceVariant(
          id: x['service_variant_id'] as int,
          name: x['name'] as String,
          addPrice: (x['add_price'] as num).toDouble(),
          extraMinutes: (x['extra_minutes'] as int?) ?? 0,
        );
      }).toList();
      return BeauticianService(
        id: s['service_id'] as String,
        categoryId: s['category_id'] as String,
        title: s['title'] as String,
        description: s['description'] as String?,
        images: List<String>.from((s['images'] as List?) ?? []),
        price: (s['price'] as num).toDouble(),
        durationMinutes: s['duration_minutes'] as int,
        isActive: true,
        variants: variants,
      );
    }).toList();

    final serviceRatings = await _services
        .fetchRatingSummaries(services.map((service) => service.id).toList());
    services = services
        .map((service) => service.withRating(
              serviceRatings[service.id] ??
                  const ServiceRatingSummary(average: null, count: 0),
            ))
        .toList();
    final beauticianRating =
        await _services.fetchBeauticianRatingSummary(beauticianId);

    return PublicBeauticianProfile(
      id: m['beautician_id'] as String,
      firstName: m['first_name'] as String,
      lastName: m['last_name'] as String,
      profileImage: m['profile_image'] as String?,
      bio: m['bio'] as String?,
      about: m['about'] as String?,
      categories: categories,
      schedule: schedule,
      services: services,
      rating: beauticianRating.average,
      ratingCount: beauticianRating.count,
    );
  }
}
