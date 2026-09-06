import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/features/trips/domain/passenger_order_draft.dart';
import 'package:vput/features/trips/domain/trip_route_point.dart';

class PassengerOrderDraftController extends Notifier<PassengerOrderDraft> {
  @override
  PassengerOrderDraft build() => const PassengerOrderDraft();

  void reset() {
    state = const PassengerOrderDraft();
  }

  void setPointAt(int index, TripRoutePoint point) {
    if (index < 0 || index >= state.points.length) return;
    final points = [...state.points]..[index] = point;
    state = state.copyWith(points: points);
  }

  void addStop([TripRoutePoint point = const TripRoutePoint(address: '')]) {
    final points = [...state.points]..insert(state.points.length - 1, point);
    state = state.copyWith(points: points);
  }

  void removeStopAt(int index) {
    if (index <= 0 || index >= state.points.length - 1) return;
    final points = [...state.points]..removeAt(index);
    state = state.copyWith(points: points);
  }

  void setDepartureDay(DateTime day, {required DateTime now}) {
    final current = state.departureAt;
    final next = current == null
        ? DateTime(day.year, day.month, day.day, 8)
        : DateTime(day.year, day.month, day.day, current.hour, current.minute);
    state = state.copyWith(
      departureAt: next.isAfter(now) ? next : null,
      clearArrivalAt: true,
    );
  }

  void setDepartureTime({required int hour, required int minute}) {
    final departure = state.departureAt;
    if (departure == null) return;
    state = state.copyWith(
      departureAt: DateTime(
        departure.year,
        departure.month,
        departure.day,
        hour,
        minute,
      ),
      clearArrivalAt: true,
    );
  }

  void setArrivalTime({required int hour, required int minute}) {
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

  void setPassengerCount(int value) {
    state = state.copyWith(passengerCount: value.clamp(1, 8));
  }
}

final passengerOrderDraftProvider =
    NotifierProvider<PassengerOrderDraftController, PassengerOrderDraft>(
      PassengerOrderDraftController.new,
    );
