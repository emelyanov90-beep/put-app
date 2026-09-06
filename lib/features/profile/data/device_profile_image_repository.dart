import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vput/features/profile/domain/profile_image_repository.dart';
import 'package:vput/features/profile/domain/profile_image_source.dart';

class DeviceProfileImageRepository implements ProfileImageRepository {
  DeviceProfileImageRepository(this._picker);

  final ImagePicker _picker;

  @override
  Future<Uint8List?> pick(ProfileImageSource source) async {
    final image = await _picker.pickImage(
      source: switch (source) {
        ProfileImageSource.camera => ImageSource.camera,
        ProfileImageSource.gallery => ImageSource.gallery,
      },
      imageQuality: 85,
      maxWidth: 1440,
      maxHeight: 1440,
    );

    if (image == null) return null;
    if (await image.length() > 10 * 1024 * 1024) {
      throw const FormatException('Image exceeds 10 MiB');
    }
    final bytes = await image.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    codec.dispose();
    return bytes;
  }
}

final profileImageRepositoryProvider = Provider<ProfileImageRepository>((ref) {
  return DeviceProfileImageRepository(ImagePicker());
});
