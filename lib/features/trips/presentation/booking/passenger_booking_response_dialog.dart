import 'package:flutter/material.dart';
import 'package:vput/app/theme/app_colors.dart';

enum PassengerBookingResponseAction { pay, withdrawRequest }

class PassengerBookingAcceptedDialog extends StatelessWidget {
  const PassengerBookingAcceptedDialog({
    required this.onPay,
    required this.onWithdraw,
    super.key,
  });

  static const payButtonKey = Key('passenger_booking_accepted_pay');
  static const withdrawButtonKey = Key('passenger_booking_accepted_withdraw');

  final VoidCallback onPay;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    return _BookingResponseDialogFrame(
      title: 'Водитель принял заявку',
      message:
          'Водитель подтвердил вашу заявку на поездку. Для завершения '
          'бронирования оплатите поездку.',
      actions: [
        _DialogButton(
          key: payButtonKey,
          label: 'Перейти к оплате',
          filled: true,
          onPressed: onPay,
        ),
        const SizedBox(height: 4),
        _DialogButton(
          key: withdrawButtonKey,
          label: 'Отказаться от заявки',
          onPressed: onWithdraw,
        ),
      ],
    );
  }
}

class PassengerBookingWithdrawDialog extends StatelessWidget {
  const PassengerBookingWithdrawDialog({
    required this.onReturn,
    required this.onConfirm,
    super.key,
  });

  static const returnButtonKey = Key('passenger_booking_withdraw_return');
  static const confirmButtonKey = Key('passenger_booking_withdraw_confirm');

  final VoidCallback onReturn;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return _BookingResponseDialogFrame(
      title: 'Отменить бронирование?',
      message:
          'Водитель уже подтвердил вашу заявку. Вы уверены, что хотите '
          'отказаться от поездки?',
      actions: [
        _DialogButton(
          key: returnButtonKey,
          label: 'Вернуться',
          filled: true,
          onPressed: onReturn,
        ),
        const SizedBox(height: 4),
        _DialogButton(
          key: confirmButtonKey,
          label: 'Отказаться от заявки',
          onPressed: onConfirm,
        ),
      ],
    );
  }
}

class PassengerBookingRejectedDialog extends StatelessWidget {
  const PassengerBookingRejectedDialog({required this.onOk, super.key});

  static const okButtonKey = Key('passenger_booking_rejected_ok');

  final VoidCallback onOk;

  @override
  Widget build(BuildContext context) {
    return _BookingResponseDialogFrame(
      title: 'Водитель отклонил заявку',
      message:
          'К сожалению, водитель отклонил вашу заявку на поездку. '
          'Вы можете выбрать другую поездку или создать собственную.',
      actions: [
        _DialogButton(
          key: okButtonKey,
          label: 'Ок',
          filled: true,
          onPressed: onOk,
        ),
      ],
    );
  }
}

Future<PassengerBookingResponseAction?> showPassengerBookingAcceptedFlow(
  BuildContext context,
) async {
  final action = await showDialog<PassengerBookingResponseAction>(
    context: context,
    barrierDismissible: false,
    barrierColor: AppColors.accentBlack.withValues(alpha: .42),
    builder: (dialogContext) => PassengerBookingAcceptedDialog(
      onPay: () =>
          Navigator.of(dialogContext).pop(PassengerBookingResponseAction.pay),
      onWithdraw: () =>
          Navigator.of(dialogContext)
              .pop(PassengerBookingResponseAction.withdrawRequest),
    ),
  );
  if (action == null || action == PassengerBookingResponseAction.pay) {
    return action;
  }

  if (!context.mounted) {
    return null;
  }
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: AppColors.accentBlack.withValues(alpha: .42),
    builder: (dialogContext) => PassengerBookingWithdrawDialog(
      onReturn: () => Navigator.of(dialogContext).pop(false),
      onConfirm: () => Navigator.of(dialogContext).pop(true),
    ),
  );
  if (confirmed == true) {
    return PassengerBookingResponseAction.withdrawRequest;
  }
  if (confirmed == false && context.mounted) {
    return showPassengerBookingAcceptedFlow(context);
  }
  return null;
}

Future<void> showPassengerBookingRejectedDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: AppColors.accentBlack.withValues(alpha: .42),
    builder: (dialogContext) => PassengerBookingRejectedDialog(
      onOk: () => Navigator.of(dialogContext).pop(),
    ),
  );
}

class _BookingResponseDialogFrame extends StatelessWidget {
  const _BookingResponseDialogFrame({
    required this.title,
    required this.message,
    required this.actions,
  });

  final String title;
  final String message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'docs/imgs/geo.png',
              width: 90,
              height: 80,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.accentBlack,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                height: 1.33,
              ),
            ),
            const SizedBox(height: 16),
            ...actions,
          ],
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.onPressed,
    this.filled = false,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: filled
          ? FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
                foregroundColor: AppColors.accentWhite,
                shape: shape,
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brandGreen,
                side: const BorderSide(color: AppColors.brandGreen),
                shape: shape,
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }
}
