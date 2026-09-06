import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/features/trips/domain/passenger_trip.dart';
import 'package:vput/features/trips/domain/trip_draft.dart';
import 'package:vput/features/trips/data/preview_trip_publication_settings.dart';
import 'package:vput/features/trips/domain/trip_extras.dart';
import 'package:vput/features/trips/domain/trip_route_point.dart';
import 'package:vput/features/vehicles/application/driver_vehicles_controller.dart';
import 'package:vput/features/vehicles/domain/driver_vehicle.dart';

/// Holds the trip a driver is composing. The draft survives navigation between
/// the wizard steps and is only sent to the backend on save or publish.
class TripDraftController extends Notifier<TripDraft> {
  @override
  TripDraft build() => const TripDraft();

  void reset() {
    state = const TripDraft();
  }

  /// Replaces the whole draft, e.g. when an existing trip is opened for editing.
  void load(TripDraft draft) {
    state = draft;
  }

  void setPointAt(int index, TripRoutePoint point) {
    if (index < 0 || index >= state.points.length) return;
    final points = [...state.points]..[index] = point;
    state = state.copyWith(points: points);
  }

  void setOrigin(TripRoutePoint point) => setPointAt(0, point);

  void setDestination(TripRoutePoint point) =>
      setPointAt(state.points.length - 1, point);

  /// Adds a planned stop right before the destination. Existing fares keep
  /// their meaning: they follow the points they were set for, and the legs the
  /// new stop introduces start out unpriced.
  void addStop([TripRoutePoint point = const TripRoutePoint(address: '')]) {
    final insertAt = state.points.length - 1;
    final points = [...state.points]..insert(insertAt, point);
    state = state.copyWith(
      points: points,
      fares: state.fares.withPointInserted(insertAt),
    );
  }

  /// Removes a planned stop. The origin and the destination cannot be removed.
  /// The fares of the legs that ended at that stop go with it.
  void removeStopAt(int index) {
    if (index <= 0 || index >= state.points.length - 1) return;
    final points = [...state.points]..removeAt(index);
    state = state.copyWith(
      points: points,
      fares: state.fares.withPointRemoved(index),
    );
  }

  void setTransportType(PassengerTransportType type) {
    if (state.transportType == type) return;
    state = state.copyWith(transportType: type);
  }

  void setDepartureAt(DateTime moment) {
    state = state.copyWith(departureAt: moment);
    final arrival = state.arrivalAt;
    // The estimated arrival always follows the departure.
    if (arrival != null && !arrival.isAfter(moment)) {
      setArrivalTimeOfDay(hour: arrival.hour, minute: arrival.minute);
    }
  }

  void clearDepartureAt() {
    state = state.copyWith(clearDepartureAt: true);
  }

  /// Sets the estimated arrival from a time of day: the day comes from the
  /// departure and rolls over to the next one when that time has already
  /// passed on the departure day.
  void setArrivalTimeOfDay({required int hour, required int minute}) {
    final departure = state.departureAt;
    if (departure == null) return;
    var arrival = DateTime(
      departure.year,
      departure.month,
      departure.day,
      hour,
      minute,
    );
    if (!arrival.isAfter(departure)) {
      arrival = arrival.add(const Duration(days: 1));
    }
    state = state.copyWith(arrivalAt: arrival);
  }

  void setSeatCount(int value) {
    final maximum = selectedVehicle?.seatCount ?? value;
    state = state.copyWith(
      seatCount: value.clamp(0, maximum < 0 ? 0 : maximum),
    );
  }

  void setFullRoutePrice(int? value) =>
      setLegPrice(0, state.points.length - 1, value);

  /// Prices one pair of points. Every pair is set by hand: the driver does not
  /// give a rate per kilometre, so nothing here is derived from another leg.
  void setLegPrice(int fromIndex, int toIndex, int? value) {
    if (toIndex >= state.points.length) return;
    state = state.copyWith(
      fares: state.fares.withPrice(fromIndex, toIndex, value),
    );
  }

