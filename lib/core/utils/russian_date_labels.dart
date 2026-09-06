/// Russian date and time labels.
///
/// The app ships without localization delegates, so dates are formatted here
/// instead of through `MaterialLocalizations`.
abstract final class RussianDateLabels {
  static const _monthsGenitive = <String>[
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];

  static const _shortWeekdays = <String>[
    'пн',
    'вт',
    'ср',
    'чт',
    'пт',
    'сб',
    'вс',
  ];

  /// `15 мая`
  static String dayAndMonth(DateTime date) =>
      '${date.day} ${_monthsGenitive[date.month - 1]}';

  /// `пт`
  static String shortWeekday(DateTime date) => _shortWeekdays[date.weekday - 1];

  /// `14.06.2026`
  static String numericDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  /// `8:00` — the form the wizard fields use.
  static String shortTime(DateTime moment) =>
      '${moment.hour}:${moment.minute.toString().padLeft(2, '0')}';

  /// `09:30`
  static String time(DateTime moment) {
    final hour = moment.hour.toString().padLeft(2, '0');
    final minute = moment.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// `15 мая, 09:30`
  static String dateAndTime(DateTime moment) =>
      '${dayAndMonth(moment)}, ${time(moment)}';

  /// `Сегодня` / `Завтра` / `пт, 15 мая`
  static String relativeDay(DateTime date, {required DateTime now}) {
    final days = _dayDifference(date, now);
    if (days == 0) return 'Сегодня';
    if (days == 1) return 'Завтра';
    return '${shortWeekday(date)}, ${dayAndMonth(date)}';
  }

  static bool isSameDay(DateTime first, DateTime second) =>
      _dayDifference(first, second) == 0;

  static int _dayDifference(DateTime date, DateTime other) {
    final left = DateTime(date.year, date.month, date.day);
    final right = DateTime(other.year, other.month, other.day);
    return left.difference(right).inDays;
  }
}
