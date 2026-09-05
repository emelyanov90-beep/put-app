import 'package:flutter/foundation.dart';

/// A single block of a legal document: either a bold section heading or a
/// regular paragraph of body text.
@immutable
class LegalSection {
  const LegalSection.heading(this.text) : isHeading = true;

  const LegalSection.paragraph(this.text) : isHeading = false;

  final String text;
  final bool isHeading;
}
