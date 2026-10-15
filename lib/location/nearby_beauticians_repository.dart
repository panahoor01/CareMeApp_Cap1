import 'package:flutter_application_practice/pages/beautician/services/service_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 1200 -> "1.2K"
String compactCount(int n) {
  if (n < 1000) return '$n';
  final k = (n / 1000).toStringAsFixed(1);
  return '${k.endsWith('.0') ? k.substring(0, k.length - 2) : k}K';
}

class NearbyBeautician {
  final String id;
  final String firstName;
  final String lastName;
  final String? profileImage;
  final String? bio;
  final double distanceKm;
  final List<String> categories;

  // Not supplied by the server yet; the card hides ratings while these are empty.
  final double? rating;
  final int? ratingCount;
  final Map<String, double> categoryRatings;

  const NearbyBeautician({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profileImage,
    this.bio,
    required this.distanceKm,
    this.categories = const [],
    this.rating,
    this.ratingCount,
    this.categoryRatings = const {},
  });

  String get fullName => '$firstName $lastName'.trim();
  String get initial {
    final f = firstName.trim();
    return f.isEmpty ? '?' : f[0].toUpperCase();
  }

  String get distanceLabel {
    if (distanceKm < 1) return 'Less than 1 km away';
    if (distanceKm < 10) return '${distanceKm.toStringAsFixed(1)} km away';
    return '${distanceKm.round()} km away';
  }
}

class NearbyBeauticiansRepository {
  SupabaseClient get _db => Supabase.instance.client;

  /// Ranked by distance (closest first), computed by the server.
  Future<List<NearbyBeautician>> search(
    double lat,
    double lng, {
    String query = '',
    String? category,
  }) async {
    final q = query.trim();
    final res = await _db.rpc('find_nearby_beauticians', params: {
      'p_lat': lat,
      'p_lng': lng,
      'p_query': q.isEmpty ? null : q,
      'p_category': category,
    });
    final rows = (res as List).cast<Map<String, dynamic>>();

    int rank(String n) {
      final i = categoryOrder.indexOf(n);
      return i == -1 ? categoryOrder.length : i;
    }

    return rows.map((r) {
      final cats = List<String>.from((r['categories'] as List?) ?? []);
      cats.sort((a, b) => rank(a).compareTo(rank(b)));
      return NearbyBeautician(
        id: r['beautician_id'] as String,
        firstName: r['first_name'] as String,
        lastName: r['last_name'] as String,
        profileImage: r['profile_image'] as String?,
        bio: r['bio'] as String?,
        distanceKm: (r['distance_km'] as num).toDouble(),
        categories: cats,
      );
    }).toList();
  }
}
