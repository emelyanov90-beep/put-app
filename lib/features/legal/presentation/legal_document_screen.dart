import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/app/widgets/screen_header.dart';
import 'package:vput/features/legal/domain/legal_section.dart';

/// Displays a scrollable legal document (terms of service, privacy policy).
///
/// When [onAccept] is provided, a fixed "Принимаю" button is shown at the
/// bottom and must be tapped to proceed — used when acceptance is required
/// before continuing a flow. When it is null, the screen is read-only and
/// only offers the back button.
class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    required this.title,
    required this.sections,
    required this.onBack,
    this.onAccept,
    super.key,
  });

  static const backButtonKey = ScreenHeader.backButtonKey;
  static const acceptButtonKey = Key('legal_document_accept');

  final String title;
  final List<LegalSection> sections;
  final VoidCallback onBack;
  final VoidCallback? onAccept;

  @override
  Widget build(BuildContext context) {
    const overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: AppColors.background,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              ScreenHeader(title: title, onBack: onBack),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Text.rich(TextSpan(children: _buildSpans(sections))),
                ),
              ),
              if (onAccept != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      key: acceptButtonKey,
                      onPressed: onAccept,
                      style: FilledButton.styleFrom(
                        foregroundColor: AppColors.accentWhite,
                        backgroundColor: AppColors.brandGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.33,
                        ),
                      ),
                      child: const Text('Принимаю'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static List<InlineSpan> _buildSpans(List<LegalSection> sections) {
    final spans = <InlineSpan>[];
    for (var i = 0; i < sections.length; i++) {
      final section = sections[i];
      spans.add(
        TextSpan(
          text: section.text,
          style: TextStyle(
            color: AppColors.accentBlack,
            fontSize: 15,
            fontWeight: section.isHeading ? FontWeight.w700 : FontWeight.w400,
            height: 1.33,
          ),
        ),
      );
      if (i != sections.length - 1) {
        spans.add(const TextSpan(text: '\n\n'));
      }
    }
    return spans;
  }
}
