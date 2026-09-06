import 'package:vput/features/trips/domain/trip_extras.dart';

/// Preview parcel catalogue: sizes, their limits and prices.
///
/// Foundation placeholder: the real values belong to the server
/// `extra_services` catalogue, the driver only picks the sizes they carry.
const previewParcelSizeSpecs = <ParcelSizeSpec>[
  ParcelSizeSpec(
    size: ParcelSize.small,
    title: 'Маленькая',
    dimensionsLabel: 'Конверты, ключи…',
    maxWeightKg: 3,
    priceRubles: 150,
  ),
  ParcelSizeSpec(
    size: ParcelSize.medium,
    title: 'Средняя',
    dimensionsLabel: 'до 50/40/30 до 10 кг',
    maxWeightKg: 10,
    priceRubles: 250,
  ),
  ParcelSizeSpec(
    size: ParcelSize.large,
    title: 'Большая',
    dimensionsLabel: 'до 80/60/50 до 30 кг',
    maxWeightKg: 30,
    priceRubles: 350,
  ),
];

ParcelSizeSpec previewParcelSizeSpec(ParcelSize size) =>
    previewParcelSizeSpecs.firstWhere((spec) => spec.size == size);

/// The most a parcel can cost on a trip, shown as «до 350₽» before a size is
/// chosen.
int get previewMaxParcelPrice => previewParcelSizeSpecs
    .map((spec) => spec.priceRubles)
    .reduce((a, b) => a > b ? a : b);
