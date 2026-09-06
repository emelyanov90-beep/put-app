import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:vput/core/api/pocketbase_provider.dart';
import 'package:vput/core/config/app_config.dart';
import 'package:vput/features/auth/application/preview_session_controller.dart';
import 'package:vput/features/complaints/domain/complaint.dart';

class PocketBaseComplaintRepository implements ComplaintRepository {
  PocketBaseComplaintRepository(this._client);

  final PocketBase _client;

  @override
  Future<List<Complaint>> load() async {
    try {
      final response = await _client
          .send<Map<String, dynamic>>('/api/app/complaints')
          .timeout(const Duration(seconds: 15));
      final items = response['items'];
      if (items is! List) throw const FormatException('Invalid complaints');
      return items
          .whereType<Map>()
          .map((raw) => _fromJson(Map<String, dynamic>.from(raw)))
          .toList(growable: false);
    } on ClientException catch (error) {
      throw ComplaintFailure(
        error.statusCode == 401
            ? 'Сессия истекла. Войдите снова.'
            : 'Не удалось загрузить жалобы. Попробуйте ещё раз.',
      );
    } on TimeoutException {
      throw const ComplaintFailure(
        'Не удалось получить ответ. Проверьте соединение.',
      );
    } on FormatException {
      throw const ComplaintFailure('Не удалось прочитать список жалоб.');
    }
  }

  @override
  Future<Complaint> submit({
    required ComplaintSubject subject,
    required String text,
  }) async {
    try {
      final response = await _client
          .send<Map<String, dynamic>>(
            '/api/app/complaints',
            method: 'POST',
            body: {'subject': complaintSubjectCode(subject), 'text': text},
          )
          .timeout(const Duration(seconds: 15));
      final complaint = response['complaint'];
      if (complaint is! Map) throw const FormatException('Invalid complaint');
      return _fromJson(Map<String, dynamic>.from(complaint));
    } on ClientException catch (error) {
      throw ComplaintFailure(switch (error.response['code']) {
        'INVALID_COMPLAINT' =>
          'Опишите проблему подробнее: не меньше '
              '$complaintMinLength символов.',
        _ when error.statusCode == 401 => 'Сессия истекла. Войдите снова.',
        _ => 'Не удалось отправить жалобу. Попробуйте ещё раз.',
      });
    } on TimeoutException {
      throw const ComplaintFailure(
        'Не удалось получить ответ. Проверьте соединение.',
      );
    } on FormatException {
      throw const ComplaintFailure('Не удалось прочитать ответ сервера.');
    }
  }

  Complaint _fromJson(Map<String, dynamic> json) => Complaint(
    id: json['id'] as String? ?? '',
    subject: complaintSubjectFromCode(json['subject'] as String? ?? 'other'),
    text: json['text'] as String? ?? '',
    status: complaintStatusFromCode(json['status'] as String? ?? 'new'),
    createdAt:
        DateTime.tryParse(json['created'] as String? ?? '')?.toLocal() ??
        DateTime.now(),
    adminComment: json['admin_comment'] as String? ?? '',
  );
}

/// Keeps complaints in memory while the app runs without a backend, so the
/// section is usable in the preview build instead of failing.
class PreviewComplaintRepository implements ComplaintRepository {
  PreviewComplaintRepository();

  final _complaints = <Complaint>[];

  @override
  Future<List<Complaint>> load() async =>
      List.unmodifiable(_complaints.reversed);

  @override
  Future<Complaint> submit({
    required ComplaintSubject subject,
    required String text,
  }) async {
    final complaint = Complaint(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      subject: subject,
      text: text,
      status: ComplaintStatus.newest,
      createdAt: DateTime.now(),
    );
    _complaints.add(complaint);
    return complaint;
  }
}

final complaintRepositoryProvider = Provider<ComplaintRepository>((ref) {
  ref.watch(currentSessionUserIdProvider);
  if (AppConfig.isPreviewMode) return PreviewComplaintRepository();
  return PocketBaseComplaintRepository(ref.watch(pocketBaseProvider));
});
