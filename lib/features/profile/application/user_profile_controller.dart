import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart';
import 'package:vput/core/api/pocketbase_provider.dart';
import 'package:vput/core/config/app_config.dart';
import 'package:vput/features/auth/application/preview_session_controller.dart';
import 'package:vput/features/profile/application/profile_draft_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/features/profile/data/device_profile_image_repository.dart';
import 'package:vput/features/profile/domain/profile_image_source.dart';
import 'package:vput/features/profile/domain/user_profile.dart';

@immutable
class UserProfileState {
  const UserProfileState({
    required this.profile,
    this.isPickingImage = false,
    this.imageError,
  });

  final UserProfile profile;
  final bool isPickingImage;
  final String? imageError;

  UserProfileState copyWith({
    UserProfile? profile,
    bool? isPickingImage,
    String? imageError,
    bool clearImageError = false,
  }) {
    return UserProfileState(
      profile: profile ?? this.profile,
      isPickingImage: isPickingImage ?? this.isPickingImage,
      imageError: clearImageError ? null : imageError ?? this.imageError,
    );
  }
}

/// Offline preview seed matching the demo account shown in the design mockups.
const _previewProfile = UserProfile(
  name: 'Анастасия',
  phone: '+7 900 123 45 67',
  completedTrips: 120,
  cancelledTrips: 6,
);

class UserProfileController extends Notifier<UserProfileState> {
  var _generation = 0;
  @override
  UserProfileState build() {
    _generation++;
    ref.watch(currentSessionUserIdProvider);
    if (!AppConfig.isPreviewMode) {
      final record = ref.read(pocketBaseProvider).authStore.record;
      if (record != null) {
        return UserProfileState(profile: _fromRecord(record.toJson()));
      }
      return const UserProfileState(
        profile: UserProfile(
          name: '',
          phone: '',
          completedTrips: 0,
          cancelledTrips: 0,
        ),
      );
    }
    return const UserProfileState(profile: _previewProfile);
  }

  UserProfile _fromRecord(Map<String, dynamic> record) => UserProfile(
    name: record['name'] as String? ?? '',
    phone: record['phone'] as String? ?? '',
    completedTrips: 0,
    cancelledTrips: 0,
    ratingAvg: (record['rating_avg'] as num?)?.toDouble(),
    reviewsCount: (record['reviews_count'] as num?)?.toInt() ?? 0,
  );

  void completeRegistration(ProfileDraft draft, String phone) {
    _generation++;
    state = UserProfileState(
      profile: UserProfile(
        name: draft.name.trim(),
        phone: phone,
        avatarBytes: draft.avatarBytes,
        completedTrips: 0,
        cancelledTrips: 0,
      ),
    );
  }

  void usePreviewAccount(String phone) {
    _generation++;
    state = UserProfileState(
      profile: UserProfile(
        name: _previewProfile.name,
        phone: phone,
        completedTrips: _previewProfile.completedTrips,
        cancelledTrips: _previewProfile.cancelledTrips,
      ),
    );
  }

  void loadFromServerRecord(Map<String, dynamic> record) {
    _generation++;
    state = UserProfileState(profile: _fromRecord(record));
  }

  Future<void> updateName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (!AppConfig.isPreviewMode) {
      final client = ref.read(pocketBaseProvider);
      final response = await client.send<Map<String, dynamic>>(
        '/api/app/me',
        method: 'PATCH',
        body: {'name': trimmed},
      );
      final raw = response['user'];
      if (raw is Map) {
        final data = Map<String, dynamic>.from(raw)
          ..['collectionId'] = '_pb_users_auth_'
          ..['collectionName'] = 'users';
        client.authStore.save(
          client.authStore.token,
          RecordModel.fromJson(data),
        );
      }
    }
    state = state.copyWith(profile: state.profile.copyWith(name: trimmed));
  }

  Future<void> pickAvatar(ProfileImageSource source) async {
    if (state.isPickingImage) return;
    final generation = _generation;

    state = state.copyWith(isPickingImage: true, clearImageError: true);
    try {
      final bytes = await ref.read(profileImageRepositoryProvider).pick(source);
      if (!ref.mounted || generation != _generation) return;
      if (bytes != null && !AppConfig.isPreviewMode) {
        await ref
            .read(pocketBaseProvider)
            .send<Map<String, dynamic>>(
              '/api/app/me/avatar',
              method: 'POST',
              files: [
                http.MultipartFile.fromBytes(
                  'avatar',
                  bytes,
                  filename: 'avatar.jpg',
                ),
              ],
            );
      }
      state = state.copyWith(
        profile: bytes == null
            ? state.profile
            : state.profile.copyWith(avatarBytes: bytes),
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

final userProfileProvider =
    NotifierProvider<UserProfileController, UserProfileState>(
      UserProfileController.new,
    );
