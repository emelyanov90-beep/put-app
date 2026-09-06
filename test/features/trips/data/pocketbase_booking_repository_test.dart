import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:vput/features/trips/data/pocketbase_booking_repository.dart';
import 'package:vput/features/trips/domain/booking_repository.dart';
import 'package:vput/features/trips/domain/passenger_booking_request.dart';

class _Client extends Mock implements PocketBase {}

void main() {
  const request = PassengerBookingRequest(
    tripId: 'trip',
    pickupIndex: 0,
    dropoffIndex: 2,
    seatCount: 1,
    selectedExtras: {},
    amountRubles: 1,
    status: PassengerBookingStatus.confirmed,
    paymentStatus: PassengerPaymentStatus.paid,
  );
  late _Client client;
  late PocketBaseBookingRepository repository;
  void reply(Map<String, dynamic> response) {
    when(
      () => client.send<Map<String, dynamic>>(
        any(),
        method: any(named: 'method'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => response);
  }

  setUp(() {
    client = _Client();
    repository = PocketBaseBookingRepository(client);
  });
  test(
    'create sends selection only and accepts status exclusively from API',
    () async {
      reply({
        'booking': {
          'id': 'booking',
          'trip_id': 'trip',
          'status': 'pending_driver',
          'payment_status': 'unpaid',
        },
      });
      final result = await repository.create(request);
      expect(result.status, PassengerBookingStatus.pendingDriver);
      final body =
          verify(
                () => client.send<Map<String, dynamic>>(
                  '/api/app/bookings',
                  method: 'POST',
                  body: captureAny(named: 'body'),
                ),
              ).captured.single
              as Map;
      expect(
        body.keys,
        unorderedEquals([
          'trip_id',
          'booking_kind',
          'pickup_index',
          'dropoff_index',
          'seat_count',
          'extra_service_codes',
        ]),
      );
      expect(body['seat_count'], 1);
    },
  );
  test('inconsistent payment response never becomes success', () async {
    reply({
      'id': 'booking',
      'trip_id': 'trip',
      'status': 'pending_driver',
      'payment_status': 'paid',
    });
    await expectLater(
      repository.pay('booking'),
      throwsA(isA<BookingFailure>()),
    );
  });
  test(
    'payment uses the custom action and requires confirmed plus paid',
    () async {
      reply({
        'id': 'booking',
        'trip_id': 'trip',
        'status': 'confirmed',
        'payment_status': 'paid',
      });
      expect((await repository.pay('booking')).isPaid, isTrue);
      verify(
        () => client.send<Map<String, dynamic>>(
          '/api/app/bookings/booking/pay',
          method: 'POST',
          body: const {},
        ),
      ).called(1);
    },
  );
  test('no seats is a recoverable business error', () async {
    when(
      () => client.send<Map<String, dynamic>>(
        any(),
        method: any(named: 'method'),
        body: any(named: 'body'),
      ),
    ).thenThrow(
      ClientException(statusCode: 409, response: {'code': 'NO_SEATS'}),
    );
    await expectLater(
      repository.create(request),
      throwsA(
        isA<BookingFailure>().having(
          (e) => e.message,
          'message',
          contains('Свободных мест'),
        ),
      ),
    );
  });
  test(
    'cancellation needs a matching cancelled booking and server refund',
    () async {
      reply({
        'booking': {
          'id': 'booking',
          'status': 'cancelled_by_passenger',
          'payment_status': 'refund_requested',
        },
        'booking_blocked': true,
        'refund_amount': 50,
      });
      final result = await repository.cancel('booking');
      expect(result.bookingBlocked, isTrue);
      expect(result.refundRequested, isTrue);
      expect(result.refundAmountRubles, 50);
      await expectLater(
        repository.cancel('another'),
        throwsA(isA<BookingFailure>()),
      );
    },
  );
}
