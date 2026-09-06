import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vput/app/app.dart';
import 'package:vput/app/router.dart';
import 'package:vput/features/onboarding/presentation/welcome_screen.dart';
import 'package:vput/features/onboarding/presentation/onboarding_slide_one_screen.dart';
import 'package:vput/features/onboarding/presentation/onboarding_slide_two_screen.dart';
import 'package:vput/features/onboarding/presentation/onboarding_slide_three_screen.dart';
import 'package:vput/features/auth/presentation/phone_auth_screen.dart';
import 'package:vput/features/auth/presentation/sms_code_screen.dart';
import 'package:vput/features/legal/presentation/legal_document_screen.dart';
import 'package:vput/features/profile/presentation/create_profile_screen.dart';
import 'package:vput/features/profile/presentation/profile_screen.dart';
import 'package:vput/features/profile/presentation/personal_data_screen.dart';
import 'package:vput/features/profile/presentation/role_switch_screen.dart';
import 'package:vput/features/profile/application/user_profile_controller.dart';
import 'package:vput/features/city/presentation/city_selection_screen.dart';
import 'package:vput/features/location/presentation/location_access_dialog.dart';
import 'package:vput/features/trips/presentation/passenger_trips_screen.dart';
import 'package:vput/features/trips/presentation/trip_details_screen.dart';
import 'package:vput/features/trips/presentation/widgets/passenger_bottom_bar.dart';
import 'package:vput/features/trips/presentation/booking/passenger_booking_sheet.dart';
import 'package:vput/features/trips/presentation/passenger_orders_screen.dart';
import 'package:vput/features/trips/presentation/passenger_order_details_screen.dart';
import 'package:vput/features/trips/data/preview_passenger_orders.dart';
import 'package:vput/features/trips/application/driver_trips_controller.dart';
import 'package:vput/features/trips/presentation/driver/create_trip_route_screen.dart';
import 'package:vput/features/trips/presentation/driver/create_trip_pricing_screen.dart';
import 'package:vput/features/trips/presentation/driver/create_trip_booking_mode_screen.dart';
import 'package:vput/features/trips/presentation/driver/trip_published_screen.dart';
import 'package:vput/features/trips/presentation/driver/driver_trips_screen.dart';
import 'package:vput/features/trips/presentation/widgets/create_trip_controls.dart';
import 'package:vput/features/trips/presentation/widgets/driver_vehicle_picker.dart';
import 'package:vput/features/trips/presentation/widgets/trip_schedule_sheets.dart';
import 'package:vput/features/chat/application/chats_controller.dart';
import 'package:vput/features/chat/presentation/chat_screen.dart';
import 'package:vput/features/chat/presentation/chats_screen.dart';
import 'package:vput/features/vehicles/presentation/driver_vehicles_screen.dart';
import 'package:vput/features/vehicles/presentation/driver_vehicle_details_screen.dart';

