import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/features/auth/domain/russian_phone_formatter.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({
    required this.onCodeRequested,
    required this.onOpenTermsOfService,
    required this.onOpenPrivacyPolicy,
    super.key,
  });

  static const titleKey = Key('phone_auth_title');
  static const descriptionKey = Key('phone_auth_description');
  static const phoneFieldKey = Key('phone_auth_phone_field');
  static const getCodeButtonKey = Key('phone_auth_get_code');

  final ValueChanged<String> onCodeRequested;
  final VoidCallback onOpenTermsOfService;
  final VoidCallback onOpenPrivacyPolicy;

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  late final _termsRecognizer = TapGestureRecognizer()
    ..onTap = widget.onOpenTermsOfService;
  late final _privacyRecognizer = TapGestureRecognizer()
    ..onTap = widget.onOpenPrivacyPolicy;

  @override
  void initState() {
    super.initState();
    _phoneFocusNode.addListener(_handleFocusChange);
    _phoneController.addListener(_handleTextChange);
  }

  @override
  void dispose() {
    _phoneFocusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _phoneController
      ..removeListener(_handleTextChange)
      ..dispose();
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) setState(() {});
  }

  void _handleTextChange() {
    if (mounted) setState(() {});
  }

  bool get _isPhoneComplete =>
      RussianPhoneFormatter.nationalDigitsOf(_phoneController.text) ==
      RussianPhoneFormatter.nationalDigitCount;

  void _submit() {
    if (!_isPhoneComplete) return;
    _phoneFocusNode.unfocus();
    widget.onCodeRequested(_phoneController.text);
  }

  @override
  Widget build(BuildContext context) {
    const overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: AppColors.background,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          'Добро пожаловать в «Путь»!',
                          key: PhoneAuthScreen.titleKey,
                          style: TextStyle(
                            color: AppColors.accentBlack,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Находите выгодные поездки и договаривайтесь на своих условиях',
                          key: PhoneAuthScreen.descriptionKey,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            height: 1.33,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _PhoneField(
                          controller: _phoneController,
                          focusNode: _phoneFocusNode,
                          onSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Мы отправим вам СМС с кодом для входа в приложение',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            height: 1.33,
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _TermsText(
                            termsRecognizer: _termsRecognizer,
                            privacyRecognizer: _privacyRecognizer,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: FilledButton(
                              key: PhoneAuthScreen.getCodeButtonKey,
                              onPressed: _isPhoneComplete ? _submit : null,
                              style: FilledButton.styleFrom(
                                disabledBackgroundColor: AppColors.background,
                                disabledForegroundColor:
                                    AppColors.textSecondary,
                                foregroundColor: AppColors.accentWhite,
                                backgroundColor: AppColors.brandGreen,
                                side: const BorderSide(
                                  color: AppColors.divider,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  height: 1.33,
                                ),
                              ),
                              child: const Text('Получить код'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([controller, focusNode]),
      builder: (context, _) {
        final focused = focusNode.hasFocus;
        final floatLabel = focused || controller.text.isNotEmpty;

        return Container(
          key: PhoneAuthScreen.phoneFieldKey,
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: focused ? AppColors.accentBlack : AppColors.divider,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: floatLabel
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              if (floatLabel)
                const Text(
                  'Номер телефона',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 1.33,
                  ),
                ),
              TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                onSubmitted: onSubmitted,
                inputFormatters: [RussianPhoneFormatter()],
                cursorColor: AppColors.brandGreen,
                style: const TextStyle(
                  color: AppColors.accentBlack,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  height: 1.33,
                ),
                decoration: InputDecoration.collapsed(
                  hintText: floatLabel ? null : 'Номер телефона',
                  hintStyle: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    height: 1.33,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TermsText extends StatelessWidget {
  const _TermsText({
    required this.termsRecognizer,
    required this.privacyRecognizer,
  });

  final TapGestureRecognizer termsRecognizer;
  final TapGestureRecognizer privacyRecognizer;

  @override
  Widget build(BuildContext context) {
    const secondaryStyle = TextStyle(
      color: AppColors.textSecondary,
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.38,
    );
    const linkStyle = TextStyle(
      color: AppColors.brandGreen,
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.38,
    );

    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(
            text: 'Продолжая, я соглашаюсь с ',
            style: secondaryStyle,
          ),
          TextSpan(
            text: 'условиями использования',
            style: linkStyle,
            recognizer: termsRecognizer,
          ),
          const TextSpan(text: ' и ', style: secondaryStyle),
          TextSpan(
            text: 'политикой конфиденциальности',
            style: linkStyle,
            recognizer: privacyRecognizer,
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
