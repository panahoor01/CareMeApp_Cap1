import 'dart:typed_data';

import 'package:flutter_application_practice/pages/beautician/services/service_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ServiceRepository {
  SupabaseClient get _db => Supabase.instance.client;

  Future<List<ServiceCategory>> fetchCategories() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw AuthException('Please log in again.');

    final rows = await _db
        .from('beautician_service_categories')
        .select('beautician_service_category_id, service_category')
        .eq('beautician_id', uid);

    final cats = rows
        .map((r) => ServiceCategory(
              id: r['beautician_service_category_id'] as String,
              name: r['service_category'] as String,
            ))
        .toList();

    int rank(String n) {
      final i = categoryOrder.indexOf(n);
      return i == -1 ? categoryOrder.length : i;
    }

    cats.sort((a, b) => rank(a.name).compareTo(rank(b.name)));
    return cats;
  }

  Future<List<BeauticianService>> fetchServices(
      List<String> categoryIds) async {
    if (categoryIds.isEmpty) return [];

    final rows = await _db
        .from('services')
        .select('service_id, beautician_service_category_id, service_title, '
            'service_description, service_images, service_price, '
            'service_duration_minutes, is_active, '
            'service_variants(service_variant_id, service_variant_name, '
            'service_variant_add_price, service_variant_extra_minute)')
        .inFilter('beautician_service_category_id', categoryIds)
        .order('created_at', ascending: false);

    final ids = rows.map((row) => row['service_id'] as String).toList();
    final ratings = await fetchRatingSummaries(ids);
    return rows.map((row) {
      final service = _fromRow(row);
      return service.withRating(
        ratings[service.id] ??
            const ServiceRatingSummary(average: null, count: 0),
      );
    }).toList();
  }

  Future<Map<String, ServiceRatingSummary>> fetchRatingSummaries(
    List<String> serviceIds,
  ) async {
    if (serviceIds.isEmpty) return {};
    final result = await _db.rpc('get_service_rating_summaries', params: {
      'p_service_ids': serviceIds,
    });
    return {
      for (final raw in (result as List))
        (raw['service_id'] as String): ServiceRatingSummary(
          average: (raw['average_rating'] as num?)?.toDouble(),
          count: (raw['rating_count'] as num?)?.toInt() ?? 0,
        ),
    };
  }

  Future<ServiceRatingSummary> fetchBeauticianRatingSummary(
    String beauticianId,
  ) async {
    final result = await _db.rpc('get_beautician_rating_summary', params: {
      'p_beautician_id': beauticianId,
    });
    final row = Map<String, dynamic>.from(result as Map);
    return ServiceRatingSummary(
      average: (row['average_rating'] as num?)?.toDouble(),
      count: (row['rating_count'] as num?)?.toInt() ?? 0,
    );
  }

  Future<List<ServiceReview>> fetchReviews(String serviceId) async {
    final result = await _db.rpc('get_service_reviews', params: {
      'p_service_id': serviceId,
    });
    return (result as List)
        .map((row) =>
            ServiceReview.fromRow(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<void> submitReview({
    required String bookingId,
    required int rating,
    required String review,
  }) async {
    await _db.rpc('submit_service_review', params: {
      'p_booking_id': bookingId,
      'p_rating': rating,
      'p_review': review,
    });
  }

  BeauticianService _fromRow(Map<String, dynamic> r) {
    final variants = ((r['service_variants'] as List?) ?? [])
        .map((v) => ServiceVariant(
              id: v['service_variant_id'] as int,
              name: v['service_variant_name'] as String,
              addPrice: (v['service_variant_add_price'] as num).toDouble(),
              extraMinutes: (v['service_variant_extra_minute'] as int?) ?? 0,
            ))
        .toList();
    variants.sort((a, b) => a.id!.compareTo(b.id!));

    return BeauticianService(
      id: r['service_id'] as String,
      categoryId: r['beautician_service_category_id'] as String,
      title: r['service_title'] as String,
      description: r['service_description'] as String?,
      images: List<String>.from((r['service_images'] as List?) ?? []),
      price: (r['service_price'] as num).toDouble(),
      durationMinutes: r['service_duration_minutes'] as int,
      isActive: r['is_active'] as bool,
      variants: variants,
    );
  }

  Future<String> uploadImage(
      Uint8List bytes, String contentType, int index) async {
    final uid = _db.auth.currentUser!.id;
    final ext = contentType.contains('png') ? 'png' : 'jpg';
    final path = '$uid/${DateTime.now().microsecondsSinceEpoch}_$index.$ext';
    await _db.storage.from('service-images').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType),
        );
    return _db.storage.from('service-images').getPublicUrl(path);
  }

  Future<void> saveService({
    String? serviceId,
    required String categoryId,
    required String title,
    required String description,
    required List<String> images,
    required double price,
    required int durationMinutes,
    required bool isActive,
    required List<ServiceVariant> variants,
  }) async {
    await _db.rpc('save_service', params: {
      'p_service_id': serviceId,
      'p_category_id': categoryId,
      'p_title': title,
      'p_description': description,
      'p_images': images,
      'p_price': price,
      'p_duration_minutes': durationMinutes,
      'p_is_active': isActive,
      'p_variants': variants
          .map((v) => {
                'service_variant_id': v.id,
                'name': v.name,
                'add_price': v.addPrice,
                'extra_minutes': v.extraMinutes,
              })
          .toList(),
    });
  }

  Future<void> addCategory(String name) async {
    await _db.rpc('add_my_service_category', params: {'p_category': name});
  }

  Future<void> deleteService(String serviceId) async {
    await _db.rpc('delete_service', params: {'p_service_id': serviceId});
  }
}
