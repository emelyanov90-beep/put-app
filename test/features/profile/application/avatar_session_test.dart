import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/profile/application/profile_draft_controller.dart';
import 'package:vput/features/profile/application/user_profile_controller.dart';
import 'package:vput/features/profile/data/device_profile_image_repository.dart';
import 'package:vput/features/profile/domain/profile_image_repository.dart';
import 'package:vput/features/profile/domain/profile_image_source.dart';

class _DelayedImage implements ProfileImageRepository {
  final pending = Completer<Uint8List?>();
  @override
  Future<Uint8List?> pick(ProfileImageSource source) => pending.future;
}

void main() {
  test(
    'late avatar cannot enter a new user session after invalidation',
    () async {
      final image = _DelayedImage();
      final container = ProviderContainer(
        overrides: [profileImageRepositoryProvider.overrideWithValue(image)],
      );
      addTearDown(container.dispose);
      final pending = container
          .read(userProfileProvider.notifier)
          .pickAvatar(ProfileImageSource.gallery);
      container.invalidate(userProfileProvider);
      container.read(userProfileProvider);
      image.pending.complete(Uint8List.fromList([1, 2, 3]));
      await pending;
      expect(container.read(userProfileProvider).profile.avatarBytes, isNull);
      expect(container.read(userProfileProvider).isPickingImage, isFalse);
    },
  );
  for (final invalidate in [false, true]) {
    test(
      'late draft avatar is discarded after ${invalidate ? 'invalidation' : 'reset'}',
      () async {
        final image = _DelayedImage();
        final container = ProviderContainer(
          overrides: [profileImageRepositoryProvider.overrideWithValue(image)],
        );
        addTearDown(container.dispose);
        final controller = container.read(profileDraftProvider.notifier);
        final pending = controller.pickAvatar(ProfileImageSource.gallery);
        if (invalidate) {
          container.invalidate(profileDraftProvider);
          container.read(profileDraftProvider);
        } else {
          controller.reset();
        }
        image.pending.complete(Uint8List.fromList([1, 2, 3]));
        await pending;
        expect(container.read(profileDraftProvider).avatarBytes, isNull);
        expect(container.read(profileDraftProvider).isPickingImage, isFalse);
      },
    );
  }
}
