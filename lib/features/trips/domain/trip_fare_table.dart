import 'package:flutter/foundation.dart';

/// One sellable leg of a route, addressed by the positions of its two points.
@immutable
class TripFareLeg {
  const TripFareLeg(this.fromIndex, this.toIndex);

  final int fromIndex;
  final int toIndex;

  /// Storage key of the leg, e.g. `0-2`.
  String get key => '$fromIndex-$toIndex';

  static TripFareLeg? parseKey(String key) {
    final parts = key.split('-');
    if (parts.length != 2) return null;
    final from = int.tryParse(parts[0]);
    final to = int.tryParse(parts[1]);
    if (from == null || to == null || from < 0 || to <= from) return null;
    return TripFareLeg(from, to);
  }

  @override
  bool operator ==(Object other) =>
      other is TripFareLeg &&
      other.fromIndex == fromIndex &&
      other.toIndex == toIndex;

  @override
  int get hashCode => Object.hash(fromIndex, toIndex);

  @override
  String toString() => 'TripFareLeg($key)';
}

/// Fares the driver set for the legs of a route.
///
/// Every pair of points may carry its own price — the driver does not set a
/// rate per kilometre, because a short leg is deliberately dearer per kilometre
/// than a long one. So a fare is always the one entered for that exact pair and
/// is never derived by adding shorter legs together.
@immutable
class TripFareTable {
  const TripFareTable([this.prices = const {}]);

  final Map<TripFareLeg, int> prices;

  bool get isEmpty => prices.isEmpty;

  int? priceFor(int fromIndex, int toIndex) =>
      prices[TripFareLeg(fromIndex, toIndex)];

  /// Returns a copy with the leg priced, or with the price removed when
  /// [value] is `null`.
  TripFareTable withPrice(int fromIndex, int toIndex, int? value) {
    if (fromIndex < 0 || toIndex <= fromIndex) return this;
    final next = Map<TripFareLeg, int>.of(prices);
    final leg = TripFareLeg(fromIndex, toIndex);
    if (value == null) {
      next.remove(leg);
    } else {
      next[leg] = value;
    }
    return TripFareTable(next);
  }

  /// Every pair of points of a route with [pointCount] points, ordered the way
  /// the pricing screen lists them: all legs starting at the first point, then
  /// the legs starting at the next one, and so on.
  static List<TripFareLeg> legsFor(int pointCount) => [
    for (var from = 0; from < pointCount - 1; from++)
      for (var to = from + 1; to < pointCount; to++) TripFareLeg(from, to),
  ];

  /// Re-addresses the fares after a point was inserted at [index]: every point
  /// at or after it moves one position further, and the legs move with it.
  TripFareTable withPointInserted(int index) {
    int shift(int position) => position >= index ? position + 1 : position;
    return TripFareTable({
      for (final entry in prices.entries)
        TripFareLeg(shift(entry.key.fromIndex), shift(entry.key.toIndex)):
            entry.value,
    });
  }

  /// Re-addresses the fares after the point at [index] was removed. Legs that
  /// ended at that point disappear with it.
  TripFareTable withPointRemoved(int index) {
    int shift(int position) => position > index ? position - 1 : position;
    return TripFareTable({
      for (final entry in prices.entries)
        if (entry.key.fromIndex != index && entry.key.toIndex != index)
          TripFareLeg(shift(entry.key.fromIndex), shift(entry.key.toIndex)):
              entry.value,
    });
  }

  /// Drops the legs that no longer exist on a route with [pointCount] points.
  TripFareTable trimmedTo(int pointCount) => TripFareTable({
    for (final entry in prices.entries)
      if (entry.key.toIndex < pointCount) entry.key: entry.value,
  });

  Map<String, int> toJson() => {
    for (final entry in prices.entries) entry.key.key: entry.value,
  };

  static TripFareTable fromJson(dynamic raw) {
    if (raw is! Map) return const TripFareTable();
    final prices = <TripFareLeg, int>{};
    for (final entry in raw.entries) {
      final leg = TripFareLeg.parseKey(entry.key.toString());
      final price = entry.value;
      if (leg == null || price is! num) continue;
      prices[leg] = price.toInt();
    }
    return TripFareTable(prices);
  }

  @override
  bool operator ==(Object other) =>
      other is TripFareTable && mapEquals(other.prices, prices);

  @override
  int get hashCode => Object.hashAllUnordered([
    for (final entry in prices.entries) Object.hash(entry.key, entry.value),
  ]);
}
