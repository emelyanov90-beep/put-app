import 'package:flutter_test/flutter_test.dart';
import 'package:vput/core/utils/russian_date_labels.dart';

void main() {
  group('RussianDateLabels', () {
    test('formats a date, a time and both together', () {
      final moment = DateTime(2026, 5, 15, 9, 30);

      expect(RussianDateLabels.dayAndMonth(moment), '15 мая');
      expect(RussianDateLabels.time(moment), '09:30');
      expect(RussianDateLabels.dateAndTime(moment), '15 мая, 09:30');
      expect(RussianDateLabels.numericDate(moment), '15.05.2026');
      expect(RussianDateLabels.shortTime(DateTime(2026, 6, 14, 8)), '8:00');
    });

    test('names today and tomorrow, then falls back to the weekday', () {
      final now = DateTime(2026, 5, 15, 9);

      expect(RussianDateLabels.relativeDay(now, now: now), 'Сегодня');
      expect(
        RussianDateLabels.relativeDay(DateTime(2026, 5, 16), now: now),
        'Завтра',
      );
      expect(
        RussianDateLabels.relativeDay(DateTime(2026, 5, 17), now: now),
        'вс, 17 мая',
      );
    });

    test('compares calendar days, not moments', () {
      expect(
        RussianDateLabels.isSameDay(
          DateTime(2026, 5, 15, 23, 59),
          DateTime(2026, 5, 15),
        ),
        isTrue,
      );
      expect(
        RussianDateLabels.isSameDay(
          DateTime(2026, 5, 16),
          DateTime(2026, 5, 15, 23, 59),
        ),
        isFalse,
      );
    });
  });
}
