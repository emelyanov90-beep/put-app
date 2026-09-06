import 'package:flutter/foundation.dart';

enum ComplaintSubject { trip, driver, passenger, payment, app, other }

enum ComplaintStatus { newest, inReview, resolved, rejected }

@immutable
class Complaint {
  const Complaint({
    required this.id,
    required this.subject,
    required this.text,
    required this.status,
    required this.createdAt,
    this.adminComment = '',
  });

  final String id;
  final ComplaintSubject subject;
  final String text;
  final ComplaintStatus status;
  final DateTime createdAt;
  final String adminComment;

  String get statusLabel => switch (status) {
    ComplaintStatus.newest => 'Отправлена',
    ComplaintStatus.inReview => 'На рассмотрении',
    ComplaintStatus.resolved => 'Решена',
    ComplaintStatus.rejected => 'Отклонена',
  };
}

String complaintSubjectLabel(ComplaintSubject subject) => switch (subject) {
  ComplaintSubject.trip => 'Поездка',
  ComplaintSubject.driver => 'Водитель',
  ComplaintSubject.passenger => 'Пассажир',
  ComplaintSubject.payment => 'Оплата',
  ComplaintSubject.app => 'Приложение',
  ComplaintSubject.other => 'Другое',
};

String complaintSubjectCode(ComplaintSubject subject) => switch (subject) {
  ComplaintSubject.trip => 'trip',
  ComplaintSubject.driver => 'driver',
  ComplaintSubject.passenger => 'passenger',
  ComplaintSubject.payment => 'payment',
  ComplaintSubject.app => 'app',
  ComplaintSubject.other => 'other',
};

ComplaintSubject complaintSubjectFromCode(String code) => switch (code) {
  'trip' => ComplaintSubject.trip,
  'driver' => ComplaintSubject.driver,
  'passenger' => ComplaintSubject.passenger,
  'payment' => ComplaintSubject.payment,
  'app' => ComplaintSubject.app,
  _ => ComplaintSubject.other,
};

ComplaintStatus complaintStatusFromCode(String code) => switch (code) {
  'in_review' => ComplaintStatus.inReview,
  'resolved' => ComplaintStatus.resolved,
  'rejected' => ComplaintStatus.rejected,
  _ => ComplaintStatus.newest,
};

/// Minimum length the server enforces, mirrored so the button can be disabled
/// before a request is sent.
const complaintMinLength = 10;
const complaintMaxLength = 2000;

abstract interface class ComplaintRepository {
  Future<List<Complaint>> load();
  Future<Complaint> submit({
    required ComplaintSubject subject,
    required String text,
  });
}

class ComplaintFailure implements Exception {
  const ComplaintFailure(this.message);
  final String message;
}
