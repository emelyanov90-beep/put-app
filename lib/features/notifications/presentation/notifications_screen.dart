import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/core/utils/russian_date_labels.dart';
import 'package:vput/features/notifications/application/notifications_controller.dart';
import 'package:vput/features/notifications/domain/app_notification.dart';
import 'package:vput/features/profile/presentation/widgets/profile_section_scaffold.dart';
import 'package:vput/features/system/presentation/system_failure_view.dart';
import 'package:vput/features/system/presentation/system_loading_screen.dart';

/// «Уведомления»: everything the server has sent this user, newest first.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({required this.onBack, super.key});

  static const markAllReadKey = Key('notifications_mark_all_read');
  static Key itemKey(String id) => Key('notification_$id');

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);

    return state.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(child: SystemLoadingView()),
      ),
      error: (_, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SystemFailureView(
            onRetry: () => ref.read(notificationsProvider.notifier).reload(),
          ),
        ),
      ),
      data: (notifications) {
        final unread = notifications.where((item) => !item.isRead).length;
        return ProfileSectionScaffold(
          title: 'Уведомления',
          onBack: onBack,
          footer: notifications.isEmpty
              ? null
              : ProfilePrimaryAction(
                  actionKey: markAllReadKey,
                  label: 'Отметить все прочитанными',
                  onPressed: unread == 0
                      ? null
                      : () => ref
                            .read(notificationsProvider.notifier)
                            .markAllRead(),
                ),
          children: [
            if (notifications.isEmpty)
              const ProfileEmptyState(
                icon: Icons.notifications_none_rounded,
                title: 'Уведомлений пока нет',
                description:
                    'Здесь появятся заявки, подтверждения и сообщения по '
                    'вашим поездкам.',
              )
            else
              for (var index = 0; index < notifications.length; index++) ...[
                if (index > 0) const SizedBox(height: 10),
                _NotificationCard(notification: notifications[index]),
              ],
          ],
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    return Container(
      key: NotificationsScreen.itemKey(notification.id),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unread ? AppColors.brandGreen : Colors.transparent,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _icon(notification.kind),
            size: 22,
            color: unread ? AppColors.brandGreen : AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: const TextStyle(
                    color: AppColors.accentBlack,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.33,
                  ),
                ),
                if (notification.body.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      height: 1.33,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  RussianDateLabels.dateAndTime(notification.createdAt),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static IconData _icon(AppNotificationKind kind) => switch (kind) {
    AppNotificationKind.bookingCreated => Icons.person_add_alt_1_rounded,
    AppNotificationKind.bookingApproved => Icons.check_circle_outline_rounded,
    AppNotificationKind.bookingRejected => Icons.cancel_outlined,
    AppNotificationKind.bookingPaid => Icons.account_balance_wallet_outlined,
    AppNotificationKind.bookingCancelled => Icons.event_busy_rounded,
    AppNotificationKind.tripPublished => Icons.campaign_outlined,
    AppNotificationKind.tripCancelled => Icons.event_busy_rounded,
    AppNotificationKind.vehicleSubmitted => Icons.directions_car_filled_rounded,
    AppNotificationKind.message => Icons.chat_bubble_outline_rounded,
    AppNotificationKind.other => Icons.notifications_none_rounded,
  };
}
