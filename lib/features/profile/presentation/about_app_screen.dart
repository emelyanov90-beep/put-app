import 'package:flutter/material.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/features/profile/presentation/widgets/profile_section_scaffold.dart';

/// «О приложении»: what «Путь» is, which build the user is running, and the
/// legal documents the same texts are shown from during registration.
class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({
    required this.onBack,
    required this.onTerms,
    required this.onPrivacy,
    super.key,
  });

  /// Kept in step with `version:` in `pubspec.yaml`.
  static const appVersion = '1.0.0';
  static const buildNumber = '1';

  static const termsItemKey = Key('about_terms');
  static const privacyItemKey = Key('about_privacy');

  final VoidCallback onBack;
  final VoidCallback onTerms;
  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context) {
    return ProfileSectionScaffold(
      title: 'О приложении',
      onBack: onBack,
      children: [
        const ProfileCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Путь',
                style: TextStyle(
                  color: AppColors.accentBlack,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Попутные поездки между городами: пассажиры находят место в '
                'машине или автобусе, водители берут попутчиков и посылки.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.33,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const ProfileSectionTitle('Версия'),
        const ProfileCard(
          child: Column(
            children: [
              _InfoRow(label: 'Версия приложения', value: appVersion),
              SizedBox(height: 10),
              _InfoRow(label: 'Сборка', value: buildNumber),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const ProfileSectionTitle('Документы'),
        ProfileCard(
          padded: false,
          child: Column(
            children: [
              _LinkRow(
                rowKey: termsItemKey,
                title: 'Условия использования',
                onTap: onTerms,
              ),
              const Divider(height: 1, color: AppColors.divider),
              _LinkRow(
                rowKey: privacyItemKey,
                title: 'Политика конфиденциальности',
                onTap: onPrivacy,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Оплата в тестовой версии выполняется без списания денег.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.38,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.33,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.accentBlack,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.33,
          ),
        ),
      ],
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.rowKey,
    required this.title,
    required this.onTap,
  });

  final Key rowKey;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: rowKey,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.accentBlack,
                  fontSize: 15,
                  height: 1.33,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