// Runs real Flutter screens on an Android device. Catalogue, driver publication,
// chat and auth are the project's UI preview fixtures, not a server E2E test.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'frontend audit: registration, passenger, profile, chat and driver',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const VputApp()),
      );
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();

      Future<void> shot(String name) async {
        await tester.pumpAndSettle();
        await binding.takeScreenshot(name);
        expect(tester.takeException(), isNull, reason: name);
      }

      Future<void> tap(Key key) async {
        await tester.pumpAndSettle();
        final finder = find.byKey(key);
        if (finder.evaluate().isEmpty &&
            find.byType(Scrollable).evaluate().isNotEmpty) {
          await tester.scrollUntilVisible(
            finder,
            200,
            scrollable: find.byType(Scrollable).first,
          );
        }
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        final rect = tester.getRect(finder);
        // A tall trip card may exceed the viewport; its centre can be behind
        // the bottom navigation even though its header is visible.
        if (rect.height > 100) {
          await tester.tapAt(rect.topLeft + const Offset(32, 32));
        } else {
          await tester.tap(finder);
        }
        await tester.pumpAndSettle();
      }

      Future<void> next() => tap(CreateTripStepScaffold.primaryButtonKey);
      Future<void> go(String path) async {
        container.read(routerProvider).go(path);
        await tester.pumpAndSettle();
      }

      await shot('01-welcome');
      await tap(WelcomeScreen.startButtonKey);
      await shot('02-onboarding-one');
      await tap(OnboardingSlideOneScreen.continueButtonKey);
      await shot('03-onboarding-two');
      await tap(OnboardingSlideTwoScreen.continueButtonKey);
      await shot('04-phone');
      await tester.enterText(find.byType(TextField), '9123456789');
      await tap(PhoneAuthScreen.getCodeButtonKey);
      await shot('05-terms');
      await tap(LegalDocumentScreen.acceptButtonKey);
      await shot('06-otp');
      for (var i = 0; i < 6; i++) {
        await tester.enterText(find.byType(TextField).at(i), '2');
      }
      await tap(SmsCodeScreen.submitButtonKey);
      expect(find.byKey(SmsCodeScreen.errorBannerKey), findsOneWidget);
      await shot('07-otp-invalid');
      for (var i = 0; i < 6; i++) {
        await tester.enterText(find.byType(TextField).at(i), '1');
      }
      await tap(SmsCodeScreen.submitButtonKey);
      await shot('08-create-profile');
      await tester.enterText(
        find.byKey(CreateProfileScreen.nameFieldKey),
        'Анна QA',
      );
      await tap(CreateProfileScreen.continueButtonKey);
      await tester.pump(const Duration(seconds: 1));
      await shot('09-role');
      await tap(OnboardingSlideThreeScreen.passengerButtonKey);
      await tester.pump(const Duration(seconds: 1));
      await shot('10-city');
      await tap(CitySelectionScreen.cityKey('ru_city_1'));
      await tap(CitySelectionScreen.continueButtonKey);
      await shot('11-location-prompt');
      await tap(LocationAccessDialog.skipButtonKey);
      await shot('12-trip-list');
      await tap(PassengerTripsScreen.busTabKey);
      await shot('13-bus-empty');
      await tap(PassengerTripsScreen.carTabKey);
      await tap(PassengerTripsScreen.tripCardKey('preview_trip_viktor'));
      await shot('14-trip-no-seats');
      await tap(const Key('screen_header_back'));
      await tap(PassengerTripsScreen.tripCardKey('preview_trip_alexander'));
      await shot('15-trip-available');
      await tap(TripDetailsScreen.bookSeatButtonKey);
      await shot('16-booking-sheet');
      await tap(PassengerBookingSheet.submitButtonKey);
      expect(
        find.text('Сервис бронирования недоступен. Попробуйте позже.'),
        findsOneWidget,
      );
      await shot('17-booking-service-unavailable');
      await go(AppRoutes.orders);
      await shot('18-orders');
      await tap(
        PassengerOrdersScreen.orderCardKey(previewPassengerOrders.first.id),
      );
      await shot('19-order-details');
      await tap(PassengerOrderDetailsScreen.cancelButtonKey);
      await shot('20-cancellation-confirmation');
      await tap(PassengerOrderDetailsScreen.keepBookingButtonKey);
      await tap(PassengerOrderDetailsScreen.cancelButtonKey);
      await tap(PassengerOrderDetailsScreen.confirmCancelButtonKey);
      expect(
        find.text('Сервис отмены бронирования недоступен. Попробуйте позже.'),
        findsOneWidget,
      );
      expect(find.byType(PassengerOrderDetailsScreen), findsOneWidget);
      await shot('20b-cancellation-service-unavailable');
      // Let the visible transient error finish before interacting with the next screen.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await go(AppRoutes.profile);
      expect(find.text('Анна QA'), findsOneWidget);
      expect(container.read(userProfileProvider).profile.phone, '+79123456789');
      await shot('21-profile');
      await tap(ProfileScreen.personalDataItemKey);
      await tester.enterText(
        find.byKey(PersonalDataScreen.nameFieldKey),
        'Анна',
      );
      await shot('22-personal-data-keyboard');
      await tap(PersonalDataScreen.saveButtonKey);
      await tap(PassengerBottomBar.chatsButtonKey);
      expect(find.byType(PassengerBottomBar), findsOneWidget);
      await shot('23-chats-empty');

      // Explicit UI fixture for rendering/sending a chat; no claim of realtime.
      final thread = container
          .read(chatsProvider.notifier)
          .openThread(
            peerId: 'qa_driver',
            peerName: 'Водитель QA',
            tripId: 'qa_trip',
          );
      await go('/chats/$thread');
      await shot('24-chat-empty');
      await tester.enterText(
        find.byKey(ChatScreen.messageFieldKey),
        'Здравствуйте! Где встречаемся?',
      );
      await tap(ChatScreen.sendButtonKey);
      await shot('25-chat-message');
      await go(AppRoutes.chats);
      expect(find.byKey(ChatsScreen.threadKey(thread)), findsOneWidget);
      await shot('26-chat-list');
      await tap(PassengerBottomBar.profileButtonKey);
      await tap(ProfileScreen.switchRoleItemKey);
      await shot('27-switch-role');
      await tap(RoleSwitchScreen.driverOptionKey);
      await tap(ProfileScreen.vehiclesItemKey);
      await shot('28-vehicles');
      await tap(DriverVehiclesScreen.vehicleKey('preview_vehicle_largus'));
      await shot('29-vehicle-details');
      await tap(DriverVehicleDetailsScreen.editButtonKey);
      await shot('30-vehicle-edit');
      await go(AppRoutes.profileVehicleNew);
      await shot('31-vehicle-new');
      await go(AppRoutes.createTrip);
      await shot('32-create-type');
      await next();
      await tester.enterText(
        find.byKey(CreateTripRouteScreen.originFieldKey),
        'Москва',
      );
      await tester.enterText(
        find.byKey(CreateTripRouteScreen.destinationFieldKey),
        'Тверь',
      );
      await tap(CreateTripRouteScreen.dateFieldKey);
      await shot('33-create-date');
      await tap(TripDatePickerSheet.dayKey(2));
      await tap(CreateTripRouteScreen.departureTimeFieldKey);
      await shot('34-create-time');
      await tap(TripTimePickerSheet.slotKey('10:00'));
      await tap(CreateTripRouteScreen.arrivalTimeFieldKey);
      await tap(TripTimePickerSheet.slotKey('18:00'));
      await tap(CreateTripSeatCounter.increaseKey);
      await shot('35-create-route');
      await next();
      await tester.enterText(
        find.byKey(CreateTripPricingScreen.fullRouteFieldKey),
        '1800',
      );
      await shot('36-create-price');
      await next();
      await shot('37-create-vehicle');
      await tap(DriverVehiclePicker.vehicleKey('preview_vehicle_largus'));
      await next();
      await shot('38-create-extras');
      await next();
      await shot('39-create-booking-mode');
      await tap(CreateTripBookingModeScreen.instantOptionKey);
      await tap(CreateTripBookingModeScreen.publishButtonKey);
      await shot('40-published-preview');
      expect(container.read(driverTripsProvider), hasLength(1));
      await tap(TripPublishedScreen.myTripsButtonKey);
      await shot('41-driver-trips');
      expect(find.byType(DriverTripsScreen), findsOneWidget);
      await go(AppRoutes.profile);
      await tap(ProfileScreen.logoutButtonKey);
      await tap(ProfileScreen.logoutConfirmKey);
      expect(container.read(chatsProvider), isEmpty);
      expect(container.read(driverTripsProvider), isEmpty);
      await shot('42-logout');
      await go(AppRoutes.orders);
      expect(find.byType(PhoneAuthScreen), findsOneWidget);
      await shot('43-protected-route');
    },
  );
}
