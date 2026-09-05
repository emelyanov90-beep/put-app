import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/app/app.dart';
import 'package:vput/features/onboarding/presentation/welcome_screen.dart';

void main() {
  testWidgets('welcome actions open the expected next flow', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: VputApp()));

    expect(find.byType(WelcomeScreen), findsOneWidget);

    await tester.tap(find.byKey(WelcomeScreen.startButtonKey));
    await tester.pumpAndSettle();

    expect(find.text('Выбор города'), findsNWidgets(2));
  });
}
