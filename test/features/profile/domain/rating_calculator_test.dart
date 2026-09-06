import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/profile/domain/rating_calculator.dart';

void main() {
  test('no published reviews stays null and has the exact TZ label', () {
    expect(RatingCalculator.average([]), isNull);
    expect(
      RatingCalculator.label(average: null, count: 0),
      '5 звезд, нет отзывов',
    );
  });
  test('only supplied published reviews determine the average', () {
    expect(RatingCalculator.average([5, 4, 3]), 4);
    expect(() => RatingCalculator.average([6]), throwsArgumentError);
  });
  test('Russian review count declensions include teen exceptions', () {
    for (final entry in {
      1: 'отзыв',
      2: 'отзыва',
      5: 'отзывов',
      11: 'отзывов',
      12: 'отзывов',
      21: 'отзыв',
      24: 'отзыва',
    }.entries) {
      expect(
        RatingCalculator.label(average: 4.5, count: entry.key),
        '4.5, ${entry.key} ${entry.value}',
      );
    }
  });
  test('corrupt averages are not displayed as a fabricated rating', () {
    expect(
      RatingCalculator.label(average: double.nan, count: 1),
      'Отзывы временно недоступны',
    );
  });
}
