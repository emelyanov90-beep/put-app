import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/complaints/application/complaints_controller.dart';
import 'package:vput/features/complaints/domain/complaint.dart';
import 'package:vput/features/complaints/presentation/complaints_screen.dart';

void main() {
  testWidgets('submits a complaint and shows it in the list', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: ComplaintsScreen(onBack: () {})),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Жалоб пока нет'), findsOneWidget);

    await tester.tap(find.byKey(ComplaintsScreen.createButtonKey));
    await tester.pumpAndSettle();

    final submit = tester.widget<FilledButton>(
      find.byKey(ComplaintsScreen.submitButtonKey),
    );
    expect(submit.onPressed, isNull, reason: 'too short to send');

    await tester.tap(
      find.byKey(ComplaintsScreen.subjectKey(ComplaintSubject.payment)),
    );
    await tester.enterText(
      find.byKey(ComplaintsScreen.textFieldKey),
      'Списание прошло дважды за одно бронирование.',
    );
    await tester.pump();
    await tester.tap(find.byKey(ComplaintsScreen.submitButtonKey));
    await tester.pumpAndSettle();

    final complaints = container.read(complaintsProvider).value!;
    expect(complaints, hasLength(1));
    expect(complaints.single.subject, ComplaintSubject.payment);
    expect(find.text('Оплата'), findsWidgets);
  });
}
