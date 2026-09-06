import 'package:flutter/material.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/features/trips/domain/trip_publication_limits.dart';

/// What the driver chose in the limit dialog.
enum PublicationLimitAction { saveTemplate, cancel }

/// Shown when the driver has already used up today's publications: a car trip
/// runs once a day in each direction, there and back.
class PublicationLimitDialog extends StatelessWidget {
  const PublicationLimitDialog({
    required this.limits,
    required this.usage,
    super.key,
  });

  static const dialogKey = Key('publication_limit_dialog');
  static const saveTemplateButtonKey = Key('publication_limit_save_template');
  static const cancelButtonKey = Key('publication_limit_cancel');

  final TripPublicationLimits limits;
  final TripPublicationUsage usage;

  static Future<PublicationLimitAction?> show(
    BuildContext context, {
    required TripPublicationLimits limits,
    required TripPublicationUsage usage,
  }) {
    return showDialog<PublicationLimitAction>(
      context: context,
      barrierColor: AppColors.accentBlack.withValues(alpha: .4),
      builder: (context) =>
          PublicationLimitDialog(limits: limits, usage: usage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: dialogKey,
      backgroundColor: AppColors.background,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Foundation placeholder: the design shows a 24-hour clock with a
            // warning sign; no such asset is in the repository yet.
            const Center(
              child: Icon(
                Icons.timelapse_rounded,
                size: 64,
                color: AppColors.divider,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Достигнут лимит на сегодня',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.accentBlack,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'На легковой автомобиль можно опубликовать не более '
              '${limits.outboundPerDay} поездки в сутки в двух направлениях '
              '(туда и обратно). Сегодня у вас уже ${usage.publishedToday} '
              '${_publicationsWord(usage.publishedToday)}.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF95969C),
                fontSize: 15,
                height: 1.33,
              ),
            ),
            const SizedBox(height: 20),
            _DirectionProgress(
              label: 'Туда',
              used: usage.publishedOutboundToday,
              total: limits.outboundPerDay,
            ),
            const SizedBox(height: 16),
            _DirectionProgress(
              label: 'Обратно',
              used: usage.publishedReturnToday,
              total: limits.returnPerDay,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: FilledButton(
                key: saveTemplateButtonKey,
                onPressed: () =>
                    Navigator.of(context)
                        .pop(PublicationLimitAction.saveTemplate),
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
                child: const Text('Сохранить как шаблон'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: OutlinedButton(
                key: cancelButtonKey,
                onPressed: () =>
                    Navigator.of(context).pop(PublicationLimitAction.cancel),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brandGreen,
                  side: const BorderSide(color: AppColors.brandGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Отмена'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _publicationsWord(int count) {
    final mod100 = count % 100;
    final mod10 = count % 10;
    if (mod100 >= 11 && mod100 <= 14) return 'публикаций';
    if (mod10 == 1) return 'публикация';
    if (mod10 >= 2 && mod10 <= 4) return 'публикации';
    return 'публикаций';
  }
}

class _DirectionProgress extends StatelessWidget {
  const _DirectionProgress({
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
              '$used/ $total',
              style: const TextStyle(
                color: AppColors.accentBlack,
                fontSize: 15,
                fontWeight: FontWeight.w600,
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
