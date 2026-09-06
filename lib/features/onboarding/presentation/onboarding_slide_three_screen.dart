import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vput/app/theme/app_colors.dart';

class OnboardingSlideThreeScreen extends StatelessWidget {
  const OnboardingSlideThreeScreen({
    required this.onDriverSelected,
    required this.onPassengerSelected,
    super.key,
  });

  static const headerKey = Key('onboarding_slide_three_header');
  static const logoKey = Key('onboarding_slide_three_logo');
  static const illustrationKey = Key('onboarding_slide_three_illustration');
  static const cardKey = Key('onboarding_slide_three_card');
  static const titleKey = Key('onboarding_slide_three_title');
  static const descriptionKey = Key('onboarding_slide_three_description');
  static const driverButtonKey = Key('onboarding_slide_three_driver');
  static const passengerButtonKey = Key('onboarding_slide_three_passenger');

  final VoidCallback onDriverSelected;
  final VoidCallback onPassengerSelected;

  @override
  Widget build(BuildContext context) {
    const overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarColor: Color(0xFFEDEDED),
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Color(0xFFEDEDED),
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
            final contentHeight = 336 * scale + bottomInset;
            final preferredCardTop = 455 * scale;
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
                  top: 143 * scale,
                  width: artboardWidth,
                  height: 274 * scale,
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
                  child: _RoleSelectionCard(
                    scale: scale,
                    bottomInset: bottomInset,
                    onDriverSelected: onDriverSelected,
                    onPassengerSelected: onPassengerSelected,
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

class _RoleSelectionCard extends StatelessWidget {
  const _RoleSelectionCard({
    required this.scale,
    required this.bottomInset,
    required this.onDriverSelected,
    required this.onPassengerSelected,
  });

  final double scale;
  final double bottomInset;
  final VoidCallback onDriverSelected;
  final VoidCallback onPassengerSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFEDEDED),
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
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 68 * scale,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: 343,
                        child: Text.rich(
                          key: OnboardingSlideThreeScreen.titleKey,
                          const TextSpan(
                            style: TextStyle(
                              color: AppColors.accentBlack,
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
                    height: 48 * scale,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: 343,
                        child: Text(
                          'Кем вы будете\nв этой поездке?',
                          key: OnboardingSlideThreeScreen.descriptionKey,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.accentBlack,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: EdgeInsets.fromLTRB(
                0,
                16 * scale,
                0,
                16 * scale + bottomInset,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RoleButton(
                    key: OnboardingSlideThreeScreen.driverButtonKey,
                    scale: scale,
                    label: 'Водитель',
                    assetPath: 'docs/imgs/driver.png',
                    backgroundColor: AppColors.brandGreen,
                    foregroundColor: AppColors.accentSurface,
                    imageWidth: 75,
                    imageHeight: 63,
                    imageTop: 9,
                    onTap: onDriverSelected,
                  ),
                  SizedBox(width: 9 * scale),
                  _RoleButton(
                    key: OnboardingSlideThreeScreen.passengerButtonKey,
                    scale: scale,
                    label: 'Пассажир',
                    assetPath: 'docs/imgs/passagire.png',
                    backgroundColor: const Color(0xFFF6F6F6),
                    foregroundColor: AppColors.accentBlack,
                    imageWidth: 80,
                    imageHeight: 77,
                    imageTop: 1,
                    onTap: onPassengerSelected,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  const _RoleButton({
    required this.scale,
    required this.label,
    required this.assetPath,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.imageWidth,
    required this.imageHeight,
    required this.imageTop,
    required this.onTap,
    super.key,
  });

  final double scale;
  final String label;
  final String assetPath;
  final Color backgroundColor;
  final Color foregroundColor;
  final double imageWidth;
  final double imageHeight;
  final double imageTop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        width: 167 * scale,
        height: 132 * scale,
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12 * scale),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.all(12 * scale),
              child: Column(
                children: [
                  SizedBox(
                    width: 80 * scale,
                    height: 80 * scale,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: AppColors.accentWhite,
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          Positioned(
                            top: imageTop * scale,
                            width: imageWidth * scale,
                            height: imageHeight * scale,
                            child: Image.asset(assetPath, fit: BoxFit.contain),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 4 * scale),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: foregroundColor,
                          fontSize: 20 * scale,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
