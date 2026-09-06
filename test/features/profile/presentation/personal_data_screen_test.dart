import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/onboarding/application/onboarding_draft_controller.dart';
import 'package:vput/features/profile/application/user_profile_controller.dart';
import 'package:vput/features/profile/data/device_profile_image_repository.dart';
import 'package:vput/features/profile/domain/profile_image_repository.dart';
import 'package:vput/features/profile/domain/profile_image_source.dart';
import 'package:vput/features/profile/presentation/personal_data_screen.dart';

class _FakeProfileImageRepository implements ProfileImageRepository {
  ProfileImageSource? requestedSource;

  @override
  Future<Uint8List?> pick(ProfileImageSource source) async {
    requestedSource = source;
    return base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+'
      'A8AAQUBAScY42YAAAAASUVORK5CYII=',
    );
  }
}

void main() {
  testWidgets('shows the current name and phone, and saves an edited name', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    var savedTaps = 0;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: PersonalDataScreen(
            role: OnboardingRole.passenger,
            onBack: () {},
            onSaved: () => savedTaps++,
          ),
        ),
      ),
    );

    expect(find.text('Анастасия'), findsOneWidget);
    expect(find.text('+7 900 123 45 67'), findsOneWidget);
    expect(find.byKey(PersonalDataScreen.driverPhotoHintKey), findsNothing);

    await tester.enterText(
      find.byKey(PersonalDataScreen.nameFieldKey),
      'Мария',
    );
    await tester.pump();
    await tester.tap(find.byKey(PersonalDataScreen.saveButtonKey));

    expect(savedTaps, 1);
    expect(container.read(userProfileProvider).profile.name, 'Мария');
  });

  testWidgets('shows the driver photo hint only for the driver role', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: PersonalDataScreen(
            role: OnboardingRole.driver,
            onBack: () {},
            onSaved: () {},
          ),
        ),
      ),
    );

    expect(find.byKey(PersonalDataScreen.driverPhotoHintKey), findsOneWidget);
  });

  testWidgets('blocks saving an empty name', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: PersonalDataScreen(
            role: OnboardingRole.passenger,
            onBack: () {},
            onSaved: () {},
          ),
        ),
      ),
    );

    await tester.enterText(find.byKey(PersonalDataScreen.nameFieldKey), '   ');
    await tester.pump();

    final saveButton = tester.widget<FilledButton>(
      find.byKey(PersonalDataScreen.saveButtonKey),
    );
    expect(saveButton.onPressed, isNull);
  });

  testWidgets('opens photo source sheet and loads a picked avatar', (
    tester,
  ) async {
    final imageRepository = _FakeProfileImageRepository();
    final container = ProviderContainer(
      overrides: [
        profileImageRepositoryProvider.overrideWithValue(imageRepository),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: PersonalDataScreen(
            role: OnboardingRole.passenger,
            onBack: () {},
            onSaved: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(PersonalDataScreen.editAvatarButtonKey));
    await tester.pumpAndSettle();

    expect(find.byKey(PersonalDataScreen.photoSheetKey), findsOneWidget);

    await tester.tap(find.byKey(PersonalDataScreen.galleryButtonKey));
    await tester.pumpAndSettle();

    expect(imageRepository.requestedSource, ProfileImageSource.gallery);
    expect(container.read(userProfileProvider).profile.avatarBytes, isNotNull);
  });
}
