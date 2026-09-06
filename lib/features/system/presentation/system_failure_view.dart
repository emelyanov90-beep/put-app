import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/features/system/application/connection_status_provider.dart';
import 'package:vput/features/system/presentation/system_message_view.dart';

/// Renders the failure state for an operation that did not succeed.
///
/// The device connectivity decides which of the two Figma states is shown:
/// offline gets "Нет интернет-соединения", everything else (including a
/// connectivity check that could not be resolved) gets the generic error, so
/// the copy never blames the network without evidence.
class SystemFailureView extends ConsumerWidget {
  const SystemFailureView({required this.onRetry, super.key});

  static const noInternetKey = Key('system_no_internet');
  static const errorKey = Key('system_error');
  static const retryButtonKey = SystemMessageView.actionButtonKey;

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    if (!isOnline) {
      return SystemMessageView(
        key: noInternetKey,
        assetPath: 'docs/imgs/notinternet.png',
        title: 'Нет интернет-соединения',
        description:
            'Проверьте, включён ли Wi-Fi или мобильный интернет, '
            'и попробуйте снова.',
        actionLabel: 'Обновить',
        onAction: onRetry,
      );
    }

    return SystemMessageView(
      key: errorKey,
      assetPath: 'docs/imgs/notinternet.png',
      title: 'Не удалось выполнить действие',
      description:
          'Что-то пошло не так. Проверьте интернет и повторите попытку. '
          'Если ошибка останется — зайдите позже.',
      actionLabel: 'Обновить',
      onAction: onRetry,
    );
  }
}

/// Full-screen variant of [SystemFailureView].
class SystemFailureScreen extends StatelessWidget {
  const SystemFailureScreen({required this.onRetry, super.key});

  final VoidCallback onRetry;

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
        backgroundColor: AppColors.background,
        body: SafeArea(child: SystemFailureView(onRetry: onRetry)),
      ),
    );
  }
}
