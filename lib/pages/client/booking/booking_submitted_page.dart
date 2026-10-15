import 'package:flutter/material.dart';
import 'package:flutter_application_practice/pages/beautician/services/service_models.dart';
import 'package:flutter_application_practice/screens/signup_screen/signup_widget.dart';

class BookingSummary {
  final String beauticianName;
  final String serviceTitle;
  final String? variantName;
  final int quantity;
  final String dateLabel;
  final String timeSpan;
  final String barangay;
  final double total;

  const BookingSummary({
    required this.beauticianName,
    required this.serviceTitle,
    this.variantName,
    required this.quantity,
    required this.dateLabel,
    required this.timeSpan,
    required this.barangay,
    required this.total,
  });
}

class BookingSubmittedPage extends StatelessWidget {
  final BookingSummary summary;
  const BookingSubmittedPage({super.key, required this.summary});

  void _goHome(BuildContext context) =>
      Navigator.of(context).popUntil((route) => route.isFirst);

  Widget _row(String label, String value, {bool strong = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 92,
              child: Text(label,
                  style:
                      const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: strong ? 17 : 14.5,
                  fontWeight: strong ? FontWeight.bold : FontWeight.w600,
                  color: strong ? const Color(0xFFEF4444) : Colors.black,
                ),
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final service = s.variantName == null
        ? s.serviceTitle
        : '${s.serviceTitle} (${s.variantName})';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goHome(context);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 32),
                        const Icon(Icons.check_circle,
                            size: 84, color: Color(0xFF22C55E)),
                        const SizedBox(height: 16),
                        const Text('Request sent!',
                            style: TextStyle(
                                fontSize: 26, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                          'Your booking request was submitted to ${s.beauticianName}. '
                          "You'll be notified once they respond.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 15,
                              height: 1.45,
                              color: Colors.black87),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFD1D5DB)),
                          ),
                          child: Column(
                            children: [
                              _row('Service', service),
                              _row('Quantity', '${s.quantity}'),
                              _row('Date', s.dateLabel),
                              _row('Time', s.timeSpan),
                              _row('Barangay', s.barangay),
                              const Divider(height: 20),
                              _row('Total', formatPeso(s.total), strong: true),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'The beautician may adjust the estimated time before accepting your request.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12.5, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                ),
                SignupContinueButton(
                  label: 'Back to home',
                  onPressed: () => _goHome(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
