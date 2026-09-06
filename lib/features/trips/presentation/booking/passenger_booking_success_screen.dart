import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vput/app/theme/app_colors.dart';

class PassengerBookingSuccessScreen extends StatelessWidget {
  const PassengerBookingSuccessScreen({
    required this.onOrders,
    required this.onChatDriver,
    super.key,
  });

  static const titleKey = Key('passenger_booking_success_title');
  static const ordersButtonKey = Key('passenger_booking_success_orders');
  static const chatButtonKey = Key('passenger_booking_success_chat');

  final VoidCallback onOrders;
  final VoidCallback onChatDriver;

  @override
  Widget build(BuildContext context) {
    const overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(
                height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.divider),
                    ),
                  ),
                  child: SizedBox.expand(),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const _SuccessIcon(),
                      const SizedBox(height: 24),
                      const Text(
                        'Место забронировано',
                        key: titleKey,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.accentBlack,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 343),
                        child: const Text(
                          'Вы успешно забронировали место в поездке. '
                          'Детали маршрута и данные водителя доступны '
                          'в разделе «Мои поездки».',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                            height: 1.33,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          key: ordersButtonKey,
                          onPressed: onOrders,
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
                          child: const Text('Мои поездки'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          key: chatButtonKey,
                          onPressed: onChatDriver,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.brandGreen,
                            side: const BorderSide(color: AppColors.brandGreen),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: const Text('Написать водителю'),
                        ),
                      ),
                    ],
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

class _SuccessIcon extends StatelessWidget {
  const _SuccessIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.brandGreen.withValues(alpha: .14),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.brandGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.accentWhite,
              size: 24,
            ),
          ),
          const Positioned(left: 14, top: 19, child: _Sparkle(size: 12)),
          const Positioned(right: 14, top: 22, child: _Sparkle(size: 9)),
          const Positioned(right: 19, bottom: 17, child: _Sparkle(size: 8)),
          const Positioned(left: 21, bottom: 20, child: _Sparkle(size: 7)),
          const Positioned(left: 34, top: 9, child: _Dot()),
          const Positioned(right: 32, top: 8, child: _Dot()),
          const Positioned(left: 27, bottom: 5, child: _Dot()),
        ],
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.auto_awesome_rounded,
      color: AppColors.brandGreen,
      size: size,
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: 3,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.brandGreen,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
