import 'package:flutter/material.dart';
import 'package:flutter_application_practice/pages/beautician/services/service_models.dart';
import 'package:flutter_application_practice/pages/bookings/booking_models.dart';

class BookingCard extends StatelessWidget {
  final BookingItem booking;
  final bool isBeautician;
  final VoidCallback onTap;

  const BookingCard({
    super.key,
    required this.booking,
    required this.isBeautician,
    required this.onTap,
  });

  Widget _image() {
    final url = booking.serviceImage;
    final placeholder = Container(
      color: const Color(0xFFF3F4F6),
      child: const Center(
        child: Icon(Icons.spa_outlined, size: 32, color: Color(0xFF9CA3AF)),
      ),
    );
    if (url == null || url.isEmpty) return placeholder;
    return Image.network(url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => placeholder);
  }

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final color = b.status.color;
    final topRight = b.status.isInProgress
        ? b.status.label
        : '${dateShort(b.date)} • ${timeLabel(b.startMinutes)}';
    final showDot =
        isBeautician && !b.seen && b.status == BookingStatus.pending;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: color, width: 1.5),
        ),
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 120,
            child: Row(
              children: [
                SizedBox(width: 108, child: _image()),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                b.serviceTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (showDot)
                              Container(
                                width: 9,
                                height: 9,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            Text(topRight,
                                style: TextStyle(fontSize: 11.5, color: color)),
                            const SizedBox(width: 3),
                            Icon(b.status.icon, size: 15, color: color),
                          ],
                        ),
                        if (b.variantName != null)
                          Text('• ${b.variantName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF4B5563))),
                        Text(
                          '${b.otherName} • ${isBeautician ? 'client' : 'beautician'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF4B5563)),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Text('×${b.quantity}',
                                style: const TextStyle(fontSize: 12)),
                            const Spacer(),
                            Text(formatPeso(b.unitPrice),
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Total: ${formatPeso(b.totalPrice)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
