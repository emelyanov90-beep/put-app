import 'package:flutter/foundation.dart';

/// Money split of a trip as the driver sees it.
///
/// The driver names what they want to receive; the platform commission is added
/// on top of it, and the passenger pays the sum. So a fare of 1000 ₽ with a
/// 10 % commission means the passenger pays 1100 ₽ and the driver keeps 1000 ₽.
///
/// The data-model formula still holds, with `total_price` being what the
/// passenger owes: `driver_amount = total_price - commission_amount`.
@immutable
class TripMoneyBreakdown {
  const TripMoneyBreakdown({
    required this.driverAmount,
    required this.commission,
  });

  /// What the driver receives — the fare they entered.
  final int driverAmount;

  /// What the platform charges on top of it.
  final int commission;

  /// What the passenger pays.
  int get total => driverAmount + commission;
}

/// Commission the platform charges for a booking, as a percentage of the fare.
///
/// The rate comes from the server configuration (`app_settings`); the client
/// only applies it, and the backend recomputes it when a booking is created.
@immutable
class TripCommissionPolicy {
  const TripCommissionPolicy({required this.percent});

  final int percent;

  /// Splits a fare the driver entered into what they keep and what is added.
  TripMoneyBreakdown breakdownFor(int driverFare) {
    final safeFare = driverFare < 0 ? 0 : driverFare;
    return TripMoneyBreakdown(
      driverAmount: safeFare,
      commission: commissionOn(safeFare),
    );
  }

  /// Commission charged on [driverFare], rounded to whole rubles the same way
  /// the backend rounds it.
  int commissionOn(int driverFare) {
    if (driverFare <= 0 || percent <= 0) return 0;
    return (driverFare * percent / 100).round();
  }
}
