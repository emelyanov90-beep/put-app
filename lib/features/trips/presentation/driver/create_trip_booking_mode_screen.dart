import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/features/trips/application/trip_draft_controller.dart';
import 'package:vput/features/trips/data/preview_trip_publication_settings.dart';
import 'package:vput/features/trips/domain/trip_draft.dart';
import 'package:vput/features/trips/presentation/widgets/create_trip_controls.dart';
import 'package:vput/features/trips/presentation/widgets/publication_limit_dialog.dart';

/// Tint of the chosen option in the design.
const _selectedTint = Color(0xFFE9F6EE);

/// Step 6: how a passenger joins the trip, and the actions that finish the
/// wizard — publish it or keep it as a template.
class CreateTripBookingModeScreen extends ConsumerWidget {
  const CreateTripBookingModeScreen({
    required this.onBack,
    required this.onPublish,
    required this.onSaveTemplate,
    this.now,
    super.key,
  });

  static const standardOptionKey = Key('create_trip_booking_standard');
  static const instantOptionKey = Key('create_trip_booking_instant');
  static const publishButtonKey = CreateTripStepScaffold.primaryButtonKey;
  static const saveTemplateButtonKey =
      CreateTripStepScaffold.secondaryButtonKey;

  final VoidCallback onBack;
  final VoidCallback onPublish;
  final VoidCallback onSaveTemplate;

  /// Injectable clock; defaults to the real one.
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moment = now ?? DateTime.now();
    final draft = ref.watch(tripDraftProvider);
    final controller = ref.read(tripDraftProvider.notifier);
    final limits = ref.watch(tripPublicationLimitsProvider);
    final usage = ref.watch(tripPublicationUsageProvider);
    // The limit is checked on tap, as in the design: the button stays active
    // and the dialog explains what is left for today.
    final block = usage.blockFor(limits, isReturn: draft.pairedTripId != null);

    return CreateTripStepScaffold(
      step: 6,
      onBack: onBack,
      primaryLabel: 'Опубликовать поездку',
      onPrimary:
          draft.canPublish(now: moment) &&
              ref.watch(tripDraftVehicleReadyProvider)
          ? () async {
              if (block == null) {
                onPublish();
                return;
              }
              final action = await PublicationLimitDialog.show(
                context,
                limits: limits,
                usage: usage,
              );
              if (context.mounted &&
                  action == PublicationLimitAction.saveTemplate) {
                onSaveTemplate();
              }
            }
          : null,
      secondaryLabel: 'Сохранить шаблон',
      onSecondary: draft.canSave ? onSaveTemplate : null,
      children: [
        CreateTripSection(
          title: 'Тип бронирования',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BookingOption(
                optionKey: standardOptionKey,
                title: 'Стандартное',
                subtitle: 'Вы рассматриваете каждую заявку отдельно',
                bullets: const [
                  'Вы получаете уведомление о заявке',
                  'Можете перейти в профиль пассажира',
                  'Подтверждаете или отклоняете бронь',
                  'После подтверждения пассажир оплачивает',
                ],
                selected: draft.bookingMode == TripBookingMode.standard,
                onTap: () =>
                    controller.setBookingMode(TripBookingMode.standard),
              ),
              const SizedBox(height: 12),
              _BookingOption(
                optionKey: instantOptionKey,
                title: 'Быстрое бронирование',
                subtitle: 'Без подтверждения каждой заявки',
                bullets: const [
                  'Пассажир сразу оплачивает место',
                  'Подтверждение не требуется',
                  'Подходит для постоянных маршрутов',
                ],
                selected: draft.bookingMode == TripBookingMode.instant,
                onTap: () => controller.setBookingMode(TripBookingMode.instant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BookingOption extends StatelessWidget {
  const _BookingOption({
    required this.optionKey,
    required this.title,
    required this.subtitle,
    required this.bullets,
    required this.selected,
    required this.onTap,
  });

  final Key optionKey;
  final String title;
  final String subtitle;
  final List<String> bullets;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        key: optionKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? _selectedTint : AppColors.accentWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.brandGreen : AppColors.divider,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.accentBlack,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.33,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Color(0xFF95969C),
                            fontSize: 13,
                            height: 1.38,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _RadioMark(selected: selected),
                ],
              ),
              const SizedBox(height: 12),
              for (final bullet in bullets) ...[
                if (bullet != bullets.first) const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6, right: 8),
                      child: SizedBox.square(
                        dimension: 4,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xFF95969C),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        bullet,
                        style: const TextStyle(
                          color: Color(0xFF95969C),
                          fontSize: 13,
                          height: 1.38,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioMark extends StatelessWidget {
  const _RadioMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 20,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(width: 2, color: AppColors.brandGreen),
        ),
        child: selected
            ? const Padding(
                padding: EdgeInsets.all(3.5),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.brandGreen,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
