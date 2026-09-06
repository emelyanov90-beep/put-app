import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/app/widgets/screen_header.dart';
import 'package:vput/features/onboarding/application/onboarding_draft_controller.dart';

class RoleSwitchScreen extends StatelessWidget {
  const RoleSwitchScreen({
    required this.currentRole,
    required this.onRoleSelected,
    required this.onBack,
    super.key,
  });

  static const driverOptionKey = Key('role_switch_driver');
  static const passengerOptionKey = Key('role_switch_passenger');

  final OnboardingRole currentRole;
  final ValueChanged<OnboardingRole> onRoleSelected;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    const overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: AppColors.background,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              ScreenHeader(
                title: 'Выберите роль',
                onBack: onBack,
                trailing: const ScreenHeaderOverflowBadge(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    _RoleOption(
                      key: driverOptionKey,
                      label: 'Водитель',
                      selected: currentRole == OnboardingRole.driver,
                      onTap: () => onRoleSelected(OnboardingRole.driver),
                    ),
                    _RoleOption(
                      key: passengerOptionKey,
                      label: 'Пассажир',
                      selected: currentRole == OnboardingRole.passenger,
                      onTap: () => onRoleSelected(OnboardingRole.passenger),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: AppColors.brandGreen,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.accentBlack,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  height: 1.33,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
