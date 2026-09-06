import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/features/trips/data/preview_trip_publication_settings.dart';
import 'package:vput/features/trips/domain/trip_publication_limits.dart';

/// Success state after publishing, with what is left of today's and this
/// week's publication limits.
class TripPublishedScreen extends ConsumerWidget {
  const TripPublishedScreen({
    required this.onMyTrips,
    this.isPreview = false,
    super.key,
  });

  static const myTripsButtonKey = Key('trip_published_my_trips');
  static const limitsCardKey = Key('trip_published_limits');

  final VoidCallback onMyTrips;
  final bool isPreview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limits = ref.watch(tripPublicationLimitsProvider);
    final usage = ref.watch(tripPublicationUsageProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _SuccessMark(),
                      const SizedBox(height: 20),
                      Text(
                        isPreview
                            ? 'Тестовая поездка создана'
                            : 'Заказ опубликован!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.accentBlack,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          height: 1.27,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isPreview
                            ? 'Другие пользователи пока её не видят.'
                            : 'Пассажиры уже видят ваш заказ. Ждём отклик!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF95969C),
                          fontSize: 15,
                          height: 1.33,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _LimitsCard(limits: limits, usage: usage),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                height: 48,
                width: double.infinity,
                child: FilledButton(
                  key: myTripsButtonKey,
                  onPressed: onMyTrips,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandGreen,
                    foregroundColor: AppColors.accentWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Мои заказы'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessMark extends StatelessWidget {
  const _SuccessMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 88,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xFFE9F6EE),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: SizedBox.square(
            dimension: 56,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.brandGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 28,
                color: AppColors.accentWhite,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LimitsCard extends StatelessWidget {
  const _LimitsCard({required this.limits, required this.usage});

  final TripPublicationLimits limits;
  final TripPublicationUsage usage;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: TripPublishedScreen.limitsCardKey,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'Лимит публикаций',
            style: TextStyle(
              color: AppColors.accentBlack,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.33,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _LimitBar(
                  label: 'Сегодня',
                  used: usage.publishedToday,
                  total: limits.perDay,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _LimitBar(
                  label: 'На неделе',
                  used: usage.publishedThisWeek,
                  total: limits.perWeek,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LimitBar extends StatelessWidget {
  const _LimitBar({
    required this.label,
    required this.used,
    required this.total,
  });

  final String label;
  final int used;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF95969C),
                  fontSize: 15,
                  height: 1.33,
                ),
              ),
            ),
            Text(
              '$used / $total',
              style: const TextStyle(
                color: Color(0xFF95969C),
                fontSize: 15,
                height: 1.33,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : (used / total).clamp(0, 1).toDouble(),
            minHeight: 4,
            backgroundColor: AppColors.divider,
            valueColor: const AlwaysStoppedAnimation(AppColors.brandGreen),
          ),
        ),
      ],
    );
  }
}
