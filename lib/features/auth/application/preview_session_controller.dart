import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:vput/core/api/pocketbase_provider.dart';
import 'package:vput/core/config/app_config.dart';
import 'package:vput/features/auth/data/preview_blocked_account.dart';

final initialAuthStateProvider = Provider<bool>((ref) => false);

@immutable
class AuthVerificationResult {
  const AuthVerificationResult({
    required this.profileCompleted,
    required this.record,
  });

  final bool profileCompleted;
  final Map<String, dynamic> record;
}

class AuthFailure implements Exception {
  const AuthFailure(this.message, {this.code});

  final String message;
  final String? code;
}

/// Session state backed by PocketBase in configured builds. The historical
/// provider name is kept so existing widget tests and routes remain stable.
class PreviewSessionController extends Notifier<bool> {
  @override
  bool build() => ref.watch(initialAuthStateProvider);

  Future<void> requestCode(String phone) async {
    if (!AppConfig.hasPocketBaseUrl) return;
    try {
      await ref
          .read(pocketBaseProvider)
          .send<Map<String, dynamic>>(
            '/api/app/auth/request-code',
            method: 'POST',
            body: {'phone': phone},
          );
    } on ClientException catch (error) {
      final code = error.response['code'] as String?;
      throw AuthFailure(
        code == 'INVALID_PHONE'
            ? 'Проверьте номер телефона.'
            : 'Не удалось запросить код. Проверьте соединение.',
        code: code,
      );
    }
  }

  Future<AuthVerificationResult> verifyCode(
    String phone,
    String code, {
    bool previewProfileCompleted = false,
  }) async {
    if (!AppConfig.hasPocketBaseUrl) {
      if (isPreviewBlockedAccount(phone)) {
        throw const AuthFailure(
          'Аккаунт заблокирован.',
          code: 'ACCOUNT_BLOCKED',
        );
      }
      state = true;
      return AuthVerificationResult(
        profileCompleted: previewProfileCompleted,
        record: <String, dynamic>{
          'id': 'preview_user',
          'name': previewProfileCompleted ? 'Александр' : '',
          'primary_role': 'passenger',
          'driver_enabled': false,
          'profile_completed': previewProfileCompleted,
          'rating_count': 0,
        },
      );
    }
    try {
      final response = await ref
          .read(pocketBaseProvider)
          .send<Map<String, dynamic>>(
            '/api/app/auth/verify-code',
            method: 'POST',
            body: {'phone': phone, 'code': code},
          );
      final token = response['token'];
      final record = response['record'];
      if (token is! String || token.isEmpty || record is! Map) {
        throw const FormatException('Invalid auth response');
      }
      final data = Map<String, dynamic>.from(record);
      ref
          .read(pocketBaseProvider)
          .authStore
          .save(token, RecordModel.fromJson(data));
      state = true;
      return AuthVerificationResult(
        profileCompleted: data['profile_completed'] == true,
        record: data,
      );
    } on ClientException catch (error) {
      final code = error.response['code'] as String?;
      throw AuthFailure(switch (code) {
        'INVALID_OTP' => 'Неверный код подтверждения.',
        'ACCOUNT_BLOCKED' => 'Аккаунт заблокирован.',
        _ => 'Не удалось войти. Проверьте соединение.',
      }, code: code);
    } on FormatException {
      throw const AuthFailure('Сервер вернул некорректный ответ.');
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String cityId,
    required String role,
  }) async {
    if (!AppConfig.hasPocketBaseUrl) {
      return {
        'id': 'preview_user',
        'name': name,
        'city_id': cityId,
        'primary_role': role,
        'driver_enabled': role == 'driver',
        'profile_completed': true,
        'rating_count': 0,
      };
    }
    try {
      final client = ref.read(pocketBaseProvider);
      final response = await client.send<Map<String, dynamic>>(
        '/api/app/me',
        method: 'PATCH',
        body: {
          'name': name,
          'city_id': cityId,
          'primary_role': role,
          'driver_enabled': role == 'driver',
        },
      );
      final raw = response['user'];
      if (raw is! Map) throw const FormatException();
      final data = Map<String, dynamic>.from(raw)
        ..['collectionId'] = '_pb_users_auth_'
        ..['collectionName'] = 'users';
      client.authStore.save(client.authStore.token, RecordModel.fromJson(data));
      return data;
    } on ClientException catch (error) {
      throw AuthFailure(
        'Не удалось сохранить профиль. Попробуйте ещё раз.',
        code: error.response['code'] as String?,
      );
    } on FormatException {
      throw const AuthFailure('Сервер вернул некорректный профиль.');
    }
  }

  Future<Map<String, dynamic>> updateRole(String role) async {
    if (!AppConfig.hasPocketBaseUrl) {
      return {
        'id': 'preview_user',
        'primary_role': role,
        'driver_enabled': role == 'driver',
      };
    }
    try {
      final client = ref.read(pocketBaseProvider);
      final body = <String, dynamic>{'primary_role': role};
      if (role == 'driver') body['driver_enabled'] = true;
      final response = await client.send<Map<String, dynamic>>(
        '/api/app/me',
        method: 'PATCH',
        body: body,
      );
      final raw = response['user'];
      if (raw is! Map) throw const FormatException();
      final data = Map<String, dynamic>.from(raw)
        ..['collectionId'] = '_pb_users_auth_'
        ..['collectionName'] = 'users';
      client.authStore.save(client.authStore.token, RecordModel.fromJson(data));
      return data;
    } on ClientException catch (error) {
      throw AuthFailure(
        'Не удалось переключить роль. Попробуйте ещё раз.',
        code: error.response['code'] as String?,
      );
    } on FormatException {
      throw const AuthFailure('Сервер вернул некорректный профиль.');
    }
  }

  void signIn() => state = true;
  void signOut() => state = false;
}

final previewSessionProvider = NotifierProvider<PreviewSessionController, bool>(
  PreviewSessionController.new,
);

/// main() binds this to the real SDK auth store; widget tests need no storage.
final clearStoredAuthProvider = Provider<VoidCallback>((ref) => () {});
