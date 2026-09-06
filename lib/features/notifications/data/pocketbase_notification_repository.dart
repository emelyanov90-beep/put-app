import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:vput/core/api/pocketbase_provider.dart';
import 'package:vput/core/config/app_config.dart';
import 'package:vput/features/auth/application/preview_session_controller.dart';
import 'package:vput/features/notifications/domain/app_notification.dart';

/// Notifications are read straight from the collection — `listRule` already
/// limits them to their owner. Marking them read is a state change and goes
/// through the server action instead.
class PocketBaseNotificationRepository implements NotificationRepository {
  PocketBaseNotificationRepository(this._client);

  final PocketBase _client;

  @override
  Future<List<AppNotification>> load() async {
    try {
      final records = await _client
          .collection('notifications')
          .getFullList(sort: '-created_at', batch: 200)
          .timeout(const Duration(seconds: 15));
      return records.map(_fromRecord).toList(growable: false);
    } on ClientException catch (error) {
      throw NotificationFailure(
        error.statusCode == 401
            ? 'Сессия истекла. Войдите снова.'
            : 'Не удалось загрузить уведомления. Попробуйте ещё раз.',
      );
    } on TimeoutException {
      throw const NotificationFailure(
        'Не удалось получить ответ. Проверьте соединение.',
      );
    }
  }

  @override
  Future<int> markAllRead() async {
    try {
      final response = await _client
          .send<Map<String, dynamic>>(
            '/api/app/notifications/read',
            method: 'POST',
            body: const {'ids': <String>[]},
          )
          .timeout(const Duration(seconds: 15));
      return (response['updated'] as num?)?.toInt() ?? 0;
    } catch (_) {
      throw const NotificationFailure(
        'Не удалось отметить уведомления прочитанными.',
      );
    }
  }

  AppNotification _fromRecord(RecordModel record) {
    final payload = record.get<dynamic>('payload');
    final map = payload is Map ? Map<String, dynamic>.from(payload) : const {};
    return AppNotification(
      id: record.id,
      kind: appNotificationKindFromType(record.getStringValue('type')),
      title: record.getStringValue('title'),
      body: record.getStringValue('body'),
      createdAt:
          DateTime.tryParse(record.getStringValue('created_at'))?.toLocal() ??
          DateTime.now(),
      isRead: record.getStringValue('read_at').isNotEmpty,
      bookingId: map['booking_id'] as String?,
      tripId: map['trip_id'] as String?,
    );
  }
}

/// Demo notifications used while the app runs without a backend, so the section
/// shows its real layout instead of an error.
class PreviewNotificationRepository implements NotificationRepository {
  PreviewNotificationRepository();

  var _read = false;

  @override
  Future<List<AppNotification>> load() async {
    final now = DateTime.now();
    return [
      AppNotification(
        id: 'preview_notification_approved',
        kind: AppNotificationKind.bookingApproved,
        title: 'Заявка одобрена',
        body: 'Теперь можно оплатить комиссию.',
        createdAt: now.subtract(const Duration(hours: 2)),
        isRead: _read,
      ),
      AppNotification(
        id: 'preview_notification_message',
        kind: AppNotificationKind.message,
        title: 'Новое сообщение',
        body: 'У вас новое сообщение.',
        createdAt: now.subtract(const Duration(days: 1)),
        isRead: true,
      ),
    ];
  }

  @override
  Future<int> markAllRead() async {
    if (_read) return 0;
    _read = true;
    return 1;
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  ref.watch(currentSessionUserIdProvider);
  if (AppConfig.isPreviewMode) return PreviewNotificationRepository();
  return PocketBaseNotificationRepository(ref.watch(pocketBaseProvider));
});
