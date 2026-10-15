class PhoneUtils {
  PhoneUtils._();

  static final _mobile = RegExp(r'^(?:\+?63|0)?9\d{9}$');

  static bool isValid(String input) =>
      _mobile.hasMatch(input.replaceAll(RegExp(r'[\s\-()]'), ''));

  /// "0912 345 6789" / "9123456789" / "+639123456789" -> "+639123456789"
  static String normalize(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    final local = digits.startsWith('63')
        ? digits.substring(2)
        : digits.startsWith('0')
            ? digits.substring(1)
            : digits;
    return '+63$local';
  }
}
