import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/features/profile/data/device_profile_image_repository.dart';
import 'package:vput/features/profile/domain/profile_image_repository.dart';
import 'package:vput/features/profile/domain/profile_image_source.dart';
import 'package:vput/features/profile/presentation/widgets/photo_source_sheet.dart';
import 'package:vput/features/vehicles/application/driver_vehicles_controller.dart';
import 'package:vput/features/vehicles/data/preview_driver_vehicle_repository.dart';
import 'package:vput/features/vehicles/domain/driver_vehicle.dart';
import 'package:vput/features/vehicles/presentation/driver_vehicle_details_screen.dart';
import 'package:vput/features/vehicles/presentation/driver_vehicle_form_screen.dart';
import 'package:vput/features/vehicles/presentation/driver_vehicles_screen.dart';
import 'package:vput/features/vehicles/presentation/widgets/vehicle_catalog_sheet.dart';

/// Stands in for the camera and the file picker: returns a 1×1 PNG.
class _FakeImageRepository implements ProfileImageRepository {
  @override
  Future<Uint8List?> pick(ProfileImageSource source) async => base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+'
    'A8AAQUBAScY42YAAAAASUVORK5CYII=',
  );
}

class _CancelledImageRepository implements ProfileImageRepository {
  @override
  Future<Uint8List?> pick(ProfileImageSource source) async => null;
}

class _FailingImageRepository implements ProfileImageRepository {
  @override
  Future<Uint8List?> pick(ProfileImageSource source) async =>
      throw StateError('denied');
}

ProviderContainer _container({
  List<DriverVehicle> vehicles = previewDriverVehicles,
  ProfileImageRepository? imageRepository,
}) {
  final container = ProviderContainer(
    overrides: [
      driverVehicleRepositoryProvider.overrideWithValue(
        PreviewDriverVehicleRepository(vehicles: vehicles),
      ),
      profileImageRepositoryProvider.overrideWithValue(
        imageRepository ?? _FakeImageRepository(),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> _pump(
  WidgetTester tester,
  ProviderContainer container,
  Widget screen,
) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: screen),
    ),
  );
}

