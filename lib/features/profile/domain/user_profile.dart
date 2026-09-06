import 'package:flutter/foundation.dart';
import 'package:vput/features/profile/domain/rating_calculator.dart';

@immutable
class UserProfile {
  const UserProfile({
    required this.name,
    required this.phone,
    required this.completedTrips,
    required this.cancelledTrips,
    this.avatarBytes,
    this.ratingAvg,
    this.reviewsCount = 0,
  });

  final String name;
  final String phone;
  final int completedTrips;
  final int cancelledTrips;
  final Uint8List? avatarBytes;

  final double? ratingAvg;
  final int reviewsCount;

  String get ratingLabel =>
      RatingCalculator.label(average: ratingAvg, count: reviewsCount);

  UserProfile copyWith({String? name, Uint8List? avatarBytes}) {
    return UserProfile(
      name: name ?? this.name,
      phone: phone,
      ratingAvg: ratingAvg,
      reviewsCount: reviewsCount,
      completedTrips: completedTrips,
      cancelledTrips: cancelledTrips,
      avatarBytes: avatarBytes ?? this.avatarBytes,
    );
  }
}
