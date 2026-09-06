import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/app/widgets/screen_header.dart';
import 'package:vput/features/system/presentation/system_message_view.dart';

/// Shown when a record a route points at is gone — a deleted trip, an order
/// that no longer belongs to the user, a stale deep link.
///
/// Every section of the application is implemented, so this screen is never a
/// «coming soon» placeholder: if it appears, the data is genuinely missing.
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
                title: title,
                description:
                    'Данные больше недоступны. Вернитесь к списку и выберите '
                    'другую запись.',
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
