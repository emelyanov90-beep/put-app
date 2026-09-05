import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/legal/domain/legal_section.dart';
import 'package:vput/features/legal/presentation/legal_document_screen.dart';

void main() {
  const sections = [
    LegalSection.heading('1. Заголовок'),
    LegalSection.paragraph('Текст первого раздела.'),
  ];

  testWidgets('read-only mode has no accept button and the back arrow works', (
    tester,
  ) async {
    var backTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: LegalDocumentScreen(
          title: 'Условия использования',
          sections: sections,
          onBack: () => backTaps++,
        ),
      ),
    );

    expect(find.text('Условия использования'), findsOneWidget);
    expect(find.textContaining('1. Заголовок'), findsOneWidget);
    expect(find.textContaining('Текст первого раздела.'), findsOneWidget);
    expect(find.byKey(LegalDocumentScreen.acceptButtonKey), findsNothing);

    await tester.tap(find.byKey(LegalDocumentScreen.backButtonKey));
    expect(backTaps, 1);
  });

  testWidgets('shows an accept button that triggers onAccept when provided', (
    tester,
  ) async {
    var acceptTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: LegalDocumentScreen(
          title: 'Условия использования',
          sections: sections,
          onBack: () {},
          onAccept: () => acceptTaps++,
        ),
      ),
    );

    expect(find.byKey(LegalDocumentScreen.acceptButtonKey), findsOneWidget);

    await tester.tap(find.byKey(LegalDocumentScreen.acceptButtonKey));
    expect(acceptTaps, 1);
  });
}
