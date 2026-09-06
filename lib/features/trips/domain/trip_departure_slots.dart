/// Departure time is chosen in 30 minute steps only.
abstract final class TripDepartureSlots {
  static const stepMinutes = 30;

  /// Whether [moment] lands exactly on a 30 minute slot.
  static bool isAligned(DateTime moment) {
    return moment.minute % stepMinutes == 0 &&
        moment.second == 0 &&
        moment.millisecond == 0 &&
        moment.microsecond == 0;
  }

  /// All 30 minute slots of [day], skipping slots that are already in the past
  /// when [day] is the same calendar day as [now].
  static List<DateTime> forDay(DateTime day, {required DateTime now}) {
    final slots = <DateTime>[];
    for (
      var minutes = 0;
      minutes < Duration.minutesPerDay;
      minutes += stepMinutes
    ) {
      final slot = DateTime(
        day.year,
        day.month,
        day.day,
      ).add(Duration(minutes: minutes));
      if (slot.isBefore(now)) continue;
      slots.add(slot);
    }
    return List.unmodifiable(slots);
  }

  /// Rounds [moment] up to the next 30 minute slot.
  static DateTime roundUp(DateTime moment) {
    final aligned = DateTime(
      moment.year,
      moment.month,
      moment.day,
      moment.hour,
      moment.minute - moment.minute % stepMinutes,
    );
    return aligned.isBefore(moment)
        ? aligned.add(const Duration(minutes: stepMinutes))
        : aligned;
  }
}
