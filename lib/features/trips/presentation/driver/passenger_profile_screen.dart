import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/features/trips/domain/driver_trip.dart';

class PassengerProfileScreen extends StatelessWidget {
  const PassengerProfileScreen({
    required this.passenger,
    required this.onBack,
    required this.onChat,
    this.pickupAddress,
    this.dropoffAddress,
    super.key,
  });

  static const titleKey = Key('passenger_profile_title');
  static const chatButtonKey = Key('passenger_profile_chat');
  static const routeCardKey = Key('passenger_profile_route');

  final DriverTripPassengerBooking passenger;
  final VoidCallback onBack;
  final VoidCallback onChat;

  /// Where the passenger gets on and off, shown once the booking is confirmed.
  final String? pickupAddress;
  final String? dropoffAddress;

  @override
  Widget build(BuildContext context) {
    const overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.accentWhite,
      systemNavigationBarIconBrightness: Brightness.dark,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _Header(onBack: onBack),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PassengerCard(passenger: passenger),
                      if (passenger.confirmed) ...[
                        const SizedBox(height: 20),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Маршрут пассажира',
                            style: TextStyle(
                              color: AppColors.accentBlack,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.33,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _PassengerRouteCard(
                          pickup: pickupAddress ?? passenger.pickupAddress,
                          dropoff: dropoffAddress ?? passenger.dropoffAddress,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            color: AppColors.background,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: SizedBox(
              height: 48,
              width: double.infinity,
              child: FilledButton(
                key: chatButtonKey,
                onPressed: onChat,
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
                child: const Text('Написать'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 102,
      padding: const EdgeInsets.only(bottom: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 48,
              child: Center(
                child: SizedBox.square(
                  dimension: 40,
                  child: IconButton.filled(
                    onPressed: onBack,
                    padding: EdgeInsets.zero,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.accentWhite,
                      foregroundColor: AppColors.brandGreen,
                    ),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
            const Expanded(
              child: Text(
                'Профиль пассажира',
                key: PassengerProfileScreen.titleKey,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.accentBlack,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
            SizedBox(
              width: 56,
              height: 48,
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.accentWhite.withValues(alpha: .72),
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox.square(
                    dimension: 40,
                    child: Icon(Icons.more_horiz_rounded, size: 22),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PassengerCard extends StatelessWidget {
  const _PassengerCard({required this.passenger});

  final DriverTripPassengerBooking passenger;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: AppColors.divider,
                foregroundImage: passenger.passengerAvatarAsset == null
                    ? null
                    : AssetImage(passenger.passengerAvatarAsset!),
                child: passenger.passengerAvatarAsset == null
                    ? const Icon(
                        Icons.person_rounded,
                        color: AppColors.textSecondary,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  passenger.passengerName,
                  style: const TextStyle(
                    color: AppColors.accentBlack,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (passenger.confirmed) ...[
            const _ProfileField(
              label: 'Связаться с пассажиром',
              value: 'Напишите в чат',
            ),
            const SizedBox(height: 12),
          ],
          _ProfileField(
            label: 'Рейтинг поездок',
            value: passenger.passengerRatingLabel,
            leading: const Icon(
              Icons.star_rounded,
              color: Color(0xFFF2C500),
              size: 19,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({required this.label, required this.value, this.leading});

  final String label;
  final String value;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, height: 1.2)),
          const SizedBox(height: 6),
          Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 4)],
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.accentBlack,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// «Маршрут пассажира»: the part of the trip this passenger booked.
class _PassengerRouteCard extends StatelessWidget {
  const _PassengerRouteCard({required this.pickup, required this.dropoff});

  final String? pickup;
  final String? dropoff;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: PassengerProfileScreen.routeCardKey,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RoutePoint(label: 'Точка посадки', value: pickup),
          const SizedBox(height: 16),
          _RoutePoint(label: 'Точка высадки', value: dropoff),
        ],
      ),
    );
  }
}

class _RoutePoint extends StatelessWidget {
  const _RoutePoint({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 20),
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: AppColors.accentBlack,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(bottom: 6),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.accentBlack)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.33,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value ?? 'Весь маршрут',
                  style: const TextStyle(
                    color: AppColors.accentBlack,
                    fontSize: 15,
                    height: 1.33,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
