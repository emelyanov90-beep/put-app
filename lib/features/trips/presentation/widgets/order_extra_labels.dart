import 'package:flutter/material.dart';
import 'package:vput/features/trips/domain/passenger_trip.dart';

/// Name of an extra service in a form-like context («Детское кресло»), used by
/// the wizards where the passenger or the driver switches a service on.
String orderExtraTitle(TripExtraService service) => switch (service) {
  TripExtraService.childSeat => 'Детское кресло',
  TripExtraService.luggage => 'Багаж',
  TripExtraService.pets => 'Животные',
  TripExtraService.parcel => 'Посылка',
};

/// Icon of an extra service, shared by every screen that lists services.
IconData orderExtraIcon(TripExtraService service) => switch (service) {
  TripExtraService.childSeat => Icons.child_friendly_rounded,
  TripExtraService.luggage => Icons.work_rounded,
  TripExtraService.pets => Icons.pets_rounded,
  TripExtraService.parcel => Icons.inventory_2_rounded,
};
