import 'package:flutter/material.dart';
import 'package:vput/app/theme/app_colors.dart';

/// «Пассажир оплатил поездку» — the seat is now taken for good.
class PassengerPaidDialog extends StatelessWidget {
  const PassengerPaidDialog({super.key});

  static const dialogKey = Key('passenger_paid_dialog');
  static const openButtonKey = Key('passenger_paid_open');

  /// Resolves to `true` when the driver chooses to open the trip.
  static Future<bool> show(BuildContext context) async {
    final opened = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.accentBlack.withValues(alpha: .4),
      builder: (context) => const PassengerPaidDialog(),
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
              'Пассажир оплатил поездку',
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
              'Пассажир успешно оплатил поездку. Место в вашей поездке '
              'забронировано.',
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
                child: const Text('Перейти к поездке'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
