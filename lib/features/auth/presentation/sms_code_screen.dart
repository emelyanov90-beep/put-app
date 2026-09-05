import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/app/widgets/screen_header.dart';

class SmsCodeScreen extends StatefulWidget {
  const SmsCodeScreen({
    required this.phone,
    required this.expectedCode,
    required this.onVerified,
    required this.onBack,
    this.onResend,
    super.key,
  });

  static const codeLength = 6;
  static const resendSeconds = 59;

  static const descriptionKey = Key('sms_code_description');
  static const submitButtonKey = Key('sms_code_submit');
  static const resendButtonKey = Key('sms_code_resend');
  static const errorBannerKey = Key('sms_code_error');
  static const backButtonKey = ScreenHeader.backButtonKey;

  static Key digitFieldKey(int index) => ValueKey('sms_code_digit_$index');

  final String phone;
  final String expectedCode;
  final VoidCallback onVerified;
  final VoidCallback onBack;
  final VoidCallback? onResend;

  @override
  State<SmsCodeScreen> createState() => _SmsCodeScreenState();
}

class _SmsCodeScreenState extends State<SmsCodeScreen> {
  late final _controllers = List.generate(
    SmsCodeScreen.codeLength,
    (_) => TextEditingController(),
  );
  late final _focusNodes = List.generate(
    SmsCodeScreen.codeLength,
    (_) => FocusNode(),
  );

  Timer? _resendTimer;
  int _secondsRemaining = SmsCodeScreen.resendSeconds;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    for (final node in _focusNodes) {
      node.addListener(_handleFocusChange);
    }
    _startTimer();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node
        ..removeListener(_handleFocusChange)
        ..dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) setState(() {});
  }

  void _startTimer() {
    _resendTimer?.cancel();
    setState(() => _secondsRemaining = SmsCodeScreen.resendSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
        return;
      }
      setState(() => _secondsRemaining -= 1);
    });
  }

  String get _code => _controllers.map((c) => c.text).join();

  bool get _isComplete => _code.length == SmsCodeScreen.codeLength;

  bool get _isGroupActive =>
      _code.isNotEmpty || _focusNodes.any((node) => node.hasFocus);

  void _handleDigitChanged(int index, String value) {
    if (_hasError) _hasError = false;
    if (value.isNotEmpty && index < SmsCodeScreen.codeLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() {});
  }

  void _handleBackspace(int index) {
    if (index == 0) return;
    _focusNodes[index - 1].requestFocus();
    _controllers[index - 1].clear();
    setState(() => _hasError = false);
  }

  void _submit() {
    if (!_isComplete || _hasError) return;
    if (_code == widget.expectedCode) {
      widget.onVerified();
    } else {
      setState(() => _hasError = true);
    }
  }

  void _resend() {
    for (final controller in _controllers) {
      controller.clear();
    }
    _focusNodes.first.requestFocus();
    setState(() => _hasError = false);
    _startTimer();
    widget.onResend?.call();
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

    final canSubmit = _isComplete && !_hasError;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              ScreenHeader(title: 'СМС-код', onBack: widget.onBack),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text:
                                  'Введите код подтверждения из SMS, '
                                  'отправленного на ',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                height: 1.33,
                              ),
                            ),
                            TextSpan(
                              text: widget.phone,
                              style: const TextStyle(
                                color: AppColors.accentBlack,
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                height: 1.33,
                              ),
                            ),
                          ],
                        ),
                        key: SmsCodeScreen.descriptionKey,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 4,
                        children: [
                          for (var i = 0; i < SmsCodeScreen.codeLength; i++)
                            _DigitField(
                              index: i,
                              controller: _controllers[i],
                              focusNode: _focusNodes[i],
                              active: _isGroupActive,
                              onChanged: _handleDigitChanged,
                              onBackspace: _handleBackspace,
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _secondsRemaining > 0
                          ? _ResendTimer(seconds: _secondsRemaining)
                          : _ResendLink(onTap: _resend),
                      if (_hasError) ...[
                        const SizedBox(height: 16),
                        const _ErrorBanner(),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    key: SmsCodeScreen.submitButtonKey,
                    onPressed: canSubmit ? _submit : null,
                    style: FilledButton.styleFrom(
                      disabledBackgroundColor: AppColors.background,
                      disabledForegroundColor: AppColors.textSecondary,
                      foregroundColor: AppColors.accentWhite,
                      backgroundColor: AppColors.brandGreen,
                      side: const BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.33,
                      ),
                    ),
                    child: const Text('Вход'),
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

class _DigitField extends StatelessWidget {
  const _DigitField({
    required this.index,
    required this.controller,
    required this.focusNode,
    required this.active,
    required this.onChanged,
    required this.onBackspace,
  });

  final int index;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool active;
  final void Function(int index, String value) onChanged;
  final void Function(int index) onBackspace;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: SmsCodeScreen.digitFieldKey(index),
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.accentWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? AppColors.brandGreen : Colors.transparent,
        ),
      ),
      alignment: Alignment.center,
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              controller.text.isEmpty) {
            onBackspace(index);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          cursorColor: AppColors.brandGreen,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (value) => onChanged(index, value),
          style: const TextStyle(
            color: AppColors.accentBlack,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            height: 1.29,
          ),
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            hintText: '_',
            hintStyle: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.29,
            ),
          ),
        ),
      ),
    );
  }
}

class _ResendTimer extends StatelessWidget {
  const _ResendTimer({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        const Text(
          'Выслать код повторно через:',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.33,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.brandGreen),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '0:${seconds.toString().padLeft(2, '0')}',
            style: const TextStyle(
              color: AppColors.accentBlack,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.33,
            ),
          ),
        ),
      ],
    );
  }
}

class _ResendLink extends StatelessWidget {
  const _ResendLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        const Text(
          'Не получили SMS код?',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.33,
          ),
        ),
        OutlinedButton(
          key: SmsCodeScreen.resendButtonKey,
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accentBlack,
            side: const BorderSide(color: AppColors.brandGreen),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.33,
            ),
          ),
          child: const Text('Отправить'),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: SmsCodeScreen.errorBannerKey,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.errorBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 8,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: AppColors.accentWhite,
                size: 18,
              ),
              Flexible(
                child: Text(
                  'Неверный код подтверждения',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.accentWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Код не подходит. Проверьте правильность введённых цифр и срок '
          'действия кода. Если код устарел, запросите новый',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.errorText,
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 1.33,
          ),
        ),
      ],
    );
  }
}
