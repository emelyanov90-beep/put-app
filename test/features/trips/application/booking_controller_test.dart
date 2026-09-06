import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/trips/application/booking_controller.dart';
import 'package:vput/features/trips/data/pocketbase_booking_repository.dart';
import 'package:vput/features/trips/domain/booking_repository.dart';
import 'package:vput/features/trips/domain/passenger_booking_request.dart';

const request = PassengerBookingRequest(
  tripId: 'trip',
  pickupIndex: 0,
  dropoffIndex: 1,
  seatCount: 1,
  selectedExtras: {},
  amountRubles: 1200,
  status: PassengerBookingStatus.pendingDriver,
  paymentStatus: PassengerPaymentStatus.unpaid,
);

class FakeRepository implements BookingRepository {
  @override
  Future<BookingCancellationResult> cancel(String bookingId) async =>
      const BookingCancellationResult(
        bookingBlocked: false,
        refundRequested: true,
        refundAmountRubles: 50,
      );
  final pending = Completer<BookingActionResult>();
  int creates = 0;
  int payments = 0;
  @override
  Future<BookingActionResult> create(PassengerBookingRequest request) {
    creates++;
    return pending.future;
  }

  @override
  Future<BookingActionResult> pay(String bookingId) async {
    payments++;
    return const BookingActionResult(
      id: 'booking',
      tripId: 'trip',
      status: PassengerBookingStatus.confirmed,
      paymentStatus: PassengerPaymentStatus.paid,
    );
  }
}

void main() {
  test('duplicate taps and revisits do not create a second request', () async {
    final repository = FakeRepository();
    final container = ProviderContainer(
      overrides: [bookingRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final controller = container.read(bookingControllerProvider.notifier);
    final first = controller.create(request);
    expect(container.read(bookingControllerProvider).isLoading, isTrue);
    expect(await controller.create(request), isNull);
    repository.pending.complete(
      const BookingActionResult(
        id: 'booking',
        tripId: 'trip',
        status: PassengerBookingStatus.pendingDriver,
        paymentStatus: PassengerPaymentStatus.unpaid,
      ),
    );
    final booking = (await first)!;
    expect(booking.isPaid, isFalse);
    expect(await controller.pay(booking), isNull);
    expect(repository.payments, 0);
    await controller.create(request);
    expect(repository.creates, 1);
  });
  test(
    'instant awaiting payment needs a server result before showing paid',
    () async {
      final repository = FakeRepository();
      final container = ProviderContainer(
        overrides: [bookingRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final controller = container.read(bookingControllerProvider.notifier);
      repository.pending.complete(
        const BookingActionResult(
          id: 'booking',
          tripId: 'trip',
          status: PassengerBookingStatus.awaitingPayment,
          paymentStatus: PassengerPaymentStatus.unpaid,
        ),
      );
      final booking = (await controller.create(request))!;
      expect(booking.isPaid, isFalse);
      final paid = (await controller.pay(booking))!;
      expect(paid.isPaid, isTrue);
      await controller.pay(paid);
      expect(repository.payments, 1);
    },
  );
  test(
    'unconfigured backend produces recoverable error and never succeeds',
    () async {
      final container = ProviderContainer(
        overrides: [
          bookingRepositoryProvider.overrideWithValue(
            const UnconfiguredBookingRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(bookingControllerProvider.notifier);
      expect(await controller.create(request), isNull);
      expect(container.read(bookingControllerProvider).hasError, isTrue);
      expect(controller.forTrip('trip'), isNull);
      expect(await controller.create(request), isNull);
    },
  );
  test(
    'completion after logout does not repopulate the next user session',
    () async {
      final repository = FakeRepository();
      final container = ProviderContainer(
        overrides: [bookingRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final pending = container
          .read(bookingControllerProvider.notifier)
          .create(request);
      container.invalidate(bookingControllerProvider);
      container.read(bookingControllerProvider);
      repository.pending.complete(
        const BookingActionResult(
          id: 'booking',
          tripId: 'trip',
          status: PassengerBookingStatus.pendingDriver,
          paymentStatus: PassengerPaymentStatus.unpaid,
        ),
      );
      expect(await pending, isNull);
      expect(
        container.read(bookingControllerProvider.notifier).forTrip('trip'),
        isNull,
      );
    },
  );
}
