import 'package:vput/features/trips/domain/trip_fare_table.dart';

/// Builds a fare table from `[from, to]: price` entries, so tests can state a
/// route's fares as plainly as the driver enters them.
TripFareTable fares(Map<List<int>, int> entries) => TripFareTable({
  for (final entry in entries.entries)
    TripFareLeg(entry.key.first, entry.key.last): entry.value,
});
