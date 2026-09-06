import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/app/widgets/screen_header.dart';
import 'package:vput/features/onboarding/application/onboarding_draft_controller.dart';
import 'package:vput/features/profile/application/user_profile_controller.dart';
import 'package:vput/features/profile/presentation/widgets/photo_source_sheet.dart';

class PersonalDataScreen extends ConsumerStatefulWidget {
  const PersonalDataScreen({
    required this.role,
    required this.onBack,
    required this.onSaved,
    super.key,
  });

  static const avatarKey = Key('personal_data_avatar');
  static const editAvatarButtonKey = Key('personal_data_edit_avatar');
  static const nameFieldKey = Key('personal_data_name');
  static const phoneRowKey = Key('personal_data_phone');
  static const driverPhotoHintKey = Key('personal_data_driver_photo_hint');
  static const saveButtonKey = Key('personal_data_save');
  static const photoSheetKey = PhotoSourceSheet.sheetKey;
  static const cameraButtonKey = PhotoSourceSheet.cameraButtonKey;
  static const galleryButtonKey = PhotoSourceSheet.galleryButtonKey;

  final OnboardingRole? role;
  final VoidCallback onBack;
  final VoidCallback onSaved;

  @override
  ConsumerState<PersonalDataScreen> createState() => _PersonalDataScreenState();
}

class _PersonalDataScreenState extends ConsumerState<PersonalDataScreen> {
  late final TextEditingController _nameController;
  final _nameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: ref.read(userProfileProvider).profile.name,
    );
    _nameFocusNode.addListener(_rebuild);
    _nameController.addListener(_rebuild);
  }

  @override
  void dispose() {
    _nameFocusNode
      ..removeListener(_rebuild)
      ..dispose();
    _nameController
      ..removeListener(_rebuild)
      ..dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  Future<void> _openPhotoSourceSheet() async {
    _nameFocusNode.unfocus();
    final source = await PhotoSourceSheet.show(context);

    if (source == null || !mounted) return;
    await ref.read(userProfileProvider.notifier).pickAvatar(source);
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;
    await ref
        .read(userProfileProvider.notifier)
        .updateName(_nameController.text);
    if (!mounted) return;
    _nameFocusNode.unfocus();
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(
      userProfileProvider.select((state) => state.imageError),
      (_, error) {
        if (error == null) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
        Future.microtask(
          ref.read(userProfileProvider.notifier).clearImageError,
        );
      },
    );

    const overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: AppColors.background,
    );
    final state = ref.watch(userProfileProvider);
    final canSave = _nameController.text.trim().isNotEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              ScreenHeader(
                title: 'Личные данные',
                onBack: widget.onBack,
                trailing: const ScreenHeaderOverflowBadge(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                  child: Column(
                    children: [
                      Center(
                        child: _ProfileAvatar(
                          bytes: state.profile.avatarBytes,
                          isLoading: state.isPickingImage,
                          onEdit: _openPhotoSourceSheet,
                        ),
                      ),
                      if (widget.role == OnboardingRole.driver) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Для водителей обязательно фото лица в анфас. '
                          'Оно проходит проверку у администратора.',
                          key: PersonalDataScreen.driverPhotoHintKey,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            height: 1.38,
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      _NameField(
                        controller: _nameController,
                        focusNode: _nameFocusNode,
                        onSubmitted: (_) => _save(),
                      ),
                      _PhoneRow(phone: state.profile.phone),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    key: PersonalDataScreen.saveButtonKey,
                    onPressed: canSave ? _save : null,
                    style: FilledButton.styleFrom(
                      disabledBackgroundColor: AppColors.background,
                      disabledForegroundColor: AppColors.textSecondary,
                      foregroundColor: AppColors.accentWhite,
                      backgroundColor: AppColors.brandGreen,
                      side: BorderSide(
                        color: canSave
                            ? AppColors.brandGreen
                            : AppColors.divider,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.33,
                      ),
                    ),
                    child: const Text('Сохранить'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.bytes,
    required this.isLoading,
    required this.onEdit,
  });

  final Uint8List? bytes;
  final bool isLoading;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      key: PersonalDataScreen.avatarKey,
      dimension: 104,
      child: Stack(
        children: [
          Positioned(
            left: 4,
            top: 4,
            child: ClipOval(
              child: SizedBox.square(
                dimension: 96,
                child: bytes == null
                    ? const ColoredBox(
                        color: AppColors.accentSurface,
                        child: Icon(
                          Icons.person_rounded,
                          color: Color(0xFF898A8D),
                          size: 54,
                        ),
                      )
                    : Image.memory(bytes!, fit: BoxFit.cover),
              ),
            ),
          ),
          if (isLoading)
            const Positioned(
              left: 4,
              top: 4,
              child: SizedBox.square(
                dimension: 96,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0x660C0C0C),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(
                        color: AppColors.accentWhite,
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            right: 0,
            bottom: 0,
            child: SizedBox.square(
              dimension: 32,
              child: IconButton.filled(
                key: PersonalDataScreen.editAvatarButtonKey,
                onPressed: isLoading ? null : onEdit,
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.brandGreen,
                  disabledBackgroundColor: AppColors.brandGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(
                  Icons.edit_rounded,
                  color: AppColors.accentWhite,
                  size: 17,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: PersonalDataScreen.nameFieldKey,
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Имя',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.33,
            ),
          ),
          TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            inputFormatters: [LengthLimitingTextInputFormatter(50)],
            onSubmitted: onSubmitted,
            cursorColor: AppColors.brandGreen,
            style: const TextStyle(
              color: AppColors.accentBlack,
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.33,
            ),
            decoration: const InputDecoration.collapsed(hintText: null),
          ),
        ],
      ),
    );
  }
}

class _PhoneRow extends StatelessWidget {
  const _PhoneRow({required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: PersonalDataScreen.phoneRowKey,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Номер телефона',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 1.33,
                  ),
                ),
                Text(
                  phone,
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
          const Icon(
            Icons.phone_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ],
      ),
    );
  }
}
