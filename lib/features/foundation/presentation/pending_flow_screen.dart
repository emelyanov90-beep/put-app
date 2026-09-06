import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/app/widgets/screen_header.dart';
import 'package:vput/features/system/presentation/system_message_view.dart';

/// Explicit unavailable state for preview sections that await backend integration.
class PendingFlowScreen extends StatelessWidget {
  const PendingFlowScreen({required this.title, super.key});
  final String title;

  @override
  Widget build(BuildContext context) {
    void back() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: title, onBack: back),
            Expanded(
              child: SystemMessageView(
                assetPath: 'docs/imgs/notinternet.png',
                title: title.contains('не найден')
                    ? title
                    : 'Раздел пока недоступен',
                description: title.contains('не найден')
                    ? 'Данные больше недоступны. Вернитесь к списку и выберите другую запись.'
                    : 'Этот раздел ещё не подключён. Вы можете вернуться к поездкам.',
                actionLabel: 'Вернуться',
                onAction: back,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
