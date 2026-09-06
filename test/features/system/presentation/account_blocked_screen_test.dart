import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/system/presentation/account_blocked_screen.dart';

void main() {
  testWidgets('states the block and offers no way back into the app', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: AccountBlockedScreen()));

    expect(find.byKey(AccountBlockedScreen.titleKey), findsOneWidget);
    expect(find.text('Ваш аккаунт заблокирован'), findsOneWidget);
    expect(
      find.text('Мы ограничили доступ из-за нарушений условий использования'),
      findsOneWidget,
    );
    expect(find.byKey(AccountBlockedScreen.illustrationKey), findsOneWidget);
    expect(find.text('Путь'), findsOneWidget);

    // Terminal state: nothing to tap through to.
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(TextButton), findsNothing);

    final popScope =
        tester
                .widgetList(
                  find.byWidgetPredicate((widget) => widget is PopScope),
                )
                .single
            as PopScope;
    expect(popScope.canPop, isFalse);
  });
}
