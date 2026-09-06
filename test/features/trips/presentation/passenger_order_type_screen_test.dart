import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/trips/application/passenger_order_draft_controller.dart';
import 'package:vput/features/trips/domain/passenger_trip.dart';
import 'package:vput/features/trips/presentation/passenger_order_type_screen.dart';
import 'package:vput/features/trips/presentation/widgets/create_trip_controls.dart';

void main() {
  testWidgets('picks the passenger order type and moves on', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    var continues = 0;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: PassengerOrderTypeScreen(
            onBack: () {},
            onContinue: () => continues++,
          ),
        ),
      ),
    );

    expect(find.text('Новый заказ'), findsOneWidget);
    expect(find.text('Шаг 1 из 4'), findsOneWidget);
    expect(find.text('Тип заказа'), findsOneWidget);
    // Passenger-facing wording; the driver wizard has its own pair.
    expect(find.text('Найти водителя для себя'), findsOneWidget);
    expect(find.text('Отправить груз или посылку'), findsOneWidget);
    expect(
      container.read(passengerOrderDraftProvider).transportType,
      PassengerTransportType.car,
    );

    await tester.tap(find.byKey(PassengerOrderTypeScreen.busOptionKey));
    await tester.pump();

    expect(
      container.read(passengerOrderDraftProvider).transportType,
      PassengerTransportType.bus,
    );

    await tester.tap(find.byKey(CreateTripStepScaffold.primaryButtonKey));
    await tester.pump();

    expect(continues, 1);
  });
}
