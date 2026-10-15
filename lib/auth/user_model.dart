import 'package:flutter/material.dart';

/// A single availability slot used by beauticians,
/// e.g. "MON 7:00 AM to 12:00 AM".
class AvailabilitySlot {
  String day;
  TimeOfDay? from;
  TimeOfDay? to;

  AvailabilitySlot({this.day = 'MON', this.from, this.to});
}

class UserModel {
  // Role: "client" or "beautician"
  String? role;

  // Name
  String? firstName;
  String? lastName;

  // Birthday
  DateTime? birthdayDate;
  String? birthday; // formatted display string, e.g. "November 22, 2002"

  // Gender
  String? gender; // "Male" | "Female" | "Others"

  // Contact
  String? phone;

  // Password (in a real app never keep the plaintext around longer than
  // needed to submit it to your auth backend)
  String? password;

  // Beautician-only professional details
  List<String> services = [];
  List<AvailabilitySlot> availability = [];
  String about = '';

  bool get isBeautician => role == 'beautician';
  bool get isClient => role == 'client';

  String get fullName => [firstName, lastName]
      .where((s) => s != null && s.trim().isNotEmpty)
      .join(' ');
}
