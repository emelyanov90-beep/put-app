import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/features/profile/application/profile_draft_controller.dart';
import 'package:vput/features/profile/presentation/widgets/photo_source_sheet.dart';

class CreateProfileScreen extends ConsumerStatefulWidget {
  const CreateProfileScreen({required this.onContinue, super.key});

  static const titleKey = Key('create_profile_title');
  static const avatarKey = Key('create_profile_avatar');
  static const editAvatarButtonKey = Key('create_profile_edit_avatar');
  static const nameFieldKey = Key('create_profile_name');
  static const continueButtonKey = Key('create_profile_continue');
  static const photoSheetKey = PhotoSourceSheet.sheetKey;
  static const cameraButtonKey = PhotoSourceSheet.cameraButtonKey;
  static const galleryButtonKey = PhotoSourceSheet.galleryButtonKey;

  final VoidCallback onContinue;

  @override
  ConsumerState<CreateProfileScreen> createState() =>
      _CreateProfileScreenState();
}

class _CreateProfileScreenState extends ConsumerState<CreateProfileScreen> {
  late final TextEditingController _nameController;
  final _nameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: ref.read(profileDraftProvider).name,
    );
    _nameFocusNode.addListener(_rebuild);
  }

  @override
  void dispose() {
    _nameFocusNode
      ..removeListener(_rebuild)
      ..dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  Future<void> _openPhotoSourceSheet() async {
    _nameFocusNode.unfocus();
    final source = await PhotoSourceSheet.show(context);

    if (source == null || !mounted) return;
    await ref.read(profileDraftProvider.notifier).pickAvatar(source);
  }

  void _continue() {
    final draft = ref.read(profileDraftProvider);
    if (!draft.isNameValid || draft.isPickingImage) return;
    _nameFocusNode.unfocus();
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(
      profileDraftProvider.select((draft) => draft.imageError),
      (_, error) {
        if (error == null) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
        Future.microtask(
          ref.read(profileDraftProvider.notifier).clearImageError,
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
    final draft = ref.watch(profileDraftProvider);
    final canContinue = draft.isNameValid && !draft.isPickingImage;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              const _ProfileHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Создайте профиль и найдите подходящую поездку',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          height: 1.33,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: _ProfileAvatar(
                          bytes: draft.avatarBytes,
                          isLoading: draft.isPickingImage,
                          onEdit: _openPhotoSourceSheet,
                        ),
                      ),
                      const SizedBox(height: 48),
                      _NameField(
                        controller: _nameController,
                        focusNode: _nameFocusNode,
                        onChanged: ref
                            .read(profileDraftProvider.notifier)
                            .setName,
                        onSubmitted: (_) => _continue(),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.divider)),
                ),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  height: 48,
                  child: FilledButton(
                    key: CreateProfileScreen.continueButtonKey,
                    onPressed: canContinue ? _continue : null,
                    style: FilledButton.styleFrom(
                      disabledBackgroundColor: AppColors.background,
                      disabledForegroundColor: AppColors.textSecondary,
                      foregroundColor: AppColors.accentWhite,
                      backgroundColor: AppColors.brandGreen,
                      side: BorderSide(
                        color: canContinue
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
                    child: const Text('Далее'),
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          const SizedBox.square(
            dimension: 40,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.badge_outlined,
                color: Color(0xFF898A8D),
                size: 23,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Создайте свой профиль',
              key: CreateProfileScreen.titleKey,
              style: TextStyle(
                color: AppColors.accentBlack,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
        ],
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
      key: CreateProfileScreen.avatarKey,
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
                key: CreateProfileScreen.editAvatarButtonKey,
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
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final floatLabel = focusNode.hasFocus || controller.text.isNotEmpty;

    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: focusNode.hasFocus
                ? AppColors.accentBlack
                : AppColors.divider,
          ),
        ),
      ),
      child: Column(
        mainAxisAlignment: floatLabel
            ? MainAxisAlignment.start
            : MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (floatLabel)
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
            key: CreateProfileScreen.nameFieldKey,
            controller: controller,
            focusNode: focusNode,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            inputFormatters: [LengthLimitingTextInputFormatter(50)],
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            cursorColor: AppColors.brandGreen,
            style: const TextStyle(
              color: AppColors.accentBlack,
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.33,
            ),
            decoration: InputDecoration.collapsed(
              hintText: floatLabel ? null : 'Имя',
              hintStyle: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w400,
                height: 1.33,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
