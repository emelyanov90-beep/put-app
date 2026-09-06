/// Ratings come only from published reviews (TZ 2.1, 25).
abstract final class RatingCalculator {
  static double? average(Iterable<int> publishedRatings) {
    if (publishedRatings.isEmpty) return null;
    if (publishedRatings.any((rating) => rating < 1 || rating > 5)) {
      throw ArgumentError('Ratings must be between 1 and 5');
    }
    return publishedRatings.reduce((a, b) => a + b) / publishedRatings.length;
  }

  static String label({required double? average, required int count}) {
    if (count <= 0) return '5 звезд, нет отзывов';
    if (average == null || !average.isFinite || average < 1 || average > 5) {
      return 'Отзывы временно недоступны';
    }
    final remainder = count % 100;
    final noun = remainder >= 11 && remainder <= 14
        ? 'отзывов'
        : switch (count % 10) {
            1 => 'отзыв',
            2 || 3 || 4 => 'отзыва',
            _ => 'отзывов',
          };
    return '${average.toStringAsFixed(1)}, $count $noun';
  }
}
