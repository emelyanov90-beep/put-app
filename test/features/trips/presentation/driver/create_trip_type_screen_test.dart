import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/trips/application/trip_draft_controller.dart';
import 'package:vput/features/trips/domain/passenger_trip.dart';
import 'package:vput/features/trips/presentation/driver/create_trip_type_screen.dart';
import 'package:vput/features/trips/presentation/widgets/create_trip_controls.dart';

void main() {
  testWidgets('picks the order type and moves on', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    var continues = 0;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: CreateTripTypeScreen(
            onBack: () {},
            onContinue: () => continues++,
          ),
        ),
      ),
    );

    expect(find.text('Новый заказ'), findsOneWidget);
    expect(find.text('Шаг 1 из 6'), findsOneWidget);
    expect(find.text('Тип заказа'), findsOneWidget);
    // Driver-facing wording: the passenger pair lives in the passenger wizard.
    expect(find.text('Взять попутчиков в свою поездку'), findsOneWidget);
    expect(find.text('Перевозить пассажиров и посылки'), findsOneWidget);
    expect(find.text('Найти водителя для себя'), findsNothing);
    expect(
      container.read(tripDraftProvider).transportType,
      PassengerTransportType.car,
    );

    await tester.tap(find.byKey(CreateTripTypeScreen.busOptionKey));
    await tester.pump();

    expect(
      container.read(tripDraftProvider).transportType,
      PassengerTransportType.bus,
    );

    await tester.tap(find.byKey(CreateTripStepScaffold.primaryButtonKey));
    await tester.pump();

    expect(continues, 1);
  });
}
