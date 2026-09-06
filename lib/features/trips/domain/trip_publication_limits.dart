import 'package:flutter/foundation.dart';

/// Why publishing is refused right now.
enum TripPublicationBlock { directionLimit, dailyLimit, weeklyLimit }

/// Publication limits. The backend owns these values (`app_settings`) and is the
/// source of truth for the counters; the client only mirrors them.
@immutable
class TripPublicationLimits {
  const TripPublicationLimits({
    required this.perDay,
    required this.perWeek,
    this.outboundPerDay = 1,
    this.returnPerDay = 1,
  });

  final int perDay;
  final int perWeek;

  /// A car trip may run once a day in each direction: there and back.
  final int outboundPerDay;
  final int returnPerDay;
}

/// How many trips the driver has already published in the current windows.
@immutable
class TripPublicationUsage {
  const TripPublicationUsage({
    required this.publishedToday,
    required this.publishedThisWeek,
    this.publishedOutboundToday = 0,
    this.publishedReturnToday = 0,
  });

  final int publishedToday;
  final int publishedThisWeek;

  /// Trips published today in the forward direction.
  final int publishedOutboundToday;

  /// Trips published today as a return of another trip.
  final int publishedReturnToday;

  /// [isReturn] tells which direction the trip about to be published runs in.
  TripPublicationBlock? blockFor(
    TripPublicationLimits limits, {
    bool isReturn = false,
  }) {
    final usedInDirection = isReturn
        ? publishedReturnToday
        : publishedOutboundToday;
    final directionLimit = isReturn
        ? limits.returnPerDay
        : limits.outboundPerDay;
    if (usedInDirection >= directionLimit) {
      return TripPublicationBlock.directionLimit;
    }
    if (publishedToday >= limits.perDay) return TripPublicationBlock.dailyLimit;
    if (publishedThisWeek >= limits.perWeek) {
      return TripPublicationBlock.weeklyLimit;
    }
    return null;
  }

  int remainingToday(TripPublicationLimits limits) =>
      (limits.perDay - publishedToday).clamp(0, limits.perDay);

  int remainingThisWeek(TripPublicationLimits limits) =>
      (limits.perWeek - publishedThisWeek).clamp(0, limits.perWeek);
}
