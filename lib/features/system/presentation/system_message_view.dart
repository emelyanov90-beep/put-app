import 'package:flutter/material.dart';
import 'package:vput/app/theme/app_colors.dart';

/// Illustration + title + description centered in the available space, with an
/// optional action pinned to the bottom. Shared by the "no internet" and
/// "error" system states.
class SystemMessageView extends StatelessWidget {
  const SystemMessageView({
    required this.assetPath,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  static const imageKey = Key('system_message_image');
  static const actionButtonKey = Key('system_message_action');

  final String assetPath;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    assetPath,
                    key: imageKey,
                    width: 90,
                    height: 80,
                    fit: BoxFit.fill,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.accentBlack,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      height: 1.29,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      height: 1.33,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                key: actionButtonKey,
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  foregroundColor: AppColors.accentWhite,
                  backgroundColor: AppColors.brandGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.33,
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ),
          ),
      ],
    );
  }
}
