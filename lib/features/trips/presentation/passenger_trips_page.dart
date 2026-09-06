import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/features/location/application/location_prompt_controller.dart';
import 'package:vput/features/location/data/device_location_permission_service.dart';
import 'package:vput/features/location/presentation/location_access_dialog.dart';
import 'package:vput/features/trips/domain/passenger_trip.dart';
import 'package:vput/features/trips/presentation/passenger_trips_screen.dart';

class PassengerTripsPage extends ConsumerStatefulWidget {
  const PassengerTripsPage({
    required this.onOrders,
    required this.onCreate,
    required this.onChats,
    required this.onProfile,
    required this.onTripSelected,
    super.key,
  });

  final VoidCallback onOrders;
  final VoidCallback onCreate;
  final VoidCallback onChats;
  final VoidCallback onProfile;
  final ValueChanged<PassengerTrip> onTripSelected;

  @override
  ConsumerState<PassengerTripsPage> createState() => _PassengerTripsPageState();
}

class _PassengerTripsPageState extends ConsumerState<PassengerTripsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showLocationPrompt());
  }

  Future<void> _showLocationPrompt() async {
    if (!mounted || ref.read(locationPromptHandledProvider)) return;
    ref.read(locationPromptHandledProvider.notifier).markHandled();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.accentBlack.withValues(alpha: .4),
      builder: (dialogContext) => LocationAccessDialog(
        onAllow: () async {
          await ref.read(locationPermissionServiceProvider).requestWhenInUse();
          if (dialogContext.mounted) Navigator.of(dialogContext).pop();
        },
        onSkip: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PassengerTripsScreen(
      onOrders: widget.onOrders,
      onCreate: widget.onCreate,
      onChats: widget.onChats,
      onProfile: widget.onProfile,
      onTripSelected: widget.onTripSelected,
    );
  }
}
