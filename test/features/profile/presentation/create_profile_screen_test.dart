import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/profile/application/profile_draft_controller.dart';
import 'package:vput/features/profile/data/device_profile_image_repository.dart';
import 'package:vput/features/profile/domain/profile_image_repository.dart';
import 'package:vput/features/profile/domain/profile_image_source.dart';
import 'package:vput/features/profile/presentation/create_profile_screen.dart';

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
  testWidgets('requires a name but keeps the avatar optional', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var continueTaps = 0;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: CreateProfileScreen(onContinue: () => continueTaps++),
        ),
      ),
    );

    FilledButton continueButton() =>
        tester.widget(find.byKey(CreateProfileScreen.continueButtonKey));

    expect(continueButton().onPressed, isNull);

    await tester.enterText(find.byKey(CreateProfileScreen.nameFieldKey), '   ');
    await tester.pump();
    expect(continueButton().onPressed, isNull);

    await tester.enterText(
      find.byKey(CreateProfileScreen.nameFieldKey),
      'Анастасия',
    );
    await tester.pump();
    expect(continueButton().onPressed, isNotNull);

    await tester.tap(find.byKey(CreateProfileScreen.continueButtonKey));
    expect(continueTaps, 1);
  });

  testWidgets('opens photo source sheet and loads a gallery image', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
        child: MaterialApp(home: CreateProfileScreen(onContinue: () {})),
      ),
    );

    await tester.tap(find.byKey(CreateProfileScreen.editAvatarButtonKey));
    await tester.pumpAndSettle();

    expect(find.byKey(CreateProfileScreen.photoSheetKey), findsOneWidget);
    expect(find.text('Загрузка фотографии'), findsOneWidget);

    await tester.tap(find.byKey(CreateProfileScreen.galleryButtonKey));
    await tester.pumpAndSettle();

    expect(imageRepository.requestedSource, ProfileImageSource.gallery);
    expect(container.read(profileDraftProvider).avatarBytes, isNotNull);
    expect(find.byKey(CreateProfileScreen.photoSheetKey), findsNothing);
  });
}
