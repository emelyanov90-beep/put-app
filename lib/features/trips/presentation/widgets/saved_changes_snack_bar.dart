import 'package:flutter/material.dart';
import 'package:vput/app/theme/app_colors.dart';

const savedChangesSnackBarKey = Key('saved_changes_snack_bar');
const savedChangesCloseKey = Key('saved_changes_close');

/// Green confirmation of the design: a check mark, the message and a close
/// button, floating above the content.
void showSavedChangesSnackBar(
  BuildContext context, {
  String message = 'Изменения сохранены',
}) {
  final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      key: savedChangesSnackBarKey,
      backgroundColor: AppColors.brandGreen,
      behavior: SnackBarBehavior.floating,
      elevation: 8,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.only(left: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
      content: SizedBox(
        height: 48,
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 20,
              color: AppColors.accentWhite,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.accentWhite,
                  fontSize: 13,
                  height: 1.38,
                ),
              ),
            ),
            SizedBox.square(
              dimension: 48,
              child: IconButton(
                key: savedChangesCloseKey,
                onPressed: messenger.hideCurrentSnackBar,
                padding: EdgeInsets.zero,
                tooltip: 'Закрыть',
                icon: const Icon(
                  Icons.close_rounded,
                  size: 24,
                  color: AppColors.accentWhite,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
