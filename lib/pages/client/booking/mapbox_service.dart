import 'dart:convert';

import 'package:flutter_application_practice/config/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class MapboxPlace {
  final String title;
  final String subtitle;
  final LatLng point;
  const MapboxPlace(
      {required this.title, required this.subtitle, required this.point});
}

class MapboxAddress {
  final String address;
  final String barangay; // '' when Mapbox doesn't know it
  const MapboxAddress({required this.address, required this.barangay});
}

class MapboxService {
  MapboxService._();

  static const _host = 'api.mapbox.com';

  static String get token => AppConfig.mapboxToken;
  static bool get hasToken => token.isNotEmpty && !token.contains('PASTE_YOUR');

  static String get tileUrl =>
      'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token=$token';

  /// Place search, limited to the Philippines and biased toward [near].
  static Future<List<MapboxPlace>> search(String query, {LatLng? near}) async {
    final q = query.trim();
    if (q.length < 3 || !hasToken) return [];

    final uri = Uri.https(_host, '/search/geocode/v6/forward', {
      'q': q,
      'country': 'ph',
      'limit': '6',
      'language': 'en',
      if (near != null) 'proximity': '${near.longitude},${near.latitude}',
      'access_token': token,
    });
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw Exception('Mapbox search failed (${res.statusCode})');
    }
    final features = (jsonDecode(res.body)['features'] as List?) ?? [];
    return features.map((f) {
      final props = (f['properties'] as Map?) ?? {};
      final coords = f['geometry']['coordinates'] as List;
      return MapboxPlace(
        title: (props['name'] ?? '').toString(),
        subtitle: (props['place_formatted'] ?? props['full_address'] ?? '')
            .toString(),
        point: LatLng(
            (coords[1] as num).toDouble(), (coords[0] as num).toDouble()),
      );
    }).toList();
  }

  /// Address text and barangay name for a pinned point (best effort).
  static Future<MapboxAddress> reverse(LatLng p) async {
    if (!hasToken) return const MapboxAddress(address: '', barangay: '');

    Future<List> call(Map<String, String> extra) async {
      final uri = Uri.https(_host, '/search/geocode/v6/reverse', {
        'longitude': p.longitude.toString(),
        'latitude': p.latitude.toString(),
        'country': 'ph',
        'language': 'en',
        'limit': '1',
        ...extra,
        'access_token': token,
      });
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];
      return (jsonDecode(res.body)['features'] as List?) ?? [];
    }

    var address = '';
    var barangay = '';

    final main = await call({});
    if (main.isNotEmpty) {
      final props = (main.first['properties'] as Map?) ?? {};
      address = (props['full_address'] ??
              props['place_formatted'] ??
              props['name'] ??
              '')
          .toString();
      final ctx = (props['context'] as Map?) ?? {};
      barangay = _name(ctx['locality']) ?? _name(ctx['neighborhood']) ?? '';
    }

    if (barangay.isEmpty) {
      final areas = await call({'types': 'locality,neighborhood'});
      if (areas.isNotEmpty) {
        barangay =
            ((areas.first['properties'] as Map?)?['name'] ?? '').toString();
      }
    }
    return MapboxAddress(address: address, barangay: barangay.trim());
  }

  static String? _name(dynamic v) {
    if (v is Map) {
      final n = v['name']?.toString().trim();
      if (n != null && n.isNotEmpty) return n;
    }
    return null;
  }
}
