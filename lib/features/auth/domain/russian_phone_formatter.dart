import 'package:flutter/services.dart';

/// Formats input into a `+7 XXX XXX XX XX` Russian phone number as the user
/// types. A manually typed leading `7` (country code) or `8` (the common
/// domestic trunk prefix) is stripped, since Russian mobile numbers always
/// start with `9` right after the country code.
class RussianPhoneFormatter extends TextInputFormatter {
  static const _groupLengths = [3, 3, 2, 2];
  static const nationalDigitCount = 10;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = _nationalDigits(newValue.text);

    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final buffer = StringBuffer('+7 ');
    var consumed = 0;
    for (var i = 0; i < _groupLengths.length && consumed < digits.length; i++) {
      if (i > 0) buffer.write(' ');
      final end = (consumed + _groupLengths[i]).clamp(0, digits.length);
      buffer.write(digits.substring(consumed, end));
      consumed = end;
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// Number of national digits (after the `7`/`8` country/trunk prefix) in
  /// [text].
  static int nationalDigitsOf(String text) => _nationalDigits(text).length;

  static String _nationalDigits(String text) {
    var digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('7') || digits.startsWith('8')) {
      digits = digits.substring(1);
    }
    if (digits.length > nationalDigitCount) {
      digits = digits.substring(0, nationalDigitCount);
    }
    return digits;
  }
}
