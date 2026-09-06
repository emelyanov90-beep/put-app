import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/core/config/app_config.dart';
import 'package:vput/features/auth/application/preview_session_controller.dart';
import 'package:vput/features/trips/data/preview_trip_catalog_repository.dart';
import 'package:vput/features/trips/domain/passenger_trip.dart';

enum PassengerTripSearchStatus { loading, empty, data, error }

@immutable
class PassengerTripSearchState {
  const PassengerTripSearchState({
    this.transportType = PassengerTransportType.car,
    this.status = PassengerTripSearchStatus.empty,
    this.trips = const [],
    this.originQuery = '',
    this.destinationQuery = '',
  });

  final PassengerTransportType transportType;
  final PassengerTripSearchStatus status;
  final List<PassengerTrip> trips;
  final String originQuery;
  final String destinationQuery;

  bool get hasFilters =>
      originQuery.trim().isNotEmpty || destinationQuery.trim().isNotEmpty;

  PassengerTripSearchState copyWith({
    PassengerTransportType? transportType,
    PassengerTripSearchStatus? status,
    List<PassengerTrip>? trips,
    String? originQuery,
    String? destinationQuery,
  }) {
    return PassengerTripSearchState(
      transportType: transportType ?? this.transportType,
      status: status ?? this.status,
      trips: trips ?? this.trips,
      originQuery: originQuery ?? this.originQuery,
      destinationQuery: destinationQuery ?? this.destinationQuery,
    );
  }
}

class PassengerTripSearchController extends Notifier<PassengerTripSearchState> {
  var _generation = 0;

  @override
  PassengerTripSearchState build() {
    final userId = ref.watch(currentSessionUserIdProvider);
    if (!AppConfig.isPreviewMode && userId == null) {
      return const PassengerTripSearchState();
    }
    unawaited(
      Future<void>.microtask(() => _startLoad(PassengerTransportType.car)),
    );
    return const PassengerTripSearchState(
      transportType: PassengerTransportType.car,
      status: PassengerTripSearchStatus.loading,
    );
  }

  void selectTransport(PassengerTransportType transportType) {
    if (state.transportType == transportType) return;
    _startLoad(
      transportType,
      originQuery: state.originQuery,
      destinationQuery: state.destinationQuery,
    );
  }

  void applyFilters({required String origin, required String destination}) {
    _startLoad(
      state.transportType,
      originQuery: origin.trim(),
      destinationQuery: destination.trim(),
    );
  }

  void clearFilters() {
    _startLoad(state.transportType);
  }

  /// Re-runs the current search, keeping the active transport type and filters.
  void retry() {
    _startLoad(
      state.transportType,
      originQuery: state.originQuery,
      destinationQuery: state.destinationQuery,
    );
  }

  void _startLoad(
    PassengerTransportType transportType, {
    String originQuery = '',
    String destinationQuery = '',
  }) {
    final generation = ++_generation;
    state = PassengerTripSearchState(
      transportType: transportType,
      status: PassengerTripSearchStatus.loading,
      originQuery: originQuery,
      destinationQuery: destinationQuery,
    );
    unawaited(
      _load(
        generation,
        transportType,
        originQuery: originQuery,
        destinationQuery: destinationQuery,
      ),
    );
  }

  Future<void> _load(
    int generation,
    PassengerTransportType transportType, {
    required String originQuery,
    required String destinationQuery,
  }) async {
    try {
      final origin = originQuery;
      final destination = destinationQuery;
      final allTrips = await ref
          .read(tripCatalogRepositoryProvider)
          .search(transportType);
      if (!ref.mounted || generation != _generation) return;
      final normalizedOrigin = origin.toLowerCase();
      final normalizedDestination = destination.toLowerCase();
      final trips = allTrips
          .where((trip) {
            final matchesOrigin =
                normalizedOrigin.isEmpty ||
                trip.origin.address.toLowerCase().contains(normalizedOrigin);
            final matchesDestination =
                normalizedDestination.isEmpty ||
                trip.destination.address.toLowerCase().contains(
                  normalizedDestination,
                );
            return matchesOrigin && matchesDestination;
          })
          .toList(growable: false);
      state = PassengerTripSearchState(
        transportType: transportType,
        status: trips.isEmpty
            ? PassengerTripSearchStatus.empty
            : PassengerTripSearchStatus.data,
        trips: trips,
        originQuery: origin,
        destinationQuery: destination,
      );
    } catch (_) {
      if (!ref.mounted || generation != _generation) return;
      state = PassengerTripSearchState(
        transportType: transportType,
        status: PassengerTripSearchStatus.error,
        originQuery: originQuery,
        destinationQuery: destinationQuery,
      );
    }
  }
}

final passengerTripSearchProvider =
    NotifierProvider<PassengerTripSearchController, PassengerTripSearchState>(
      PassengerTripSearchController.new,
    );
