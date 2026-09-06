import 'package:vput/features/trips/domain/driver_trip.dart';
import 'package:vput/features/trips/domain/trip_draft.dart';

abstract interface class DriverTripRepository {
  Future<List<DriverTrip>> list();

  Future<DriverTrip> save(
    TripDraft draft, {
    String? id,
    bool? acceptingBookings,
  });

  Future<DriverTrip> publish(String id);

  Future<DriverTrip> createReturn(String sourceId, TripDraft draft);

  Future<void> approveBooking(String bookingId);

  Future<void> rejectBooking(String bookingId);

  Future<void> cancel(String tripId);
}
