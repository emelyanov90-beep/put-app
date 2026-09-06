import 'package:flutter/material.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/core/utils/russian_date_labels.dart';
import 'package:vput/features/trips/application/trip_draft_controller.dart';
import 'package:vput/features/trips/domain/trip_departure_slots.dart';

/// Day picker of the wizard.
///
/// The app ships without localization delegates, so the dates are listed in
/// Russian here instead of through `showDatePicker`.
class TripDatePickerSheet extends StatelessWidget {
  const TripDatePickerSheet({
    required this.now,
    required this.selectedDay,
    this.dayCount = 30,
    super.key,
  });

  static const sheetKey = Key('trip_date_sheet');

  static Key dayKey(int index) => Key('trip_date_sheet_day_$index');

  final DateTime now;
  final DateTime? selectedDay;
  final int dayCount;

  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime now,
    DateTime? selectedDay,
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) =>
          TripDatePickerSheet(now: now, selectedDay: selectedDay),
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = List.generate(
      dayCount,
      (index) => DateTime(now.year, now.month, now.day + index),
    );

    return _SheetFrame(
      sheetKey: sheetKey,
      title: 'Дата выезда',
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: days.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, color: AppColors.divider),
        itemBuilder: (context, index) {
          final day = days[index];
          final selected =
              selectedDay != null &&
              RussianDateLabels.isSameDay(day, selectedDay!);
          return ListTile(
            key: dayKey(index),
            onTap: () => Navigator.of(context).pop(day),
            title: Text(
              RussianDateLabels.relativeDay(day, now: now),
              style: TextStyle(
                color: AppColors.accentBlack,
                fontSize: 15,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
            subtitle: Text(
              RussianDateLabels.dayAndMonth(day),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            trailing: selected
                ? const Icon(
                    Icons.check_rounded,
                    color: AppColors.brandGreen,
                    size: 20,
                  )
                : null,
          );
        },
      ),
    );
  }
}

/// Time picker of the wizard: 30 minute slots only.
class TripTimePickerSheet extends StatelessWidget {
  const TripTimePickerSheet({
    required this.title,
    required this.slots,
    this.selectedLabel,
    super.key,
  });

  static const sheetKey = Key('trip_time_sheet');

  static Key slotKey(String time) => Key('trip_time_sheet_slot_$time');

  final String title;

  /// Every offered slot, already filtered by the caller.
  final List<DateTime> slots;
  final String? selectedLabel;

  /// Returns the chosen slot, or `null` when the sheet is dismissed.
  static Future<DateTime?> show(
    BuildContext context, {
    required String title,
    required List<DateTime> slots,
    String? selectedLabel,
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => TripTimePickerSheet(
        title: title,
        slots: slots,
        selectedLabel: selectedLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      sheetKey: sheetKey,
      title: title,
      child: slots.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Text(
                'На этот день свободных слотов больше нет. Выберите другую дату.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.33,
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final slot in slots)
                    _SlotChip(
                      label: RussianDateLabels.time(slot),
                      selected: RussianDateLabels.time(slot) == selectedLabel,
                      onTap: () => Navigator.of(context).pop(slot),
                    ),
                ],
              ),
            ),
    );
  }
}

/// Half-hour slots of [day], skipping the ones already gone when [day] is
/// today.
List<DateTime> tripSlotsForDay(DateTime day, {required DateTime now}) =>
    TripDepartureSlots.forDay(day, now: now);

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        key: TripTimePickerSheet.slotKey(label),
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.brandGreen : AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.accentWhite : AppColors.accentBlack,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({
    required this.sheetKey,
    required this.title,
    required this.child,
  });

  final Key sheetKey;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: sheetKey,
      color: AppColors.background,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.accentBlack,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.29,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(child: child),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens the day picker and stores the chosen departure day, keeping the time
/// when that slot is still ahead.
Future<void> pickTripDepartureDate(
  BuildContext context, {
  required TripDraftController controller,
  required DateTime? departure,
  required DateTime now,
}) async {
  final day = await TripDatePickerSheet.show(
    context,
    now: now,
    selectedDay: departure,
  );
  if (day == null) return;

  DateTime firstSlotOf(DateTime day) {
    final slots = tripSlotsForDay(day, now: now);
    return slots.isEmpty ? TripDepartureSlots.roundUp(now) : slots.first;
  }

  if (departure == null) {
    controller.setDepartureAt(firstSlotOf(day));
    return;
  }
  final moved = DateTime(
    day.year,
    day.month,
    day.day,
    departure.hour,
    departure.minute,
  );
  controller.setDepartureAt(moved.isAfter(now) ? moved : firstSlotOf(day));
}

/// Opens the slot picker for the departure time.
Future<void> pickTripDepartureTime(
  BuildContext context, {
  required TripDraftController controller,
  required DateTime? departure,
  required DateTime now,
}) async {
  final slot = await TripTimePickerSheet.show(
    context,
    title: 'Время выезда',
    slots: tripSlotsForDay(departure ?? now, now: now),
    selectedLabel: departure == null ? null : RussianDateLabels.time(departure),
  );
  if (slot == null) return;
  controller.setDepartureAt(slot);
}

/// Opens the slot picker for the estimated arrival. Every slot stays available
/// because an arrival may fall on the next day.
Future<void> pickTripArrivalTime(
  BuildContext context, {
  required TripDraftController controller,
  required DateTime? arrival,
  required DateTime now,
}) async {
  final today = DateTime(now.year, now.month, now.day);
  final slot = await TripTimePickerSheet.show(
    context,
    title: 'Примерное время прибытия',
    slots: TripDepartureSlots.forDay(today, now: today),
    selectedLabel: arrival == null ? null : RussianDateLabels.time(arrival),
  );
  if (slot == null) return;
  controller.setArrivalTimeOfDay(hour: slot.hour, minute: slot.minute);
}
