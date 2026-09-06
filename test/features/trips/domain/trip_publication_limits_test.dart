import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/trips/domain/trip_publication_limits.dart';

void main() {
  const limits = TripPublicationLimits(perDay: 2, perWeek: 10);

  group('TripPublicationUsage', () {
    test('allows publishing while both windows have room', () {
      const usage = TripPublicationUsage(
        publishedToday: 1,
        publishedThisWeek: 4,
        publishedReturnToday: 1,
      );

      expect(usage.blockFor(limits), isNull);
      expect(usage.remainingToday(limits), 1);
      expect(usage.remainingThisWeek(limits), 6);
    });

    test('one publication in a direction closes that direction for today', () {
      const usage = TripPublicationUsage(
        publishedToday: 1,
        publishedThisWeek: 1,
        publishedOutboundToday: 1,
      );

      expect(usage.blockFor(limits), TripPublicationBlock.directionLimit);
      expect(usage.blockFor(limits, isReturn: true), isNull);
    });

    test('the return direction is counted on its own', () {
      const usage = TripPublicationUsage(
        publishedToday: 1,
        publishedThisWeek: 1,
        publishedReturnToday: 1,
      );

      expect(
        usage.blockFor(limits, isReturn: true),
        TripPublicationBlock.directionLimit,
      );
      expect(usage.blockFor(limits), isNull);
    });

    test('reports the daily limit first', () {
      const usage = TripPublicationUsage(
        publishedToday: 2,
        publishedThisWeek: 10,
      );

      expect(usage.blockFor(limits), TripPublicationBlock.dailyLimit);
    });

    test('reports the weekly limit when only it is exhausted', () {
      const usage = TripPublicationUsage(
        publishedToday: 0,
        publishedThisWeek: 10,
      );

      expect(usage.blockFor(limits), TripPublicationBlock.weeklyLimit);
      expect(usage.remainingThisWeek(limits), 0);
    });
  });
}
