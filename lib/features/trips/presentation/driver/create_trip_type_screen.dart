import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/features/trips/application/trip_draft_controller.dart';
import 'package:vput/features/trips/domain/passenger_trip.dart';
import 'package:vput/features/trips/presentation/widgets/create_trip_controls.dart';

/// Step 1: the transport the driver publishes the trip on.
///
/// The wording is driver-facing on purpose: the passenger-facing pair («найти
/// водителя для себя» / «отправить груз или посылку») belongs to the passenger
/// wizard step 1, see [PassengerOrderTypeScreen].
class CreateTripTypeScreen extends ConsumerWidget {
  const CreateTripTypeScreen({
    required this.onBack,
    required this.onContinue,
    this.isEditing = false,
    super.key,
  });

  static const carOptionKey = Key('create_trip_type_car');
  static const busOptionKey = Key('create_trip_type_bus');

  final VoidCallback onBack;
  final VoidCallback onContinue;
  final bool isEditing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = ref.watch(
      tripDraftProvider.select((draft) => draft.transportType),
    );
    final controller = ref.read(tripDraftProvider.notifier);

    return CreateTripStepScaffold(
      step: 1,
      onBack: onBack,
      primaryLabel: isEditing ? 'Сохранить' : 'Далее',
      onPrimary: onContinue,
      children: [
        CreateTripSection(
          title: 'Тип заказа',
          padded: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CreateTripOptionCard(
                key: carOptionKey,
                title: 'Автомобиль',
                description: 'Взять попутчиков в свою поездку',
                selected: type == PassengerTransportType.car,
                onTap: () =>
                    controller.setTransportType(PassengerTransportType.car),
                illustration: const _TransportIllustration(
                  assetPath: 'docs/imgs/car.png',
                ),
              ),
              const SizedBox(height: 12),
              CreateTripOptionCard(
                key: busOptionKey,
                title: 'Автобус',
                description: 'Перевозить пассажиров и посылки',
                selected: type == PassengerTransportType.bus,
                onTap: () =>
                    controller.setTransportType(PassengerTransportType.bus),
                illustration: const _TransportIllustration(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Illustration on the right of an order type card.
///
/// Foundation placeholder: the design uses a green LADA Largus and a green bus;
/// only the car render is in the repository, so the bus falls back to an icon
/// until `docs/imgs/bus.png` is supplied.
class _TransportIllustration extends StatelessWidget {
  const _TransportIllustration({this.assetPath});

  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    final path = assetPath;
    return SizedBox(
      width: 120,
      height: 68,
      child: path == null
          ? const Icon(
              Icons.airport_shuttle_rounded,
              size: 48,
              color: AppColors.brandGreen,
            )
          : Image.asset(path, fit: BoxFit.contain, excludeFromSemantics: true),
    );
  }
}
