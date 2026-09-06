import 'package:vput/features/trips/domain/passenger_trip.dart';

abstract interface class TripCatalogRepository {
  Future<List<PassengerTrip>> search(PassengerTransportType transportType);

  PassengerTrip? findById(String id);
}
