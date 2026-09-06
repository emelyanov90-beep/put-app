import 'package:flutter/foundation.dart';

/// Money split of a trip as the driver sees it: the price entered by the driver
/// is what the passenger pays, the platform keeps the commission and the rest
/// goes to the driver.
///
/// Follows the formula of the data model:
/// `driver_amount = total_price - commission_amount`.
@immutable
class TripMoneyBreakdown {
  const TripMoneyBreakdown({required this.total, required this.commission});

  final int total;
  final int commission;

  int get driverAmount => total - commission < 0 ? 0 : total - commission;
}

/// Commission the platform charges for a booking.
///
/// The value comes from the server configuration (`app_settings`); the client
/// only applies it.
@immutable
class TripCommissionPolicy {
  const TripCommissionPolicy({required this.fixedRubles});

  final int fixedRubles;

  TripMoneyBreakdown breakdownFor(int totalPrice) {
    return TripMoneyBreakdown(total: totalPrice, commission: fixedRubles);
  }
}
