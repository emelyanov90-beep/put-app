import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vput/app/theme/app_colors.dart';

class OnboardingSlideOneScreen extends StatelessWidget {
  const OnboardingSlideOneScreen({required this.onContinue, super.key});

  static const titleKey = Key('onboarding_slide_one_title');
  static const illustrationKey = Key('onboarding_slide_one_illustration');
  static const descriptionKey = Key('onboarding_slide_one_description');
  static const continueButtonKey = Key('onboarding_slide_one_continue');

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    const overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.accentWhite,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: AppColors.accentWhite,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: AppColors.accentWhite,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 700;
              final topSpacing = compact ? 16.0 : 25.0;
              final titleToImageSpacing = compact ? 16.0 : 25.0;
              final imageToDescriptionSpacing = compact ? 24.0 : 49.0;
              final descriptionToIndicatorSpacing = compact ? 24.0 : 40.0;
              final naturalIllustrationHeight =
                  constraints.maxWidth * 290 / 375;
              final illustrationHeight = compact
                  ? math.min(
                      naturalIllustrationHeight,
                      constraints.maxHeight * 0.33,
                    )
                  : naturalIllustrationHeight;

              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        SizedBox(height: topSpacing),
                        const _WelcomeTitle(key: titleKey),
                        SizedBox(height: titleToImageSpacing),
                        SizedBox(
                          width: illustrationHeight * 375 / 290,
                          height: illustrationHeight,
                          child: Image.asset(
                            'docs/imgs/compas.png',
                            key: illustrationKey,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(height: imageToDescriptionSpacing),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: SizedBox(
                            height: 150,
                            width: double.infinity,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: SizedBox(
                                width: 343,
                                child: Text(
                                  'Находите нужное направление, создавайте поездки\n'
                                  'или бронируйте места,\n'
                                  'экономьте время и деньги',
                                  key: descriptionKey,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.accentBlack,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: descriptionToIndicatorSpacing),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _PageIndicator(),
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: FilledButton(
                              key: continueButtonKey,
                              onPressed: onContinue,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                foregroundColor: AppColors.accentWhite,
                                backgroundColor: AppColors.brandGreen,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  height: 1.38,
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Продолжить'),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WelcomeTitle extends StatelessWidget {
  const _WelcomeTitle({super.key});

  @override
  Widget build(BuildContext context) {
    const titleStyle = TextStyle(
      color: AppColors.accentBlack,
      fontSize: 24,
      fontWeight: FontWeight.w700,
      height: 1.25,
    );

    return const SizedBox(
      width: double.infinity,
      height: 60,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: 343,
            child: Text.rich(
              TextSpan(
                style: titleStyle,
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
          width: 40,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.brandGreen,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 12,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0x33E4E5E6),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ],
    );
  }
}
