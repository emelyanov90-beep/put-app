import 'package:flutter/material.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/features/profile/domain/profile_image_source.dart';

/// Bottom sheet letting the user pick a new avatar from the camera or the
/// gallery. Shared by every screen that lets the user edit their photo.
class PhotoSourceSheet extends StatelessWidget {
  const PhotoSourceSheet({super.key});

  static const sheetKey = Key('photo_source_sheet');
  static const cameraButtonKey = Key('photo_source_camera');
  static const galleryButtonKey = Key('photo_source_gallery');

  static Future<ProfileImageSource?> show(BuildContext context) {
    return showModalBottomSheet<ProfileImageSource>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x660C0C0C),
      builder: (_) => const PhotoSourceSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      key: sheetKey,
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFCACBCE),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Загрузка фотографии',
            style: TextStyle(
              color: AppColors.accentBlack,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _PhotoSourceButton(
                  key: cameraButtonKey,
                  icon: Icons.photo_camera_rounded,
                  label: 'Камера',
                  onTap: () =>
                      Navigator.of(context).pop(ProfileImageSource.camera),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PhotoSourceButton(
                  key: galleryButtonKey,
                  icon: Icons.photo_library_rounded,
                  label: 'Галерея',
                  onTap: () =>
                      Navigator.of(context).pop(ProfileImageSource.gallery),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhotoSourceButton extends StatelessWidget {
  const _PhotoSourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accentWhite,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.brandGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.accentWhite, size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.accentBlack,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  height: 1.33,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
