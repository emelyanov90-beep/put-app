import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/profile/presentation/profile_loading_screen.dart';

void main() {
  testWidgets('shows progress and completes after the configured duration', (
    tester,
  ) async {
    var completions = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: ProfileLoadingScreen(
          duration: const Duration(milliseconds: 100),
          onCompleted: () => completions++,
        ),
      ),
    );

    expect(find.byKey(ProfileLoadingScreen.progressKey), findsOneWidget);
    expect(completions, 0);

    await tester.pump(const Duration(milliseconds: 100));

    expect(completions, 1);
  });
}
