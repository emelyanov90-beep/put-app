import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/features/trips/domain/passenger_order.dart';

class PassengerBookingCancellationResultScreen extends StatelessWidget {
  const PassengerBookingCancellationResultScreen({
    required this.outcome,
    required this.onDone,
    this.refundAmountRubles = 0,
    super.key,
  });

  static const titleKey = Key('passenger_booking_cancel_result_title');
  static const doneButtonKey = Key('passenger_booking_cancel_result_done');
  static const warningCardKey = Key('passenger_booking_cancel_warning');

  final PassengerCancellationOutcome outcome;
  final int refundAmountRubles;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    const overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    );
    final blocked = outcome == PassengerCancellationOutcome.bookingBlocked;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ResultIcon(blocked: blocked),
                      const SizedBox(height: 24),
                      Text(
                        blocked
                            ? 'Бронирование временно\nнедоступно'
                            : 'Бронь отменена',
                        key: titleKey,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.accentBlack,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          height: 1.18,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        blocked
                            ? 'Вы отменили две поездки за последние 30 дней. '
                                  'Новые бронирования недоступны до решения администратора.'
                            : 'Заявка на возврат $refundAmountRubles ₽ '
                                  'отправлена администратору. Это тестовый возврат, '
                                  'реальное движение денег не выполняется.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                          height: 1.33,
                        ),
                      ),
                      if (blocked) ...[
                        const SizedBox(height: 18),
                        Container(
                          key: warningCardKey,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF9E8),
                            border: Border.all(color: const Color(0xFFEAB308)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.error_rounded,
                                color: Color(0xFFE0A800),
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Информация о блокировке передана '
                                  'администратору приложения',
                                  style: TextStyle(
                                    color: AppColors.accentBlack,
                                    fontSize: 15,
                                    height: 1.33,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        key: doneButtonKey,
                        onPressed: onDone,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brandGreen,
                          foregroundColor: AppColors.accentWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          blocked ? 'Понятно' : 'На главную',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultIcon extends StatelessWidget {
  const _ResultIcon({required this.blocked});

  final bool blocked;

  @override
  Widget build(BuildContext context) {
    final color = blocked ? const Color(0xFFEB4245) : AppColors.brandGreen;
    final icon = blocked ? Icons.close_rounded : Icons.check_rounded;
    return SizedBox.square(
      dimension: 82,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.accentWhite, size: 24),
          ),
          Positioned(top: 8, left: 18, child: _Sparkle(color: color, size: 4)),
          Positioned(
            top: 12,
            right: 10,
            child: _Sparkle(color: color, size: 5),
          ),
          Positioned(
            bottom: 10,
            left: 14,
            child: _Sparkle(color: color, size: 3),
          ),
          Positioned(
            bottom: 18,
            right: 18,
            child: _Sparkle(color: color, size: 4),
          ),
        ],
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.auto_awesome_rounded, color: color, size: size * 3);
  }
}
