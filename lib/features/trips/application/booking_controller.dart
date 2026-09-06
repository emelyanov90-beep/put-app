import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/features/trips/data/pocketbase_booking_repository.dart';
import 'package:vput/features/trips/domain/booking_repository.dart';
import 'package:vput/features/trips/domain/passenger_booking_request.dart';

class BookingController extends Notifier<AsyncValue<BookingActionResult?>> {
  final _bookingsByTrip = <String, BookingActionResult>{};
  var _generation = 0;
  @override
  AsyncValue<BookingActionResult?> build() {
    _generation++;
    _bookingsByTrip.clear();
    return const AsyncData(null);
  }

  BookingActionResult? forTrip(String id) => _bookingsByTrip[id];

  Future<BookingActionResult?> create(PassengerBookingRequest request) async {
    if (state.isLoading) return null;
    final existing = forTrip(request.tripId);
    if (existing != null) return existing;
    return _run(() => ref.read(bookingRepositoryProvider).create(request));
  }

  Future<BookingActionResult?> createParcel(
    PassengerParcelRequest request,
  ) async {
    if (state.isLoading) return null;
    final existing = forTrip(request.tripId);
    if (existing != null) return existing;
    return _run(
      () => ref.read(bookingRepositoryProvider).createParcel(request),
    );
  }

  Future<BookingActionResult?> pay(BookingActionResult booking) async {
    if (state.isLoading) return null;
    if (booking.isPaid) return booking;
    if (booking.status != PassengerBookingStatus.awaitingPayment) return null;
    return _run(() => ref.read(bookingRepositoryProvider).pay(booking.id));
  }

  Future<BookingActionResult?> _run(
    Future<BookingActionResult> Function() action,
  ) async {
    final generation = _generation;
    state = const AsyncLoading();
    try {
      final result = await action();
      if (!ref.mounted || generation != _generation) return null;
      _bookingsByTrip[result.tripId] = result;
      state = AsyncData(result);
      return result;
    } catch (error, stack) {
      if (!ref.mounted || generation != _generation) return null;
      state = AsyncError(
        error is BookingFailure
            ? error
            : const BookingFailure(
                'Не удалось выполнить действие. Попробуйте ещё раз.',
              ),
        stack,
      );
      return null;
    }
  }
}

final bookingControllerProvider =
    NotifierProvider<BookingController, AsyncValue<BookingActionResult?>>(
      BookingController.new,
    );

class BookingCancellationController
    extends Notifier<AsyncValue<BookingCancellationResult?>> {
  var _generation = 0;
  @override
  AsyncValue<BookingCancellationResult?> build() {
    _generation++;
    return const AsyncData(null);
  }

  Future<BookingCancellationResult?> cancel(String id) async {
    if (state.isLoading) return null;
    final generation = _generation;
    state = const AsyncLoading();
    try {
      final result = await ref.read(bookingRepositoryProvider).cancel(id);
      if (!ref.mounted || generation != _generation) return null;
      state = AsyncData(result);
      return result;
    } catch (error, stack) {
      if (!ref.mounted || generation != _generation) return null;
      state = AsyncError(
        error is BookingFailure
            ? error
            : const BookingFailure(
                'Не удалось отменить бронирование. Попробуйте ещё раз.',
              ),
        stack,
      );
      return null;
    }
  }
}

final bookingCancellationProvider =
    NotifierProvider<
      BookingCancellationController,
      AsyncValue<BookingCancellationResult?>
    >(BookingCancellationController.new);
