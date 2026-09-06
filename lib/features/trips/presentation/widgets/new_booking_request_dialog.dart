import 'package:flutter/material.dart';
import 'package:vput/app/theme/app_colors.dart';

/// «Новый отклик» — the driver is told a passenger wants to join and is taken
/// to the decision screen.
class NewBookingRequestDialog extends StatelessWidget {
  const NewBookingRequestDialog({super.key});

  static const dialogKey = Key('new_booking_request_dialog');
  static const openButtonKey = Key('new_booking_request_open');

  /// Resolves to `true` when the driver chooses to open the request.
  static Future<bool> show(BuildContext context) async {
    final opened = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.accentBlack.withValues(alpha: .4),
      builder: (context) => const NewBookingRequestDialog(),
    );
    return opened ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: dialogKey,
      backgroundColor: AppColors.background,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Foundation placeholder: the design shows a map illustration that
            // is not in the repository yet.
            const Center(
              child: Icon(
                Icons.map_rounded,
                size: 64,
                color: AppColors.divider,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Новый отклик',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.accentBlack,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Пассажир хочет присоединиться к вашей поездке. Ожидается ваше '
              'решение.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF95969C),
                fontSize: 15,
                height: 1.33,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: FilledButton(
                key: openButtonKey,
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandGreen,
                  foregroundColor: AppColors.accentWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Перейти к отклику'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
