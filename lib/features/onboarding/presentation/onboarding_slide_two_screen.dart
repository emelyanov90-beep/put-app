import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vput/app/theme/app_colors.dart';

class OnboardingSlideTwoScreen extends StatelessWidget {
  const OnboardingSlideTwoScreen({required this.onContinue, super.key});

  static const headerKey = Key('onboarding_slide_two_header');
  static const logoKey = Key('onboarding_slide_two_logo');
  static const illustrationKey = Key('onboarding_slide_two_illustration');
  static const cardKey = Key('onboarding_slide_two_card');
  static const titleKey = Key('onboarding_slide_two_title');
  static const descriptionKey = Key('onboarding_slide_two_description');
  static const continueButtonKey = Key('onboarding_slide_two_continue');

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    const overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarColor: AppColors.accentBlack,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: AppColors.accentBlack,
      systemNavigationBarContrastEnforced: false,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: AppColors.accentWhite,
        body: LayoutBuilder(
          builder: (context, constraints) {
            const referenceWidth = 375.0;
            final scale = (constraints.maxWidth / referenceWidth)
                .clamp(0.85, 1.15)
                .toDouble();
            final artboardWidth = referenceWidth * scale;
            final artboardLeft = (constraints.maxWidth - artboardWidth) / 2;
            final bottomInset = MediaQuery.paddingOf(context).bottom;
            final contentHeight = 334 * scale + bottomInset;
            final preferredCardTop = 457 * scale;
            final cardTop = math.min(
              preferredCardTop,
              math.max(0.0, constraints.maxHeight - contentHeight),
            );

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  key: headerKey,
                  left: 0,
                  top: 0,
                  right: 0,
                  height: 222 * scale,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.brandGreen,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24 * scale),
                        bottomRight: Radius.circular(24 * scale),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: artboardLeft + 132 * scale,
                  top: 60 * scale,
                  width: 50 * scale,
                  height: 50 * scale,
                  child: Image.asset(
                    'docs/imgs/autorization.png',
                    key: logoKey,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  left: artboardLeft + 192 * scale,
                  top: 70 * scale,
                  width: 90 * scale,
                  height: 34 * scale,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Путь',
                      style: TextStyle(
                        color: AppColors.accentSurface,
                        fontSize: 24 * scale,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: artboardLeft,
                  top: 145 * scale,
                  width: artboardWidth,
                  height: 273 * scale,
                  child: Image.asset(
                    'docs/imgs/car.png',
                    key: illustrationKey,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  key: cardKey,
                  left: 0,
                  top: cardTop,
                  right: 0,
                  bottom: 0,
                  child: _RegistrationCard(
                    scale: scale,
                    bottomInset: bottomInset,
                    onContinue: onContinue,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RegistrationCard extends StatelessWidget {
  const _RegistrationCard({
    required this.scale,
    required this.bottomInset,
    required this.onContinue,
  });

  final double scale;
  final double bottomInset;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.accentBlack,
        border: Border.all(width: 3, color: const Color(0xFFF6F6F7)),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24 * scale),
          topRight: Radius.circular(24 * scale),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(21 * scale),
          topRight: Radius.circular(21 * scale),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                16 * scale,
                32 * scale,
                16 * scale,
                16 * scale,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 68 * scale,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: 343,
                        child: Text.rich(
                          key: OnboardingSlideTwoScreen.titleKey,
                          const TextSpan(
                            style: TextStyle(
                              color: AppColors.accentWhite,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              height: 1.21,
                            ),
                            children: [
                              TextSpan(text: 'Добро пожаловать\nв '),
                              TextSpan(
                                text: 'Путь',
                                style: TextStyle(color: AppColors.brandGreen),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8 * scale),
                  SizedBox(
                    width: double.infinity,
                    height: 120 * scale,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: 343,
                        child: Text(
                          'Зарегистрируйтесь,\n'
                          'чтобы начать\n'
                          'пользоваться\n'
                          'приложением.',
                          key: OnboardingSlideTwoScreen.descriptionKey,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.accentWhite,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8 * scale),
                  const _PageIndicator(),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: EdgeInsets.fromLTRB(
                16 * scale,
                16 * scale,
                16 * scale,
                16 * scale + bottomInset,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 42 * scale,
                child: FilledButton(
                  key: OnboardingSlideTwoScreen.continueButtonKey,
                  onPressed: onContinue,
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                    foregroundColor: AppColors.accentWhite,
                    backgroundColor: AppColors.brandGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12 * scale),
                    ),
                    textStyle: TextStyle(
                      fontSize: 13 * scale,
                      fontWeight: FontWeight.w600,
                      height: 1.38,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Продолжить'),
                      Icon(Icons.arrow_forward_ios_rounded, size: 14 * scale),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0x33E4E5E6),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 40,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.brandGreen,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ],
    );
  }
}
