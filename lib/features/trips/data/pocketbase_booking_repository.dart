import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:vput/core/api/pocketbase_provider.dart';
import 'package:vput/core/config/app_config.dart';
import 'package:vput/features/trips/domain/booking_repository.dart';
import 'package:vput/features/trips/domain/passenger_booking_request.dart';

/// No local payment/approval simulation. Only a server action can confirm a booking.
class PocketBaseBookingRepository implements BookingRepository {
  PocketBaseBookingRepository(this._client);
  final PocketBase _client;

  @override
  Future<BookingActionResult> create(PassengerBookingRequest request) =>
      _action('/api/app/bookings', {
        'trip_id': request.tripId,
        'booking_kind': 'passenger',
        'pickup_index': request.pickupIndex,
        'dropoff_index': request.dropoffIndex,
        'seat_count': request.seatCount,
        'extra_service_codes': request.selectedExtras
            .map((s) => s.name == 'childSeat' ? 'child_seat' : s.name)
            .toList(),
      });

  @override
  Future<BookingActionResult> pay(String bookingId) => _action(
    '/api/app/bookings/${Uri.encodeComponent(bookingId)}/pay',
    const {},
  );

  @override
  Future<BookingCancellationResult> cancel(String bookingId) async {
    try {
      final response = await _client
          .send<Map<String, dynamic>>(
            '/api/app/bookings/${Uri.encodeComponent(bookingId)}/cancel',
            method: 'POST',
          )
          .timeout(const Duration(seconds: 15));
      final booking = response['booking'];
      final blocked = response['booking_blocked'];
      final refund = response['refund_amount'];
      if (booking is! Map ||
          booking['id'] != bookingId ||
          booking['status'] != 'cancelled_by_passenger' ||
          blocked is! bool ||
          refund is! int ||
          refund < 0) {
        throw const FormatException();
      }
      return BookingCancellationResult(
        bookingBlocked: blocked,
        refundRequested: booking['payment_status'] == 'refund_requested',
        refundAmountRubles: refund,
      );
    } catch (_) {
      throw const BookingFailure(
        'Не удалось отменить бронирование. Попробуйте ещё раз.',
      );
    }
  }

  Future<BookingActionResult> _action(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _client
          .send<Map<String, dynamic>>(path, method: 'POST', body: body)
          .timeout(const Duration(seconds: 15));
      final data = response['booking'] is Map<String, dynamic>
          ? response['booking'] as Map<String, dynamic>
          : response;
      final id = data['id'];
      final tripId = data['trip_id'];
      final status = switch (data['status']) {
        'pending_driver' => PassengerBookingStatus.pendingDriver,
        'awaiting_payment' => PassengerBookingStatus.awaitingPayment,
        'confirmed' => PassengerBookingStatus.confirmed,
        _ => throw const FormatException('Unknown booking status'),
      };
      final payment = switch (data['payment_status']) {
        'unpaid' => PassengerPaymentStatus.unpaid,
        'paid' => PassengerPaymentStatus.paid,
        _ => throw const FormatException('Unknown payment status'),
      };
      if (id is! String ||
          id.isEmpty ||
          tripId is! String ||
          tripId.isEmpty ||
          ((status == PassengerBookingStatus.confirmed) !=
              (payment == PassengerPaymentStatus.paid))) {
        throw const FormatException('Invalid booking response');
      }
      return BookingActionResult(
        id: id,
        tripId: tripId,
        status: status,
        paymentStatus: payment,
      );
    } on ClientException catch (error) {
      final code = error.response['code'];
      throw BookingFailure(switch (code) {
        'NO_SEATS' => 'Свободных мест больше нет. Выберите другую поездку.',
        'BOOKING_EXISTS' => 'У вас уже есть заявка на эту поездку.',
        'BOOKING_BLOCKED' =>
          'Новые бронирования недоступны до решения администратора.',
        'TRIP_UNAVAILABLE' =>
          'Поездка больше недоступна. Выберите другую поездку.',
        'OWN_TRIP' => 'Нельзя забронировать собственную поездку.',
        _ when error.statusCode == 401 => 'Сессия истекла. Войдите снова.',
        _ => 'Сервис бронирования недоступен. Попробуйте ещё раз.',
      });
    } on TimeoutException {
      throw const BookingFailure(
        'Не удалось получить ответ. Проверьте соединение и повторите попытку.',
      );
    } on FormatException {
      throw const BookingFailure(
        'Не удалось получить состояние бронирования. Попробуйте ещё раз.',
      );
    }
  }
}

class UnconfiguredBookingRepository implements BookingRepository {
  @override
  Future<BookingCancellationResult> cancel(String bookingId) async =>
      throw const BookingFailure(
        'Сервис отмены бронирования недоступен. Попробуйте позже.',
      );
  const UnconfiguredBookingRepository();
  @override
  Future<BookingActionResult> create(PassengerBookingRequest request) async =>
      throw const BookingFailure(
        'Сервис бронирования недоступен. Попробуйте позже.',
      );
  @override
  Future<BookingActionResult> pay(String bookingId) async =>
      throw const BookingFailure('Сервис оплаты недоступен. Попробуйте позже.');
}

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  if (!AppConfig.hasPocketBaseUrl) return const UnconfiguredBookingRepository();
  return PocketBaseBookingRepository(ref.watch(pocketBaseProvider));
});
