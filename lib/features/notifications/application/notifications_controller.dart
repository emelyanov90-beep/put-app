import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/core/config/app_config.dart';
import 'package:vput/features/auth/application/preview_session_controller.dart';
import 'package:vput/features/notifications/data/pocketbase_notification_repository.dart';
import 'package:vput/features/notifications/domain/app_notification.dart';

class NotificationsController extends AsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() {
    final userId = ref.watch(currentSessionUserIdProvider);
    if (!AppConfig.isPreviewMode && userId == null) {
      return Future.value(const <AppNotification>[]);
    }
    return ref.watch(notificationRepositoryProvider).load();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(notificationRepositoryProvider).load(),
    );
  }

  /// Marks everything read on the server, then reloads so the list and the
  /// profile badge come from the same source.
  Future<void> markAllRead() async {
    final current = state.value;
    if (current == null || current.every((item) => item.isRead)) return;
    try {
      await ref.read(notificationRepositoryProvider).markAllRead();
    } on NotificationFailure {
      return;
    }
    state = await AsyncValue.guard(
      () => ref.read(notificationRepositoryProvider).load(),
    );
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsController, List<AppNotification>>(
      NotificationsController.new,
    );

/// Unread count shown as a badge on the «Уведомления» row of the profile.
final unreadNotificationsProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider).value;
  if (notifications == null) return 0;
  return notifications.where((item) => !item.isRead).length;
});
