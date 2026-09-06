import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/core/api/pocketbase_provider.dart';
import 'package:vput/core/config/app_config.dart';
import 'package:vput/features/trips/data/pocketbase_trip_catalog_repository.dart';
import 'package:vput/features/trips/data/preview_passenger_orders.dart';
import 'package:vput/features/trips/domain/passenger_order.dart';

final passengerOrdersProvider = FutureProvider<List<PassengerOrder>>((
  ref,
) async {
  if (!AppConfig.hasPocketBaseUrl) return previewPassengerOrders;
  final client = ref.watch(pocketBaseProvider);
  final response = await client.send<Map<String, dynamic>>(
    '/api/app/bookings/mine',
  );
  final items = response['items'];
  if (items is! List) throw const FormatException('Invalid bookings list');
  final mapper = PocketBaseTripCatalogRepository(client);
  return items
      .whereType<Map>()
      .map((raw) {
        final item = Map<String, dynamic>.from(raw);
        final booking = Map<String, dynamic>.from(item['booking'] as Map);
        final trip = mapper.tripFromJson(
          Map<String, dynamic>.from(item['trip'] as Map),
        );
        final status = booking['status'] as String? ?? '';
        final kind = booking['booking_kind'] as String? ?? 'passenger';
        return PassengerOrder(
          id: booking['id'] as String,
          trip: trip,
          status: status == 'completed'
              ? PassengerOrderStatus.completed
              : (status == 'confirmed'
                    ? (kind == 'parcel'
                          ? PassengerOrderStatus.parcelBooked
                          : PassengerOrderStatus.seatBooked)
                    : PassengerOrderStatus.created),
          departureWindowLabel: trip.departureLabel,
          priceRubles: (booking['amount'] as num?)?.toInt() ?? trip.priceRubles,
          passengerSeatCount: (booking['seat_count'] as num?)?.toInt() ?? 0,
          passengerSeatsAvailable: trip.availableSeats,
          passengerSeatsTotal: trip.totalSeats,
          parcelSizes: kind == 'parcel' ? const ['M'] : const [],
          parcelPriceRubles: kind == 'parcel'
              ? (booking['amount'] as num?)?.toInt()
              : null,
          refundAmountRubles: (booking['commission_amount'] as num?)?.toInt(),
        );
      })
      .toList(growable: false);
});
