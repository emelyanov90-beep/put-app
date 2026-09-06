import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vput/app/theme/app_colors.dart';

/// Terminal state for an account the administrator deactivated
/// (`users.is_active = false`). It deliberately offers no way forward: access
/// is restored only from the admin side.
class AccountBlockedScreen extends StatelessWidget {
  const AccountBlockedScreen({super.key});

  static const titleKey = Key('account_blocked_title');
  static const illustrationKey = Key('account_blocked_illustration');

  @override
  Widget build(BuildContext context) {
    const overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.accentBlack,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: AppColors.accentBlack,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              const _BlockedHeader(),
              Expanded(
                child: Center(
                  child: Image.asset(
                    'docs/imgs/block.png',
                    key: illustrationKey,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const _BlockedNotice(),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlockedHeader extends StatelessWidget {
  const _BlockedHeader();

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(10, topInset + 24, 10, 24),
      decoration: const BoxDecoration(
        color: AppColors.brandGreen,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox.square(
            dimension: 50,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.accentWhite,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on_rounded,
                color: AppColors.brandGreen,
                size: 30,
              ),
            ),
          ),
          SizedBox(width: 10),
          Text(
            'Путь',
            style: TextStyle(
              color: AppColors.accentWhite,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockedNotice extends StatelessWidget {
  const _BlockedNotice();

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 32, 16, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.accentBlack,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Ваш аккаунт заблокирован',
            key: AccountBlockedScreen.titleKey,
            style: TextStyle(
              color: AppColors.accentWhite,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Мы ограничили доступ из-за нарушений условий использования',
            style: TextStyle(
              color: AppColors.accentSurface,
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.33,
            ),
          ),
        ],
      ),
    );
  }
}
