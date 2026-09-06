import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/trips/domain/trip_departure_slots.dart';

void main() {
  group('TripDepartureSlots', () {
    test('accepts only whole and half hours', () {
      expect(TripDepartureSlots.isAligned(DateTime(2026, 5, 15, 9)), isTrue);
      expect(
        TripDepartureSlots.isAligned(DateTime(2026, 5, 15, 9, 30)),
        isTrue,
      );
      expect(
        TripDepartureSlots.isAligned(DateTime(2026, 5, 15, 9, 15)),
        isFalse,
      );
      expect(
        TripDepartureSlots.isAligned(DateTime(2026, 5, 15, 9, 0, 30)),
        isFalse,
      );
    });

    test('a future day offers all 48 slots', () {
      final slots = TripDepartureSlots.forDay(
        DateTime(2026, 5, 16),
        now: DateTime(2026, 5, 15, 9, 20),
      );

      expect(slots.length, 48);
      expect(slots.first, DateTime(2026, 5, 16));
      expect(slots.last, DateTime(2026, 5, 16, 23, 30));
    });

    test('today drops the slots that already passed', () {
      final slots = TripDepartureSlots.forDay(
        DateTime(2026, 5, 15),
        now: DateTime(2026, 5, 15, 9, 20),
      );

      expect(slots.first, DateTime(2026, 5, 15, 9, 30));
      expect(slots.every(TripDepartureSlots.isAligned), isTrue);
    });

    test('rounds up to the next slot and keeps an exact slot as is', () {
      expect(
        TripDepartureSlots.roundUp(DateTime(2026, 5, 15, 9, 1)),
        DateTime(2026, 5, 15, 9, 30),
      );
      expect(
        TripDepartureSlots.roundUp(DateTime(2026, 5, 15, 9, 30)),
        DateTime(2026, 5, 15, 9, 30),
      );
      expect(
        TripDepartureSlots.roundUp(DateTime(2026, 5, 15, 23, 45)),
        DateTime(2026, 5, 16),
      );
    });
  });
}