Future<void> _tap(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

void main() {
  group('DriverVehiclesScreen', () {
    testWidgets('an empty garage invites the driver to add the first car', (
      tester,
    ) async {
      var addTaps = 0;
      final container = _container(vehicles: const []);
      await _pump(
        tester,
        container,
        DriverVehiclesScreen(
          onBack: () {},
          onAddVehicle: () => addTaps++,
          onOpenVehicle: (_) {},
        ),
      );

      expect(find.text('Транспортные средства'), findsOneWidget);
      expect(find.byKey(DriverVehiclesScreen.emptyStateKey), findsOneWidget);
      expect(find.text('У вас еще нет транспортного средства'), findsOneWidget);
      expect(
        find.text('Добавьте информацию о ТС и берите или создавайте заказы'),
        findsOneWidget,
      );
      expect(find.byKey(DriverVehiclesScreen.addButtonKey), findsNothing);

      await _tap(tester, DriverVehiclesScreen.emptyAddButtonKey);

      expect(addTaps, 1);
    });

    testWidgets('lists every car of the account and opens one', (tester) async {
      DriverVehicle? opened;
      final container = _container();
      await _pump(
        tester,
        container,
        DriverVehiclesScreen(
          onBack: () {},
          onAddVehicle: () {},
          onOpenVehicle: (vehicle) => opened = vehicle,
        ),
      );

      expect(find.text('LADA Largus'), findsOneWidget);
      expect(find.text('А 777 АА 7 • 4 места'), findsOneWidget);
      expect(find.text('На проверке'), findsOneWidget);
      expect(find.byKey(DriverVehiclesScreen.addButtonKey), findsOneWidget);

      await _tap(
        tester,
        DriverVehiclesScreen.vehicleKey('preview_vehicle_largus'),
      );

      expect(opened?.id, 'preview_vehicle_largus');
    });
  });

  group('DriverVehicleDetailsScreen', () {
    for (final repository in <ProfileImageRepository>[
      _CancelledImageRepository(),
      _FailingImageRepository(),
    ]) {
      testWidgets(
        'cancelled or failed STS selection preserves verification: ${repository.runtimeType}',
        (tester) async {
          final container = _container(imageRepository: repository);
          await _pump(
            tester,
            container,
            DriverVehicleDetailsScreen(
              vehicleId: 'preview_vehicle_largus',
              onBack: () {},
              onEdit: (_) {},
              onDeleted: () {},
            ),
          );
          await _tap(tester, DriverVehicleDetailsScreen.replaceDocumentKey);
          await _tap(tester, PhotoSourceSheet.galleryButtonKey);
          expect(
            container
                .read(driverVehiclesProvider.notifier)
                .findById('preview_vehicle_largus')!
                .verificationStatus,
            VehicleVerificationStatus.approved,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('shows the card of a verified car with its document', (
      tester,
    ) async {
      final container = _container();
      await _pump(
        tester,
        container,
        DriverVehicleDetailsScreen(
          vehicleId: 'preview_vehicle_largus',
          onBack: () {},
          onEdit: (_) {},
          onDeleted: () {},
        ),
      );

      expect(find.text('LADA Largus'), findsWidgets);
      expect(find.text('А 777 АА 7'), findsOneWidget);
      expect(find.text('Проверен'), findsOneWidget);
      expect(find.text('Легковой · 4 места'), findsOneWidget);
      expect(find.text('СТС (свидетельство о регистрации)'), findsOneWidget);
      expect(find.text('Заменить'), findsOneWidget);
    });

    testWidgets('replacing the document sends the car back for a check', (
      tester,
    ) async {
      final container = _container();
      await _pump(
        tester,
        container,
        DriverVehicleDetailsScreen(
          vehicleId: 'preview_vehicle_largus',
          onBack: () {},
          onEdit: (_) {},
          onDeleted: () {},
        ),
      );

      await _tap(tester, DriverVehicleDetailsScreen.replaceDocumentKey);
      await _tap(tester, PhotoSourceSheet.galleryButtonKey);

      expect(
        container
            .read(driverVehiclesProvider.notifier)
            .findById('preview_vehicle_largus')!
            .verificationStatus,
        VehicleVerificationStatus.pending,
      );
      expect(find.text('На проверке'), findsOneWidget);
    });

    testWidgets('deleting a car is confirmed first', (tester) async {
      var deleted = 0;
      final container = _container(vehicles: [previewDriverVehicles.first]);
      await _pump(
        tester,
        container,
        DriverVehicleDetailsScreen(
          vehicleId: 'preview_vehicle_largus',
          onBack: () {},
          onEdit: (_) {},
          onDeleted: () => deleted++,
        ),
      );

      await _tap(tester, DriverVehicleDetailsScreen.deleteButtonKey);

      expect(find.text('Удалить ТС?'), findsOneWidget);
      expect(container.read(driverVehiclesProvider), hasLength(1));

      await _tap(tester, DriverVehicleDetailsScreen.confirmDeleteKey);

      expect(container.read(driverVehiclesProvider), isEmpty);
      expect(deleted, 1);
    });
  });

  group('DriverVehicleFormScreen', () {
    testWidgets('brand and model are picked from the catalogue', (
      tester,
    ) async {
      String? savedId;
      final container = _container(vehicles: const []);
      await _pump(
        tester,
        container,
        DriverVehicleFormScreen(onBack: () {}, onSaved: (id) => savedId = id),
      );

      expect(find.text('Добавление нового ТС'), findsOneWidget);
      expect(find.text('Информация об автомобиле'), findsOneWidget);
      expect(find.text('Тип'), findsOneWidget);
      expect(find.text('Подтверждающие документы'), findsOneWidget);
      // The seat count only shows up once the car is known.
      expect(
        find.byKey(DriverVehicleFormScreen.capacityFieldKey),
        findsNothing,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(DriverVehicleFormScreen.saveButtonKey),
            )
            .onPressed,
        isNull,
      );

      await _tap(tester, DriverVehicleFormScreen.brandFieldKey);

      expect(find.byKey(VehicleCatalogSheet.sheetKey), findsOneWidget);
      expect(find.text('Выбрать марку автомобиля'), findsOneWidget);
      expect(find.text('Audi'), findsOneWidget);

      // Typing narrows the list down to the brands that match.
      await tester.enterText(
        find.byKey(VehicleCatalogSheet.searchFieldKey),
        'i',
      );
      await tester.pumpAndSettle();

      expect(find.text('Audi'), findsNothing);
      expect(find.text('Infiniti'), findsOneWidget);
      expect(find.text('Isuzu'), findsOneWidget);

      await _tap(tester, VehicleCatalogSheet.optionKey('Infiniti'));

      expect(find.text('Infiniti'), findsOneWidget);
      expect(
        find.byKey(DriverVehicleFormScreen.capacityFieldKey),
        findsOneWidget,
      );

      await _tap(tester, DriverVehicleFormScreen.modelFieldKey);

      expect(find.text('Выбрать модель Infiniti'), findsOneWidget);

      await _tap(tester, VehicleCatalogSheet.optionKey('Q30'));
      await tester.enterText(
        find.byKey(DriverVehicleFormScreen.capacityFieldKey),
        '6',
      );
      await tester.pump();

      // The kind of vehicle is still missing.
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(DriverVehicleFormScreen.saveButtonKey),
            )
            .onPressed,
        isNull,
      );

      await _tap(tester, DriverVehicleFormScreen.typeCarKey);
      await _tap(tester, DriverVehicleFormScreen.saveButtonKey);

      final added = container.read(driverVehiclesProvider).single;
      expect(savedId, added.id);
      expect(added.title, 'Infiniti Q30');
      expect(added.seatCount, 6);
      expect(added.transportType, VehicleTransportType.car);
      expect(added.hasPlateNumber, isFalse);
      // Without documents the car is only a draft.
      expect(added.verificationStatus, VehicleVerificationStatus.draft);
    });

    testWidgets('a photo can be added and taken off again', (tester) async {
      final container = _container(vehicles: const []);
      await _pump(
        tester,
        container,
        DriverVehicleFormScreen(onBack: () {}, onSaved: (_) {}),
      );

      await _tap(tester, DriverVehicleFormScreen.photoButtonKey);

      expect(find.byKey(PhotoSourceSheet.sheetKey), findsOneWidget);
      expect(find.text('Загрузка фотографии'), findsOneWidget);

      await _tap(tester, PhotoSourceSheet.cameraButtonKey);

      expect(
        find.byKey(DriverVehicleFormScreen.photoRemoveKey),
        findsOneWidget,
      );
      expect(find.byKey(DriverVehicleFormScreen.photoButtonKey), findsNothing);

      await _tap(tester, DriverVehicleFormScreen.photoRemoveKey);

      expect(
        find.byKey(DriverVehicleFormScreen.photoButtonKey),
        findsOneWidget,
      );
    });

    testWidgets('the chosen kind of vehicle is highlighted', (tester) async {
      final container = _container(vehicles: const []);
      await _pump(
        tester,
        container,
        DriverVehicleFormScreen(onBack: () {}, onSaved: (_) {}),
      );

      Color? cardColor(Key key) {
        final card = tester.widget<Container>(
          find.descendant(
            of: find.byKey(key),
            matching: find.byType(Container),
          ),
        );
        return (card.decoration! as BoxDecoration).color;
      }

      expect(
        cardColor(DriverVehicleFormScreen.typeCarKey),
        AppColors.accentWhite,
      );

      await _tap(tester, DriverVehicleFormScreen.typeCarKey);

      expect(
        cardColor(DriverVehicleFormScreen.typeCarKey),
        AppColors.brandGreen.withValues(alpha: .12),
      );
      expect(
        cardColor(DriverVehicleFormScreen.typeBusKey),
        AppColors.accentWhite,
      );
    });

    testWidgets('documents send the new car on review', (tester) async {
      final container = _container(vehicles: const []);
      await _pump(
        tester,
        container,
        DriverVehicleFormScreen(onBack: () {}, onSaved: (_) {}),
      );

      await _tap(tester, DriverVehicleFormScreen.brandFieldKey);
      // The catalogue is long, so the brand is found through the search.
      await tester.enterText(
        find.byKey(VehicleCatalogSheet.searchFieldKey),
        'Toyota',
      );
      await tester.pumpAndSettle();
      await _tap(tester, VehicleCatalogSheet.optionKey('Toyota'));
      await _tap(tester, DriverVehicleFormScreen.modelFieldKey);
      await _tap(tester, VehicleCatalogSheet.optionKey('Camry'));
      await tester.enterText(
        find.byKey(DriverVehicleFormScreen.capacityFieldKey),
        '4',
      );
      await tester.pump();
      await _tap(tester, DriverVehicleFormScreen.typeCarKey);
      await _tap(tester, DriverVehicleFormScreen.documentButtonKey);
      await _tap(tester, PhotoSourceSheet.galleryButtonKey);

      expect(find.text('СТС загружено'), findsOneWidget);

      await _tap(tester, DriverVehicleFormScreen.saveButtonKey);

      final added = container.read(driverVehiclesProvider).single;
      expect(added.hasRegistrationDocument, isTrue);
      expect(added.verificationStatus, VehicleVerificationStatus.pending);
    });

    testWidgets('editing a car keeps its data and sends it back for a check', (
      tester,
    ) async {
      final container = _container(vehicles: [previewDriverVehicles.first]);
      await _pump(
        tester,
        container,
        DriverVehicleFormScreen(
          vehicleId: 'preview_vehicle_largus',
          onBack: () {},
          onSaved: (_) {},
        ),
      );

      expect(find.text('Редактирование ТС'), findsOneWidget);
      expect(find.text('LADA'), findsOneWidget);
      expect(find.text('Largus'), findsOneWidget);

      await tester.enterText(
        find.byKey(DriverVehicleFormScreen.capacityFieldKey),
        '5',
      );
      await tester.pump();
      await _tap(tester, DriverVehicleFormScreen.saveButtonKey);

      final vehicle = container.read(driverVehiclesProvider).single;
      expect(vehicle.seatCount, 5);
      expect(vehicle.plateNumber, 'А 777 АА 7');
      expect(vehicle.verificationStatus, VehicleVerificationStatus.pending);
      // A car under review is no longer offered for a trip.
      expect(container.read(approvedDriverVehiclesProvider), isEmpty);
    });
  });
}
