import 'package:flutter/foundation.dart';

/// What the notification is about, so the list can show a matching icon and
/// route the user to the right screen.
enum AppNotificationKind {
  bookingCreated,
  bookingApproved,
  bookingRejected,
  bookingPaid,
  bookingCancelled,
  tripPublished,
  tripCancelled,
  vehicleSubmitted,
  message,
  other,
}

@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    this.bookingId,
    this.tripId,
  });

  final String id;
  final AppNotificationKind kind;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String? bookingId;
  final String? tripId;
}

/// Maps the server `type` string onto [AppNotificationKind]. Unknown types stay
/// visible as [AppNotificationKind.other] rather than being dropped.
AppNotificationKind appNotificationKindFromType(String type) => switch (type) {
  'booking_created' => AppNotificationKind.bookingCreated,
  'booking_approved' => AppNotificationKind.bookingApproved,
  'booking_rejected' => AppNotificationKind.bookingRejected,
  'booking_paid' => AppNotificationKind.bookingPaid,
  'booking_cancelled' => AppNotificationKind.bookingCancelled,
  'trip_published' => AppNotificationKind.tripPublished,
  'trip_cancelled' => AppNotificationKind.tripCancelled,
  'vehicle_submitted' => AppNotificationKind.vehicleSubmitted,
  'message_received' => AppNotificationKind.message,
  _ => AppNotificationKind.other,
};

abstract interface class NotificationRepository {
  Future<List<AppNotification>> load();

  /// Marks every unread notification as read and returns how many changed.
  Future<int> markAllRead();
}

class NotificationFailure implements Exception {
  const NotificationFailure(this.message);
  final String message;
}
