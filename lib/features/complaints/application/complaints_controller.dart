import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/core/config/app_config.dart';
import 'package:vput/features/auth/application/preview_session_controller.dart';
import 'package:vput/features/complaints/data/pocketbase_complaint_repository.dart';
import 'package:vput/features/complaints/domain/complaint.dart';

class ComplaintsController extends AsyncNotifier<List<Complaint>> {
  @override
  Future<List<Complaint>> build() {
    final userId = ref.watch(currentSessionUserIdProvider);
    if (!AppConfig.isPreviewMode && userId == null) {
      return Future.value(const <Complaint>[]);
    }
    return ref.watch(complaintRepositoryProvider).load();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(complaintRepositoryProvider).load(),
    );
  }

  /// Returns the failure message when the complaint was not accepted, so the
  /// screen can show it without reading the error state itself.
  Future<String?> submit({
    required ComplaintSubject subject,
    required String text,
  }) async {
    try {
      final complaint = await ref
          .read(complaintRepositoryProvider)
          .submit(subject: subject, text: text);
      state = AsyncData([complaint, ...state.value ?? const <Complaint>[]]);
      return null;
    } on ComplaintFailure catch (error) {
      return error.message;
    }
  }
}

final complaintsProvider =
    AsyncNotifierProvider<ComplaintsController, List<Complaint>>(
      ComplaintsController.new,
    );
