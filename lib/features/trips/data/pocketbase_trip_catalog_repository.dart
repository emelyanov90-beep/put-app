import 'package:pocketbase/pocketbase.dart';
import 'package:vput/features/trips/domain/passenger_trip.dart';
import 'package:vput/features/trips/domain/trip_catalog_repository.dart';

class PocketBaseTripCatalogRepository implements TripCatalogRepository {
  PocketBaseTripCatalogRepository(this._client);

  final PocketBase _client;
  final Map<String, PassengerTrip> _cache = {};

  @override
  PassengerTrip? findById(String id) => _cache[id];

  @override
  Future<List<PassengerTrip>> search(
    PassengerTransportType transportType,
  ) async {
    final response = await _client.send<Map<String, dynamic>>(
      '/api/app/trips/search',
      query: {'transport_type': transportType.name},
    );
    final rawItems = response['items'];
    if (rawItems is! List) throw const FormatException('Invalid trips list');
    final trips = rawItems
        .whereType<Map>()
        .map((raw) => tripFromJson(Map<String, dynamic>.from(raw)))
        .toList(growable: false);
    _cache
      ..clear()
      ..addEntries(trips.map((trip) => MapEntry(trip.id, trip)));
    return trips;
  }

  PassengerTrip tripFromJson(Map<String, dynamic> json) {
    final driver = Map<String, dynamic>.from(json['driver'] as Map);
    final vehicle = Map<String, dynamic>.from(json['vehicle'] as Map);
    final rawStops = json['stops'] as List;
    final departure = DateTime.parse(json['departure_at'] as String).toLocal();
    final arrival = DateTime.parse(json['arrival_at'] as String).toLocal();
    final services = (json['services'] as List? ?? const [])
        .map(
          (value) => switch (value) {
            'child_seat' => TripExtraService.childSeat,
            'luggage' => TripExtraService.luggage,
            'pets' => TripExtraService.pets,
            'parcel' => TripExtraService.parcel,
            _ => null,
          },
        )
        .whereType<TripExtraService>()
        .toList(growable: false);
    return PassengerTrip(
      id: json['id'] as String,
      transportType: json['transport_type'] == 'bus'
          ? PassengerTransportType.bus
          : PassengerTransportType.car,
      driverName: driver['name'] as String? ?? '',
      driverRating: (driver['rating_avg'] as num?)?.toDouble(),
      driverReviewsCount: (driver['reviews_count'] as num?)?.toInt() ?? 0,
      driverTripsCount: 0,
      distanceKm: 0,
      priorityBadge: TripPriorityBadge.nearest,
      stops: rawStops
          .whereType<Map>()
          .map((stop) => TripStopPreview(stop['address'] as String? ?? ''))
          .toList(growable: false),
      departureLabel: _dateLabel(departure),
      detailsDepartureLabel: _dateLabel(departure),
      arrivalLabel: 'Прибытие ~${_timeLabel(arrival)}',
      priceRubles: (json['base_price'] as num).toInt(),
      detailsPriceRubles: (json['base_price'] as num).toInt(),
      availableSeats: (json['available_seats'] as num).toInt(),
      totalSeats: (json['seat_capacity'] as num).toInt(),
      services: services,
      vehicle: TripVehiclePreview(
        brand: vehicle['brand'] as String? ?? '',
        model: vehicle['model'] as String? ?? '',
        plateNumber: vehicle['plate_number'] as String? ?? '',
        photoAsset: 'docs/imgs/car.png',
      ),
      passengerRegistrationStatus: json['accepting_bookings'] == true
          ? TripPassengerRegistrationStatus.inProgress
          : TripPassengerRegistrationStatus.waiting,
      bookingMode: json['booking_mode'] == 'instant'
          ? PassengerTripBookingMode.instant
          : PassengerTripBookingMode.standard,
    );
  }

  static String _dateLabel(DateTime value) {
    const months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];
    return '${value.day} ${months[value.month - 1]}, ${_timeLabel(value)}';
  }

  static String _timeLabel(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}
