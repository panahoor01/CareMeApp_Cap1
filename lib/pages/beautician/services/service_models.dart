const categoryOrder = [
  'Hair',
  'Nails',
  'Makeup',
  'Lashes & Brows',
  'Wax',
  'Footspa',
];

class ServiceCategory {
  final String id; // beautician_service_category_id
  final String name;
  const ServiceCategory({required this.id, required this.name});
}

class ServiceVariant {
  final int? id; // null = not saved yet
  final String name;
  final double addPrice; // 0 = no extra charge
  final int extraMinutes; // 0 = no extra time
  const ServiceVariant({
    this.id,
    required this.name,
    required this.addPrice,
    this.extraMinutes = 0,
  });
}

class ServiceRatingSummary {
  final double? average;
  final int count;

  const ServiceRatingSummary({required this.average, required this.count});
}

class ServiceReview {
  final String id;
  final int rating;
  final String? review;
  final String reviewerName;
  final String? reviewerImage;
  final DateTime createdAt;

  const ServiceReview({
    required this.id,
    required this.rating,
    this.review,
    required this.reviewerName,
    this.reviewerImage,
    required this.createdAt,
  });

  factory ServiceReview.fromRow(Map<String, dynamic> row) => ServiceReview(
        id: row['review_id'].toString(),
        rating: (row['rating'] as num).toInt(),
        review: row['review_text'] as String?,
        reviewerName: row['reviewer_name'] as String,
        reviewerImage: row['reviewer_image'] as String?,
        createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      );
}

class BeauticianService {
  final String id;
  final String categoryId;
  final String title;
  final String? description;
  final List<String> images;
  final double price;
  final int durationMinutes;
  final bool isActive;
  final List<ServiceVariant> variants;

  // Stay null until reviews exist, and the card hides the rating while null.
  final double? rating;
  final int? ratingCount;

  const BeauticianService({
    required this.id,
    required this.categoryId,
    required this.title,
    this.description,
    this.images = const [],
    required this.price,
    required this.durationMinutes,
    this.isActive = true,
    this.variants = const [],
    this.rating,
    this.ratingCount,
  });

  String? get cover => images.isEmpty ? null : images.first;

  BeauticianService withRating(ServiceRatingSummary summary) =>
      BeauticianService(
        id: id,
        categoryId: categoryId,
        title: title,
        description: description,
        images: images,
        price: price,
        durationMinutes: durationMinutes,
        isActive: isActive,
        variants: variants,
        rating: summary.average,
        ratingCount: summary.count,
      );

  /// Base duration plus the longest variant extra time.
  int get maxDurationMinutes =>
      durationMinutes +
      variants.fold<int>(0, (m, v) => v.extraMinutes > m ? v.extraMinutes : m);
}

/// 1500 -> ₱1,500.00
String formatPeso(double v) {
  final parts = v.toStringAsFixed(2).split('.');
  final whole =
      parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  return '₱$whole.${parts[1]}';
}

/// (150, 240) -> "2.5 - 4 hours", (90, 90) -> "1.5 hours", (45, 45) -> "45 min"
String formatDurationRange(int low, int high) {
  bool halfHours(int m) => m >= 60 && m % 30 == 0;
  String hours(int m) {
    final h = m / 60;
    return h == h.truncateToDouble() ? '${h.toInt()}' : h.toStringAsFixed(1);
  }

  String full(int m) {
    if (m < 60) return '$m min';
    if (halfHours(m)) return '${hours(m)} ${m == 60 ? 'hour' : 'hours'}';
    return formatDuration(m);
  }

  if (low == high) return full(low);
  if (halfHours(low) && halfHours(high)) {
    return '${hours(low)} - ${hours(high)} hours';
  }
  return '${full(low)} - ${full(high)}';
}

/// 90 -> 1h 30m, 120 -> 2h, 45 -> 45m
String formatDuration(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '${m}m';
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}
