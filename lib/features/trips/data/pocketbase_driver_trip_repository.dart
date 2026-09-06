import 'package:pocketbase/pocketbase.dart';
import 'package:vput/features/trips/domain/driver_trip.dart';
import 'package:vput/features/trips/domain/driver_trip_repository.dart';
import 'package:vput/features/trips/domain/passenger_trip.dart';
import 'package:vput/features/trips/domain/trip_draft.dart';
import 'package:vput/features/trips/domain/trip_extras.dart';
import 'package:vput/features/trips/domain/trip_fare_table.dart';
import 'package:vput/features/trips/domain/trip_route_point.dart';

class PocketBaseDriverTripRepository implements DriverTripRepository {
  PocketBaseDriverTripRepository(this._client);

  final PocketBase _client;

  @override
  Future<List<DriverTrip>> list() async {
    final response = await _client.send<Map<String, dynamic>>(
      '/api/app/trips/mine',
    );
    final items = response['items'];
    if (items is! List) throw const FormatException('Invalid trips list');
    return items
        .whereType<Map>()
        .map((item) => _trip(Map<String, dynamic>.from(item)))
        .where((trip) => trip.status != DriverTripStatus.cancelled)
        .toList(growable: false);
  }

  @override
  Future<DriverTrip> save(
    TripDraft draft, {
    String? id,
    bool? acceptingBookings,
  }) async {
    final body = _body(draft);
    if (acceptingBookings != null) {
      body['accepting_bookings'] = acceptingBookings;
    }
    final response = await _client.send<Map<String, dynamic>>(
      id == null
          ? '/api/app/trips'
          : '/api/app/trips/${Uri.encodeComponent(id)}',
      method: id == null ? 'POST' : 'PATCH',
      body: body,
    );
    return _tripResponse(response);
  }

  @override
  Future<DriverTrip> publish(String id) async {
    final response = await _client.send<Map<String, dynamic>>(
      '/api/app/trips/${Uri.encodeComponent(id)}/publish',
      method: 'POST',
    );
    return _tripResponse(response);
  }

  @override
  Future<DriverTrip> createReturn(String sourceId, TripDraft draft) async {
    final response = await _client.send<Map<String, dynamic>>(
      '/api/app/trips/${Uri.encodeComponent(sourceId)}/create-return',
      method: 'POST',
      body: {
        'departure_at': draft.departureAt?.toUtc().toIso8601String(),
        'arrival_at': draft.arrivalAt?.toUtc().toIso8601String(),
      },
    );
    final created = _tripResponse(response);
    await save(draft, id: created.id);
    return publish(created.id);
  }

  @override
  Future<void> approveBooking(String bookingId) => _bookingAction(
    '/api/app/bookings/${Uri.encodeComponent(bookingId)}/approve',
  );

  @override
  Future<void> rejectBooking(String bookingId) => _bookingAction(
    '/api/app/bookings/${Uri.encodeComponent(bookingId)}/reject',
  );

  @override
  Future<void> cancel(String tripId) =>
      _bookingAction('/api/app/trips/${Uri.encodeComponent(tripId)}/cancel');

  Future<void> _bookingAction(String path) async {
    await _client.send<Map<String, dynamic>>(path, method: 'POST');
  }

  DriverTrip _tripResponse(Map<String, dynamic> response) {
    final raw = response['trip'];
    if (raw is! Map) throw const FormatException('Invalid trip response');
    return _trip(Map<String, dynamic>.from(raw));
  }

  Map<String, dynamic> _body(TripDraft draft) => {
    'vehicle_id': draft.vehicleId,
    'transport_type': draft.transportType.name,
    'booking_mode': draft.bookingMode.name,
    'departure_at': draft.departureAt?.toUtc().toIso8601String(),
    'arrival_at': draft.arrivalAt?.toUtc().toIso8601String(),
    'seat_capacity': draft.seatCount,
    // `base_price` is what the driver receives; the server adds its commission
    // on top of it when a booking is priced.
    'base_price': draft.fullRoutePrice,
    'minimum_boarding_price': draft.minimumBoardingPrice ?? 0,
    'fare_table': draft.fares.toJson(),
    'paired_trip_id': draft.pairedTripId,
    'stops': [
      for (final point in draft.points)
        {
          'address': point.address,
          'city_id': point.cityId ?? '',
          'latitude': point.latitude ?? 0,
          'longitude': point.longitude ?? 0,
        },
    ],
    'extra_service_codes': [
      for (final offer in draft.extras)
        if (offer.enabled) _serviceCode(offer.service),
      if (draft.parcel.enabled) 'parcel',
    ],
    'parcel': {
      'enabled': draft.parcel.enabled,
      'sizes': draft.parcel.priceBySize.keys.map((size) => size.name).toList(),
      'allowed_without_passenger': draft.parcel.allowedWithoutPassenger,
    },
  };

