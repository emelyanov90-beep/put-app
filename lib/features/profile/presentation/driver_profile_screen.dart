import 'package:flutter/material.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/app/widgets/screen_header.dart';
import 'package:vput/features/trips/domain/passenger_trip.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({
    required this.trip,
    required this.onBack,
    super.key,
  });
  final PassengerTrip trip;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: Column(
        children: [
          ScreenHeader(title: 'Профиль водителя', onBack: onBack),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accentWhite,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.driverName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        trip.driverRatingLabel,
                        style: const TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${trip.driverTripsCount} поездок',
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${trip.vehicle.brand} ${trip.vehicle.model}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Image.asset(
                  trip.vehicle.photoAsset,
                  height: 160,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
