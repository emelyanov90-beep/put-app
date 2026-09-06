import 'dart:typed_data';

import 'package:vput/features/profile/domain/profile_image_source.dart';

abstract interface class ProfileImageRepository {
  Future<Uint8List?> pick(ProfileImageSource source);
}