  DriverTrip _trip(Map<String, dynamic> json) {
    final status = switch (json['status']) {
      'draft' => DriverTripStatus.draft,
      'cancelled' => DriverTripStatus.cancelled,
      _ => DriverTripStatus.published,
    };
    final rawStops = json['stops'] as List? ?? const [];
    final offers = (json['service_offers'] as List? ?? const [])
        .whereType<Map>()
        .map((raw) => Map<String, dynamic>.from(raw))
        .toList(growable: false);
    final seatOffers = <TripExtraOffer>[
      for (final service in tripSeatExtraServices)
        TripExtraOffer(
          service: service,
          enabled: offers.any(
            (offer) => offer['code'] == _serviceCode(service),
          ),
          price: _offerPrice(offers, _serviceCode(service)),
        ),
    ];
    final parcelOffer = offers
        .where((offer) => offer['code'] == 'parcel')
        .firstOrNull;
    final details = parcelOffer?['details'] is Map
        ? Map<String, dynamic>.from(parcelOffer!['details'] as Map)
        : const <String, dynamic>{};
    final rawPrices = details['price_by_size'] is Map
        ? Map<String, dynamic>.from(details['price_by_size'] as Map)
        : const <String, dynamic>{};
    return DriverTrip(
      id: json['id'] as String,
      status: status,
      publishedAt: _date(json['published_at']),
      pairedTripId: _nonEmpty(json['paired_trip_id']),
      draft: TripDraft(
        transportType: json['transport_type'] == 'bus'
            ? PassengerTransportType.bus
            : PassengerTransportType.car,
        points: rawStops
            .whereType<Map>()
            .map(
              (raw) => TripRoutePoint(
                address: raw['address'] as String? ?? '',
                cityId: _nonEmpty(raw['city_id']),
                cityName: _nonEmpty(raw['city_name']),
                latitude: (raw['latitude'] as num?)?.toDouble(),
                longitude: (raw['longitude'] as num?)?.toDouble(),
              ),
            )
            .toList(growable: false),
        departureAt: _date(json['departure_at']),
        arrivalAt: _date(json['arrival_at']),
        seatCount: (json['seat_capacity'] as num?)?.toInt() ?? 0,
        minimumBoardingPrice: (json['minimum_boarding_price'] as num?)?.toInt(),
        fares: TripFareTable.fromJson(json['fare_table']),
        extras: seatOffers,
        parcel: TripParcelOffer(
          enabled: parcelOffer != null,
          priceBySize: _parcelPriceMap(rawPrices),
          allowedWithoutPassenger: details['allowed_without_passenger'] == true,
        ),
        bookingMode: json['booking_mode'] == 'instant'
            ? TripBookingMode.instant
            : TripBookingMode.standard,
        vehicleId: _nonEmpty((json['vehicle'] as Map?)?['id']),
        pairedTripId: _nonEmpty(json['paired_trip_id']),
      ),
      passengerBookings: (json['passenger_bookings'] as List? ?? const [])
          .whereType<Map>()
          .map((raw) => _booking(Map<String, dynamic>.from(raw)))
          .toList(growable: false),
    );
  }

  DriverTripPassengerBooking _booking(Map<String, dynamic> json) {
    final booking = Map<String, dynamic>.from(json['booking'] as Map);
    final passenger = Map<String, dynamic>.from(json['passenger'] as Map);
    final status = booking['status'];
    return DriverTripPassengerBooking(
      id: booking['id'] as String,
      passengerId: passenger['id'] as String,
      passengerName: passenger['name'] as String? ?? '',
      passengerRating: (passenger['rating_avg'] as num?)?.toDouble(),
      passengerReviewsCount: (passenger['reviews_count'] as num?)?.toInt() ?? 0,
      passengerPhone: '',
      passengerTripsCount: 0,
      seatCount: (booking['seat_count'] as num?)?.toInt() ?? 0,
      confirmed: status != 'pending_driver',
      paid: status == 'confirmed' || status == 'completed',
      pickupAddress: json['pickup_address'] as String?,
      dropoffAddress: json['dropoff_address'] as String?,
    );
  }

  static int? _offerPrice(List<Map<String, dynamic>> offers, String code) {
    for (final offer in offers) {
      if (offer['code'] == code) return (offer['price'] as num?)?.toInt();
    }
    return null;
  }

  static String _serviceCode(TripExtraService service) => switch (service) {
    TripExtraService.childSeat => 'child_seat',
    TripExtraService.luggage => 'luggage',
    TripExtraService.pets => 'pets',
    TripExtraService.parcel => 'parcel',
  };

  static ParcelSize? _parcelSize(String value) => switch (value) {
    'small' => ParcelSize.small,
    'medium' => ParcelSize.medium,
    'large' => ParcelSize.large,
    _ => null,
  };

  static Map<ParcelSize, int> _parcelPriceMap(Map<String, dynamic> prices) {
    final result = <ParcelSize, int>{};
    for (final entry in prices.entries) {
      final size = _parcelSize(entry.key);
      if (size != null && entry.value is num) {
        result[size] = (entry.value as num).toInt();
      }
    }
    return result;
  }

  static DateTime? _date(Object? value) {
    final text = value?.toString() ?? '';
    return text.isEmpty ? null : DateTime.parse(text).toLocal();
  }

  static String? _nonEmpty(Object? value) {
    final text = value?.toString() ?? '';
    return text.isEmpty ? null : text;
  }
}
