import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/features/profile/data/device_profile_image_repository.dart';
import 'package:vput/features/profile/domain/profile_image_source.dart';

@immutable
class ProfileDraft {
  const ProfileDraft({
    this.name = '',
    this.avatarBytes,
    this.isPickingImage = false,
    this.imageError,
  });

  final String name;
  final Uint8List? avatarBytes;
  final bool isPickingImage;
  final String? imageError;

  bool get isNameValid => name.trim().isNotEmpty;

  ProfileDraft copyWith({
    String? name,
    Uint8List? avatarBytes,
    bool? isPickingImage,
    String? imageError,
    bool clearImageError = false,
  }) {
    return ProfileDraft(
      name: name ?? this.name,
      avatarBytes: avatarBytes ?? this.avatarBytes,
      isPickingImage: isPickingImage ?? this.isPickingImage,
      imageError: clearImageError ? null : imageError ?? this.imageError,
    );
  }
}

class ProfileDraftController extends Notifier<ProfileDraft> {
  var _generation = 0;
  @override
  ProfileDraft build() {
    _generation++;
    return const ProfileDraft();
  }

  void reset() {
    _generation++;
    state = const ProfileDraft();
  }

  void setName(String value) {
    state = state.copyWith(name: value);
  }

  Future<void> pickAvatar(ProfileImageSource source) async {
    if (state.isPickingImage) return;
    final generation = _generation;

    state = state.copyWith(isPickingImage: true, clearImageError: true);
    try {
      final bytes = await ref.read(profileImageRepositoryProvider).pick(source);
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(
        avatarBytes: bytes,
        isPickingImage: false,
        clearImageError: true,
      );
    } catch (_) {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(
        isPickingImage: false,
        imageError: 'Не удалось загрузить фотографию. Попробуйте ещё раз.',
      );
    }
  }

  void clearImageError() {
    if (state.imageError == null) return;
    state = state.copyWith(clearImageError: true);
  }
}

final profileDraftProvider =
    NotifierProvider<ProfileDraftController, ProfileDraft>(
      ProfileDraftController.new,
    );
