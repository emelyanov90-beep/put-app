import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/core/api/pocketbase_provider.dart';
import 'package:vput/core/config/app_config.dart';
import 'package:vput/features/trips/data/pocketbase_trip_catalog_repository.dart';
import 'package:vput/features/trips/domain/passenger_trip.dart';
import 'package:vput/features/trips/domain/trip_catalog_repository.dart';

const previewPassengerTrips = <PassengerTrip>[
  PassengerTrip(
    id: 'preview_trip_viktor',
    transportType: PassengerTransportType.car,
    driverName: 'Виктор О.',
    driverRating: 4.5,
    driverReviewsCount: 12,
    driverTripsCount: 127,
    distanceKm: 3.2,
    priorityBadge: TripPriorityBadge.top,
    stops: [
      TripStopPreview('Улица Солнечная, дом 1'),
      TripStopPreview('Улица Ленина, дом 5'),
      TripStopPreview('Улица Пушкина, дом 10'),
      TripStopPreview('Улица Лунная, дом 2'),
    ],
    departureLabel: '15 мая, 09:00',
    detailsDepartureLabel: '15 мая, 09:00',
    arrivalLabel: 'Прибытие ~18:00',
    priceRubles: 1200,
    detailsPriceRubles: 1200,
    availableSeats: 0,
    totalSeats: 3,
    services: [
      TripExtraService.pets,
      TripExtraService.luggage,
      TripExtraService.parcel,
    ],
    passengerRegistrationStatus: TripPassengerRegistrationStatus.inProgress,
    vehicle: TripVehiclePreview(
      brand: 'LADA',
      model: 'Largus',
      plateNumber: 'А 777 АА 7',
      photoAsset: 'docs/imgs/car.png',
    ),
  ),
  PassengerTrip(
    id: 'preview_trip_alexander',
    transportType: PassengerTransportType.car,
    driverName: 'Александр П.',
    driverRating: null,
    driverTripsCount: 48,
    distanceKm: 4,
    priorityBadge: TripPriorityBadge.nearest,
    stops: [
      TripStopPreview('Улица Солнечная, дом 5'),
      TripStopPreview('Проспект Мечты, дом 12'),
    ],
    departureLabel: '15 мая, 09:00',
    detailsDepartureLabel: '15 мая, 09:00',
    arrivalLabel: 'Прибытие ~18:00',
    priceRubles: 1200,
    detailsPriceRubles: 1200,
    availableSeats: 1,
    totalSeats: 3,
    services: [
      TripExtraService.pets,
      TripExtraService.luggage,
      TripExtraService.childSeat,
      TripExtraService.parcel,
    ],
    vehicle: TripVehiclePreview(
      brand: 'LADA',
      model: 'Largus',
      plateNumber: 'В 123 ОР 30',
      photoAsset: 'docs/imgs/car.png',
    ),
  ),
];

class PreviewTripCatalogRepository implements TripCatalogRepository {
  const PreviewTripCatalogRepository();

  @override
  PassengerTrip? findById(String id) {
    for (final trip in previewPassengerTrips) {
      if (trip.id == id) return trip;
    }
    return null;
  }

  @override
  Future<List<PassengerTrip>> search(
    PassengerTransportType transportType,
  ) async {
    return previewPassengerTrips
        .where((trip) => trip.transportType == transportType)
        .toList(growable: false);
  }
}

final tripCatalogRepositoryProvider = Provider<TripCatalogRepository>((ref) {
  if (AppConfig.hasPocketBaseUrl) {
    return PocketBaseTripCatalogRepository(ref.watch(pocketBaseProvider));
  }
  return const PreviewTripCatalogRepository();
});
