import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vput/app/theme/app_colors.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    required this.onStart,
    required this.onSignIn,
    super.key,
  });

  static const startButtonKey = Key('welcome_start_button');
  static const signInButtonKey = Key('welcome_sign_in_button');
  static const illustrationKey = Key('welcome_illustration');

  final VoidCallback onStart;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    const overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.brandGreen,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: AppColors.brandGreen,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: AppColors.brandGreen,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final illustrationSize = (constraints.maxHeight - 325).clamp(
                210.0,
                299.0,
              );

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Image.asset(
                      'docs/imgs/autorization.png',
                      key: illustrationKey,
                      width: illustrationSize,
                      height: illustrationSize,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Путь',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.accentWhite,
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        height: 0.88,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Попутчики и посылки по вашему маршруту',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.accentSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        height: 1.33,
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        children: [
                          _WelcomeButton(
                            key: startButtonKey,
                            label: 'Начать',
                            onPressed: onStart,
                          ),
                          const SizedBox(height: 12),
                          _WelcomeButton(
                            key: signInButtonKey,
                            label: 'Уже есть аккаунт',
                            onPressed: onSignIn,
                            outlined: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WelcomeButton extends StatelessWidget {
  const _WelcomeButton({
    required this.label,
    required this.onPressed,
    this.outlined = false,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = outlined
        ? AppColors.accentWhite
        : AppColors.accentBlack;

    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(44)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      foregroundColor: WidgetStatePropertyAll(foregroundColor),
      backgroundColor: WidgetStatePropertyAll(
        outlined ? Colors.transparent : AppColors.accentWhite,
      ),
      overlayColor: WidgetStatePropertyAll(
        foregroundColor.withValues(alpha: 0.08),
      ),
      side: outlined
          ? const WidgetStatePropertyAll(
              BorderSide(color: AppColors.accentWhite),
            )
          : const WidgetStatePropertyAll(BorderSide.none),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.38),
      ),
    );

    return SizedBox(
      width: double.infinity,
      child: outlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: style,
              child: Text(label),
            )
          : FilledButton(
              onPressed: onPressed,
              style: style,
              child: Text(label),
            ),
    );
  }
}
