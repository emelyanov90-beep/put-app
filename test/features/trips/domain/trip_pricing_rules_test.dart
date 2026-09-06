import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/trips/domain/trip_commission.dart';
import 'package:vput/features/trips/domain/trip_fare_table.dart';

import '../../../support/trip_fares.dart';

void main() {
  group('commission is added on top of the fare', () {
    const policy = TripCommissionPolicy(percent: 10);

    test('the driver keeps what they entered and the passenger pays more', () {
      final money = policy.breakdownFor(1000);

      expect(money.driverAmount, 1000);
      expect(money.commission, 100);
      expect(money.total, 1100);
    });

    test('the data-model formula still holds on the passenger total', () {
      final money = policy.breakdownFor(1234);

      expect(money.total - money.commission, money.driverAmount);
    });

    test('a zero rate leaves the fare untouched', () {
      const free = TripCommissionPolicy(percent: 0);

      expect(free.breakdownFor(1000).total, 1000);
      expect(free.breakdownFor(1000).commission, 0);
    });

    test('a fraction of a ruble is rounded, never dropped', () {
      expect(policy.commissionOn(1005), 101);
      expect(policy.commissionOn(1004), 100);
    });
  });

  group('a fare belongs to its own pair of points', () {
    // Route A-B-C-D-E with the fares the driver entered by hand. A short leg
    // costs more per kilometre, so the pairs are deliberately not additive.
    final table = fares({
      [0, 1]: 300,
      [0, 2]: 500,
      [0, 3]: 700,
      [0, 4]: 900,
      [1, 2]: 300,
      [1, 3]: 500,
      [1, 4]: 700,
      [2, 3]: 300,
      [2, 4]: 500,
      [3, 4]: 300,
    });

    test('A → C costs its own fare, not A → B plus B → C', () {
      expect(table.priceFor(0, 2), 500);
      expect(table.priceFor(0, 1)! + table.priceFor(1, 2)!, 600);
    });

    test('every pair of a five point route can be priced', () {
      expect(TripFareTable.legsFor(5), hasLength(10));
      for (final leg in TripFareTable.legsFor(5)) {
        expect(
          table.priceFor(leg.fromIndex, leg.toIndex),
          isNotNull,
          reason: 'leg ${leg.key} has no fare',
        );
      }
    });

    test('a shorter leg is dearer per point crossed', () {
      final perPointShort = table.priceFor(0, 1)! / 1;
      final perPointLong = table.priceFor(0, 4)! / 4;

      expect(perPointShort, greaterThan(perPointLong));
    });

    test('an unpriced pair stays unpriced and is not derived', () {
      final sparse = fares({
        [0, 1]: 300,
        [1, 2]: 300,
      });

      expect(sparse.priceFor(0, 2), isNull);
    });
  });

  group('fares follow the points they were set for', () {
    test('inserting a stop re-addresses the fares after it', () {
      final table = fares({
        [0, 1]: 300,
        [1, 2]: 400,
        [0, 2]: 600,
      });

      // A stop appears at position 1: the old point 1 becomes point 2.
      final next = table.withPointInserted(1);

      expect(next.priceFor(0, 2), 300);
      expect(next.priceFor(2, 3), 400);
      expect(next.priceFor(0, 3), 600);
      expect(next.priceFor(0, 1), isNull);
    });

    test('removing a stop drops only the fares that touched it', () {
      final table = fares({
        [0, 1]: 300,
        [1, 2]: 400,
        [0, 2]: 600,
      });

      final next = table.withPointRemoved(1);

      expect(next.prices, hasLength(1));
      expect(next.priceFor(0, 1), 600);
    });
  });

  group('storage round-trip', () {
    test('a table survives being written and read back', () {
      final table = fares({
        [0, 1]: 300,
        [0, 2]: 500,
        [1, 2]: 300,
      });

      expect(TripFareTable.fromJson(table.toJson()), table);
      expect(table.toJson(), {'0-1': 300, '0-2': 500, '1-2': 300});
    });

    test('malformed keys and prices are ignored rather than trusted', () {
      final table = TripFareTable.fromJson({
        '0-1': 300,
        '2-1': 400,
        'x-y': 500,
        '0-3': 'free',
      });

      expect(table.prices, hasLength(1));
      expect(table.priceFor(0, 1), 300);
    });
  });
}
