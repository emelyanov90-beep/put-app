import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/notifications/application/notifications_controller.dart';
import 'package:vput/features/notifications/presentation/notifications_screen.dart';

void main() {
  testWidgets('lists notifications and marks them read', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: NotificationsScreen(onBack: () {})),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Уведомления'), findsOneWidget);
    expect(find.text('Заявка одобрена'), findsOneWidget);
    expect(container.read(unreadNotificationsProvider), 1);

    await tester.tap(find.byKey(NotificationsScreen.markAllReadKey));
    await tester.pumpAndSettle();

    expect(container.read(unreadNotificationsProvider), 0);
    final button = tester.widget<FilledButton>(
      find.byKey(NotificationsScreen.markAllReadKey),
    );
    expect(button.onPressed, isNull);
  });
}
