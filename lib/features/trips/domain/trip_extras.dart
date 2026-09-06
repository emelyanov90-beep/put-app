import 'package:flutter/foundation.dart';
import 'package:vput/features/trips/domain/passenger_trip.dart';

/// Parcel size the driver agrees to carry. Maximum dimensions and weight of
/// every size come from [ParcelSizeSpec].
enum ParcelSize { small, medium, large }

/// Limits shown next to a parcel size. The concrete numbers are server data
/// (`extra_services` catalog), not a UI constant.
@immutable
class ParcelSizeSpec {
  const ParcelSizeSpec({
    required this.size,
    required this.title,
    required this.dimensionsLabel,
    required this.maxWeightKg,
    required this.priceRubles,
  });

  final ParcelSize size;
  final String title;
  final String dimensionsLabel;
  final int maxWeightKg;

  /// Price of the size, set by the platform rather than by the driver.
  final int priceRubles;
}

/// Extra service the driver offers on a trip, with its own price in rubles.
///
/// Prices are stored per service (`trip_extra_services.price`) instead of
/// boolean flags on the trip itself.
@immutable
class TripExtraOffer {
  const TripExtraOffer({
    required this.service,
    this.enabled = false,
    this.price,
  });

  final TripExtraService service;
  final bool enabled;
  final int? price;

  bool get isValid => !enabled || (price != null && price! >= 0);

  TripExtraOffer copyWith({
    bool? enabled,
    int? price,
    bool clearPrice = false,
  }) {
    return TripExtraOffer(
      service: service,
      enabled: enabled ?? this.enabled,
      price: clearPrice ? null : price ?? this.price,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TripExtraOffer &&
        other.service == service &&
        other.enabled == enabled &&
        other.price == price;
  }

  @override
  int get hashCode => Object.hash(service, enabled, price);
}

/// Parcel service settings: a price per accepted size, plus the option to take
/// a parcel on a trip nobody rides along with.
@immutable
class TripParcelOffer {
  const TripParcelOffer({
    this.enabled = false,
    this.priceBySize = const <ParcelSize, int>{},
    this.allowedWithoutPassenger = false,
  });

  final bool enabled;
  final Map<ParcelSize, int> priceBySize;
  final bool allowedWithoutPassenger;

  /// A size is offered when the driver priced it.
  bool acceptsSize(ParcelSize size) => priceBySize.containsKey(size);

  bool get isValid => !enabled || priceBySize.isNotEmpty;

  TripParcelOffer copyWith({
    bool? enabled,
    Map<ParcelSize, int>? priceBySize,
    bool? allowedWithoutPassenger,
  }) {
    return TripParcelOffer(
      enabled: enabled ?? this.enabled,
      priceBySize: priceBySize ?? this.priceBySize,
      allowedWithoutPassenger:
          allowedWithoutPassenger ?? this.allowedWithoutPassenger,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TripParcelOffer &&
        other.enabled == enabled &&
        other.allowedWithoutPassenger == allowedWithoutPassenger &&
        mapEquals(other.priceBySize, priceBySize);
  }

  @override
  int get hashCode => Object.hash(
    enabled,
    allowedWithoutPassenger,
    Object.hashAll(
      priceBySize.entries.map((entry) => Object.hash(entry.key, entry.value)),
    ),
  );
}
