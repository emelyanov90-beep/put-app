import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum OnboardingRole { driver, passenger }

@immutable
class OnboardingDraft {
  const OnboardingDraft({this.role, this.cityId, this.cityName});

  final OnboardingRole? role;
  final String? cityId;
  final String? cityName;

  OnboardingDraft copyWith({
    OnboardingRole? role,
    String? cityId,
    String? cityName,
  }) {
    return OnboardingDraft(
      role: role ?? this.role,
      cityId: cityId ?? this.cityId,
      cityName: cityName ?? this.cityName,
    );
  }
}

class OnboardingDraftController extends Notifier<OnboardingDraft> {
  @override
  OnboardingDraft build() => const OnboardingDraft();

  void selectRole(OnboardingRole role) {
    state = state.copyWith(role: role);
  }

  void selectCity({required String id, required String name}) {
    state = state.copyWith(cityId: id, cityName: name);
  }
}

final onboardingDraftProvider =
    NotifierProvider<OnboardingDraftController, OnboardingDraft>(
      OnboardingDraftController.new,
    );
