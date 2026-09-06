import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum OnboardingRole { driver, passenger }

enum AuthEntryMode { registration, signIn }

@immutable
class OnboardingDraft {
  const OnboardingDraft({
    this.authEntryMode,
    this.phone,
    this.role,
    this.cityId,
    this.cityName,
  });

  final AuthEntryMode? authEntryMode;
  final String? phone;
  final OnboardingRole? role;
  final String? cityId;
  final String? cityName;

  OnboardingDraft copyWith({
    AuthEntryMode? authEntryMode,
    String? phone,
    OnboardingRole? role,
    String? cityId,
    String? cityName,
  }) {
    return OnboardingDraft(
      authEntryMode: authEntryMode ?? this.authEntryMode,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      cityId: cityId ?? this.cityId,
      cityName: cityName ?? this.cityName,
    );
  }
}

class OnboardingDraftController extends Notifier<OnboardingDraft> {
  @override
  OnboardingDraft build() => const OnboardingDraft();

  void beginRegistration() {
    state = const OnboardingDraft(authEntryMode: AuthEntryMode.registration);
  }

  void beginSignIn() {
    state = const OnboardingDraft(authEntryMode: AuthEntryMode.signIn);
  }

  void setPhone(String phone) {
    state = state.copyWith(phone: phone);
  }

  void selectRole(OnboardingRole role) {
    state = state.copyWith(role: role);
  }

  void selectCity({required String id, required String name}) {
    state = state.copyWith(cityId: id, cityName: name);
  }

  void logOut() {
    state = const OnboardingDraft();
  }
}

final onboardingDraftProvider =
    NotifierProvider<OnboardingDraftController, OnboardingDraft>(
      OnboardingDraftController.new,
    );
