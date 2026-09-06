import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/trips/application/trip_draft_controller.dart';
import 'package:vput/features/trips/domain/passenger_trip.dart';
import 'package:vput/features/trips/domain/trip_extras.dart';
import 'package:vput/features/trips/presentation/driver/create_trip_extras_screen.dart';
import 'package:vput/features/trips/presentation/widgets/create_trip_controls.dart';
import 'package:vput/features/trips/presentation/widgets/parcel_options_sheet.dart';

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  VoidCallback? onNext,
}) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer();
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: CreateTripExtrasScreen(
          onBack: () {},
          onContinue: onNext ?? () {},
        ),
      ),
    ),
  );
  return container;
}

Future<void> _tap(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a service is switched on at the price from the catalogue', (
    tester,
  ) async {
    var continues = 0;
    final container = await _pump(tester, onNext: () => continues++);

    expect(find.text('Шаг 5 из 6'), findsOneWidget);
    expect(find.text('Дополнительные услуги'), findsOneWidget);
    expect(find.text('Детское кресло'), findsOneWidget);
    expect(find.text('+150₽'), findsNWidgets(3));

    await _tap(
      tester,
      CreateTripExtrasScreen.extraSwitchKey(TripExtraService.childSeat),
    );

    final extra = container
        .read(tripDraftProvider)
        .extraFor(TripExtraService.childSeat);
    expect(extra.enabled, isTrue);
    expect(extra.price, 150);

    await tester.tap(find.byKey(CreateTripStepScaffold.primaryButtonKey));
    await tester.pump();

    expect(continues, 1);
  });

  testWidgets('parcel sizes are chosen in a sheet and priced by size', (
    tester,
  ) async {
    final container = await _pump(tester);

    expect(find.text('до 350₽'), findsOneWidget);

    await _tap(tester, CreateTripExtrasScreen.parcelRowKey);

    expect(find.byKey(ParcelOptionsSheet.sheetKey), findsOneWidget);
    expect(find.text('Укажите размер вашей посылки'), findsOneWidget);
    expect(find.text('до 50/40/30 до 10 кг'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(ParcelOptionsSheet.addButtonKey))
          .onPressed,
      isNull,
    );

    await _tap(tester, ParcelOptionsSheet.sizeKey(ParcelSize.small));
    await _tap(tester, ParcelOptionsSheet.withoutPassengerKey);
    await _tap(tester, ParcelOptionsSheet.addButtonKey);

    final parcel = container.read(tripDraftProvider).parcel;
    expect(parcel.enabled, isTrue);
    expect(parcel.priceBySize[ParcelSize.small], 150);
    expect(parcel.acceptsSize(ParcelSize.medium), isFalse);
    expect(parcel.allowedWithoutPassenger, isTrue);
    expect(find.text('150₽'), findsOneWidget);
  });

  testWidgets('cancelling the sheet keeps the parcel settings as they were', (
    tester,
  ) async {
    final container = await _pump(tester);

    await _tap(tester, CreateTripExtrasScreen.parcelRowKey);
    await _tap(tester, ParcelOptionsSheet.sizeKey(ParcelSize.large));
    await _tap(tester, ParcelOptionsSheet.cancelButtonKey);

    expect(container.read(tripDraftProvider).parcel, const TripParcelOffer());
    expect(find.text('до 350₽'), findsOneWidget);
  });
}
