import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/auth/data/preview_blocked_account.dart';

void main() {
  group('isPreviewBlockedAccount', () {
    test('matches the blocked number regardless of formatting', () {
      expect(isPreviewBlockedAccount(previewBlockedPhone), isTrue);
      expect(isPreviewBlockedAccount('+79000000000'), isTrue);
      expect(isPreviewBlockedAccount('+7 (900) 000-00-00'), isTrue);
    });

    test('leaves every other number alone', () {
      expect(isPreviewBlockedAccount('+7 912 345 67 89'), isFalse);
      expect(isPreviewBlockedAccount(''), isFalse);
    });
  });
}