  void setMinimumBoardingPrice(int? value) {
    state = value == null
        ? state.copyWith(clearMinimumBoardingPrice: true)
        : state.copyWith(minimumBoardingPrice: value);
  }

  /// Switches a service on with the price from the catalogue — the driver
  /// does not name it.
  void setExtraEnabled(TripExtraService service, bool enabled) {
    final price = ref.read(tripExtraServicePricesProvider)[service];
    _updateExtra(
      service,
      (extra) => enabled
          ? extra.copyWith(enabled: true, price: price)
          : extra.copyWith(enabled: false, clearPrice: true),
    );
  }

  void setExtraPrice(TripExtraService service, int? price) {
    _updateExtra(
      service,
      (extra) => price == null
          ? extra.copyWith(clearPrice: true)
          : extra.copyWith(price: price),
    );
  }

  /// Applies the parcel settings chosen in the sheet.
  void setParcel(TripParcelOffer parcel) {
    state = state.copyWith(parcel: parcel);
  }

  void setParcelEnabled(bool enabled) {
    state = state.copyWith(
      parcel: enabled
          ? state.parcel.copyWith(enabled: true)
          : const TripParcelOffer(),
    );
  }

  /// Prices a parcel size, or stops accepting it when [price] is `null`.
  void setParcelSizePrice(ParcelSize size, int? price) {
    final prices = {...state.parcel.priceBySize};
    if (price == null) {
      prices.remove(size);
    } else {
      prices[size] = price;
    }
    state = state.copyWith(parcel: state.parcel.copyWith(priceBySize: prices));
  }

  void setParcelWithoutPassenger(bool allowed) {
    state = state.copyWith(
      parcel: state.parcel.copyWith(allowedWithoutPassenger: allowed),
    );
  }

  void setBookingMode(TripBookingMode mode) {
    state = state.copyWith(bookingMode: mode);
  }

  void selectVehicle(String vehicleId) {
    final vehicle = ref
        .read(driverVehiclesProvider.notifier)
        .findById(vehicleId);
    if (vehicle == null || !vehicle.isApproved) return;
    state = state.copyWith(
      vehicleId: vehicleId,
      seatCount: state.seatCount.clamp(0, vehicle.seatCount),
    );
  }

  /// Starts the return trip: same data, route the other way round, departure
  /// time to be entered again.
  void startReturnTrip({String? sourceTripId}) {
    state = state.reversed(pairedTripId: sourceTripId);
  }

  DriverVehicle? get selectedVehicle {
    final id = state.vehicleId;
    if (id == null) return null;
    return ref.read(driverVehiclesProvider.notifier).findById(id);
  }

  void _updateExtra(
    TripExtraService service,
    TripExtraOffer Function(TripExtraOffer extra) update,
  ) {
    final extras = [
      for (final extra in state.extras)
        if (extra.service == service) update(extra) else extra,
    ];
    state = state.copyWith(extras: extras);
  }
}

final tripDraftProvider = NotifierProvider<TripDraftController, TripDraft>(
  TripDraftController.new,
);

/// Vehicle currently chosen for the draft, if any.
final selectedDriverVehicleProvider = Provider<DriverVehicle?>((ref) {
  final vehicleId = ref.watch(tripDraftProvider.select((d) => d.vehicleId));
  if (vehicleId == null) return null;
  ref.watch(driverVehiclesProvider);
  return ref.read(driverVehiclesProvider.notifier).findById(vehicleId);
});

/// Recheck a selected vehicle after edits/deletion instead of trusting its id.
final tripDraftVehicleReadyProvider = Provider<bool>((ref) {
  final draft = ref.watch(tripDraftProvider);
  final vehicle = ref.watch(selectedDriverVehicleProvider);
  return vehicle != null &&
      vehicle.isApproved &&
      vehicle.transportType.name == draft.transportType.name &&
      draft.seatCount <= vehicle.seatCount;
});
