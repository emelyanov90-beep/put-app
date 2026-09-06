/// Stub for the `users.is_active = false` check (TZ §26.1) until the real
/// backend verification exists. Signing in with this number lands on the
/// blocked-account screen instead of the app.
const previewBlockedPhone = '+7 900 000 00 00';

/// Compares by digits only, so the check does not depend on how the number was
/// formatted for display.
bool isPreviewBlockedAccount(String phone) {
  return _digitsOf(phone) == _digitsOf(previewBlockedPhone);
}

String _digitsOf(String value) => value.replaceAll(RegExp(r'\D'), '');
