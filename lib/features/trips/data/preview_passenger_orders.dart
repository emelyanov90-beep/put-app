import 'package:vput/features/trips/domain/passenger_order.dart';
import 'package:vput/features/trips/domain/passenger_trip.dart';

const _previewCarVehicle = TripVehiclePreview(
  brand: 'LADA',
  model: 'Largus',
  plateNumber: 'В 123 ОР 30',
  photoAsset: 'docs/imgs/car.png',
);

const previewPassengerOrders = <PassengerOrder>[
  PassengerOrder(
    id: '1231',
    trip: PassengerTrip(
      id: 'order_trip_seat_1231',
      transportType: PassengerTransportType.bus,
      driverName: 'Виктор О.',
      driverRating: 4.5,
      driverTripsCount: 127,
      distanceKm: 3.2,
      priorityBadge: TripPriorityBadge.top,
      stops: [
        TripStopPreview('Улица Солнечная, дом 1'),
        TripStopPreview('Улица Ленина, дом 5'),
        TripStopPreview('Улица Пушкина, дом 10'),
        TripStopPreview('Улица Лунная, дом 2'),
      ],
      departureLabel: '16 мая, 12:00–15:00',
      detailsDepartureLabel: '15 мая, 08:00',
      arrivalLabel: 'Прибытие ~18:00',
      priceRubles: 600,
      detailsPriceRubles: 1200,
      availableSeats: 10,
      totalSeats: 24,
      services: [
        TripExtraService.luggage,
        TripExtraService.pets,
        TripExtraService.parcel,
      ],
      vehicle: TripVehiclePreview(
        brand: 'Solaris',
        model: 'StarLiner',
        plateNumber: '7841НХ-7',
        photoAsset: 'docs/imgs/car.png',
      ),
    ),
    status: PassengerOrderStatus.seatBooked,
    departureWindowLabel: '16 мая, 12:00–15:00',
    priceRubles: 600,
    passengerSeatCount: 1,
    passengerSeatsAvailable: 10,
    passengerSeatsTotal: 24,
    parcelSizes: ['S', 'M'],
    parcelSlotsAvailable: 2,
    parcelSlotsTotal: 3,
    parcelPriceRubles: 400,
    segmentPriceRubles: 400,
    refundAmountRubles: 1800,
  ),
  PassengerOrder(
    id: '1232',
    trip: PassengerTrip(
      id: 'order_trip_parcel_1232',
      transportType: PassengerTransportType.car,
      driverName: 'Виктор О.',
      driverRating: 4.5,
      driverTripsCount: 127,
      distanceKm: 3.2,
      priorityBadge: TripPriorityBadge.top,
      stops: [
        TripStopPreview('Улица Берёзовая, дом 10'),
        TripStopPreview('Улица Тихая, дом 7'),
      ],
      departureLabel: '16 мая, 12:00–15:00',
      detailsDepartureLabel: '16 мая, 12:00',
      arrivalLabel: 'Прибытие ~15:00',
      priceRubles: 600,
      detailsPriceRubles: 600,
      availableSeats: 1,
      totalSeats: 3,
      services: [TripExtraService.parcel],
      vehicle: _previewCarVehicle,
    ),
    status: PassengerOrderStatus.parcelBooked,
    departureWindowLabel: '16 мая, 12:00–15:00',
    priceRubles: 600,
    parcelSizes: ['S'],
    parcelSlotsAvailable: 1,
    parcelSlotsTotal: 3,
    parcelPriceRubles: 600,
    segmentPriceRubles: 600,
    driverFound: true,
    recentCancellations30d: 1,
    refundAmountRubles: 600,
  ),
  PassengerOrder(
    id: '1233',
    trip: PassengerTrip(
      id: 'order_trip_completed_1233',
      transportType: PassengerTransportType.car,
      driverName: 'Александр П.',
      driverRating: 3.8,
      driverTripsCount: 48,
      distanceKm: 4,
      priorityBadge: TripPriorityBadge.nearest,
      stops: [
        TripStopPreview('Улица Звёздная, дом 3'),
        TripStopPreview('Улица Парковая, дом 9'),
      ],
      departureLabel: '14 мая, 09:00–10:00',
      detailsDepartureLabel: '14 мая, 09:00',
      arrivalLabel: 'Прибытие ~10:00',
      priceRubles: 450,
      detailsPriceRubles: 450,
      availableSeats: 0,
      totalSeats: 3,
      services: [TripExtraService.luggage],
      vehicle: _previewCarVehicle,
    ),
    status: PassengerOrderStatus.completed,
    departureWindowLabel: '14 мая, 09:00–10:00',
    priceRubles: 450,
    passengerSeatCount: 1,
    passengerSeatsAvailable: 0,
    passengerSeatsTotal: 3,
  ),
];

PassengerOrder? findPreviewPassengerOrderById(String id) {
  for (final order in previewPassengerOrders) {
    if (order.id == id) return order;
  }
  return null;
}
