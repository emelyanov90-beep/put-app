import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/auth/domain/russian_phone_formatter.dart';

void main() {
  group('RussianPhoneFormatter', () {
    final formatter = RussianPhoneFormatter();

    TextEditingValue format(String text) => formatter.formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(text: text),
    );

    test('groups digits as +7 XXX XXX XX XX', () {
      expect(format('9123456789').text, '+7 912 345 67 89');
    });

    test('strips a manually typed leading 7 country code', () {
      expect(format('79123456789').text, '+7 912 345 67 89');
    });

    test('strips a manually typed leading 8 trunk prefix', () {
      expect(format('89123456789').text, '+7 912 345 67 89');
    });

    test('ignores non-digit characters', () {
      expect(format('+7 (912) 345-67-89').text, '+7 912 345 67 89');
    });

    test('truncates input beyond 10 national digits', () {
      expect(format('91234567899999').text, '+7 912 345 67 89');
    });

    test('produces an empty value for empty input', () {
      expect(format('').text, '');
    });
  });

  group('RussianPhoneFormatter.nationalDigitsOf', () {
    test('counts digits excluding the 7/8 prefix', () {
      expect(RussianPhoneFormatter.nationalDigitsOf('+7 912 345 67 89'), 10);
      expect(RussianPhoneFormatter.nationalDigitsOf('+7 912 345'), 6);
      expect(RussianPhoneFormatter.nationalDigitsOf(''), 0);
    });
  });
}
