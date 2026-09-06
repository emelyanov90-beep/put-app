import 'package:flutter/material.dart';
import 'package:vput/features/profile/presentation/driver_profile_screen.dart';
import 'package:vput/features/trips/application/booking_controller.dart';
import 'package:vput/features/trips/domain/booking_repository.dart';
import 'package:vput/core/config/app_config.dart';
import 'package:vput/features/auth/application/preview_session_controller.dart';
import 'package:vput/features/auth/domain/russian_phone_formatter.dart';
import 'package:vput/features/profile/application/user_profile_controller.dart';
import 'package:vput/features/location/application/location_prompt_controller.dart';
import 'package:vput/features/trips/application/passenger_trip_search_controller.dart';
import 'package:vput/features/vehicles/application/driver_vehicles_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vput/features/auth/data/preview_sms_code.dart';
import 'package:vput/features/auth/presentation/phone_auth_screen.dart';
import 'package:vput/features/auth/presentation/sms_code_screen.dart';
import 'package:vput/features/chat/application/chats_controller.dart';
import 'package:vput/features/complaints/application/complaints_controller.dart';
import 'package:vput/features/notifications/application/notifications_controller.dart';
import 'package:vput/features/payment/application/payment_methods_controller.dart';
import 'package:vput/features/saved_routes/application/saved_routes_controller.dart';
import 'package:vput/features/chat/presentation/chat_screen.dart';
import 'package:vput/features/chat/presentation/chats_screen.dart';
import 'package:vput/features/city/presentation/city_selection_page.dart';
import 'package:vput/features/foundation/presentation/pending_flow_screen.dart';
import 'package:vput/features/legal/data/legal_documents.dart';
import 'package:vput/features/legal/presentation/legal_document_screen.dart';
import 'package:vput/features/onboarding/application/onboarding_draft_controller.dart';
import 'package:vput/features/onboarding/presentation/onboarding_slide_one_screen.dart';
import 'package:vput/features/onboarding/presentation/onboarding_slide_three_screen.dart';
import 'package:vput/features/onboarding/presentation/onboarding_slide_two_screen.dart';
import 'package:vput/features/onboarding/presentation/welcome_screen.dart';
import 'package:vput/features/profile/application/profile_draft_controller.dart';
import 'package:vput/features/complaints/presentation/complaints_screen.dart';
import 'package:vput/features/notifications/presentation/notifications_screen.dart';
import 'package:vput/features/payment/presentation/payment_methods_screen.dart';
import 'package:vput/features/profile/presentation/about_app_screen.dart';
import 'package:vput/features/profile/presentation/create_profile_screen.dart';
import 'package:vput/features/profile/presentation/faq_screen.dart';
import 'package:vput/features/profile/presentation/order_history_screen.dart';
import 'package:vput/features/saved_routes/presentation/saved_routes_screen.dart';
import 'package:vput/features/profile/presentation/personal_data_screen.dart';
import 'package:vput/features/profile/presentation/profile_loading_screen.dart';
import 'package:vput/features/profile/presentation/profile_screen.dart';
import 'package:vput/features/profile/presentation/role_switch_screen.dart';
import 'package:vput/features/system/presentation/account_blocked_screen.dart';
import 'package:vput/features/trips/application/driver_trips_controller.dart';
import 'package:vput/features/trips/application/passenger_order_draft_controller.dart';
import 'package:vput/features/trips/application/passenger_orders_provider.dart';
import 'package:vput/features/trips/application/trip_draft_controller.dart';
import 'package:vput/features/trips/data/preview_trip_catalog_repository.dart';
import 'package:vput/features/trips/data/preview_passenger_orders.dart';
import 'package:vput/features/trips/domain/driver_trip.dart';
import 'package:vput/features/trips/domain/passenger_booking_request.dart';
import 'package:vput/features/trips/domain/passenger_order.dart';
import 'package:vput/features/trips/domain/passenger_trip.dart';
import 'package:vput/features/trips/presentation/driver/create_trip_pricing_screen.dart';
import 'package:vput/features/trips/presentation/driver/create_trip_route_screen.dart';
import 'package:vput/features/trips/presentation/driver/create_return_trip_screen.dart';
import 'package:vput/features/trips/presentation/driver/create_trip_booking_mode_screen.dart';
import 'package:vput/features/trips/presentation/driver/create_trip_extras_screen.dart';
import 'package:vput/features/trips/presentation/driver/create_trip_summary_screen.dart';
import 'package:vput/features/trips/presentation/driver/create_trip_type_screen.dart';
import 'package:vput/features/trips/presentation/driver/create_trip_vehicle_screen.dart';
import 'package:vput/features/trips/presentation/driver/driver_trip_details_screen.dart';
import 'package:vput/features/trips/presentation/driver/driver_trips_screen.dart';
import 'package:vput/features/trips/presentation/driver/edit_trip_pricing_screen.dart';
import 'package:vput/features/trips/presentation/driver/passenger_profile_screen.dart';
import 'package:vput/features/trips/presentation/driver/trip_published_screen.dart';
import 'package:vput/features/trips/presentation/driver/driver_booking_request_screen.dart';
import 'package:vput/features/trips/presentation/widgets/new_booking_request_watcher.dart';
import 'package:vput/features/trips/presentation/widgets/saved_changes_snack_bar.dart';
import 'package:vput/features/vehicles/presentation/driver_vehicle_details_screen.dart';
import 'package:vput/features/vehicles/presentation/driver_vehicle_form_screen.dart';
import 'package:vput/features/vehicles/presentation/driver_vehicles_screen.dart';
import 'package:vput/features/trips/presentation/booking/passenger_booking_success_screen.dart';
import 'package:vput/features/trips/presentation/passenger_booking_cancellation_result_screen.dart';
import 'package:vput/features/trips/presentation/passenger_order_schedule_screen.dart';
import 'package:vput/features/trips/presentation/passenger_order_extras_screen.dart';
import 'package:vput/features/trips/presentation/passenger_order_summary_screen.dart';
import 'package:vput/features/trips/presentation/passenger_order_type_screen.dart';
import 'package:vput/features/trips/presentation/passenger_order_details_screen.dart';
import 'package:vput/features/trips/presentation/passenger_orders_screen.dart';
import 'package:vput/features/trips/presentation/passenger_trips_page.dart';
import 'package:vput/features/trips/presentation/trip_details_screen.dart';
import 'package:vput/features/system/presentation/system_failure_view.dart';
import 'package:vput/features/system/presentation/system_loading_screen.dart';

abstract final class AppRoutes {
  static const welcome = '/';
  static const onboardingSlideOne = '/onboarding/1';
  static const onboardingSlideTwo = '/onboarding/2';
  static const onboardingSlideThree = '/onboarding/3';
  static const city = '/city';
  static const phoneAuth = '/auth/phone';
  static const termsAcceptance = '/auth/phone/terms';
  static const termsOfService = '/legal/terms';
  static const privacyPolicy = '/legal/privacy';
  static const otpVerify = '/auth/otp';
  static const accountBlocked = '/account-blocked';
  static const createProfile = '/profile/create';
  static const profileLoading = '/profile/loading';
  static const home = '/home';
  static const tripDetails = '/trips/:tripId';
  static const bookingSuccess = '/trips/:tripId/booking/success';
  static const orders = '/orders';
  static const orderDetails = '/orders/:orderId';
  static const createPassengerOrderType = '/orders/create/type';
  static const createPassengerOrderSchedule = '/orders/create/schedule';
  static const createPassengerOrderExtras = '/orders/create/extras';
  static const createPassengerOrderSummary = '/orders/create/summary';
  static const driverTrips = '/trips/mine';
  static const driverBookingRequest = '/trips/mine/:tripId/requests/:bookingId';
  static const createTrip = '/trips/create';
  static const createTripRoute = '/trips/create/route';
  static const createTripPricing = '/trips/create/pricing';
  static const createTripVehicle = '/trips/create/vehicle';
  static const editTripPricing = '/trips/create/edit-pricing';
  static const createTripExtras = '/trips/create/extras';
  static const createTripBooking = '/trips/create/booking';
  static const createTripSummary = '/trips/create/summary';
  static const createReturnTrip = '/trips/create/return';
  static const tripPublished = '/trips/create/published';
  static const chats = '/chats';
  static const chatThread = '/chats/:threadId';
  static const profile = '/profile';
  static const profileRole = '/profile/role';
  static const profilePersonalData = '/profile/personal';
  static const profileVehicles = '/profile/vehicles';
  static const profileVehicleNew = '/profile/vehicles/new';
  static const profileVehicleDetails = '/profile/vehicles/:vehicleId';
  static const profileVehicleEdit = '/profile/vehicles/:vehicleId/edit';
  static const profileSavedRoutes = '/profile/routes';
  static const profileOrderHistory = '/profile/order-history';
  static const profileComplaints = '/profile/complaints';
  static const profileNotifications = '/profile/notifications';
  static const profilePaymentMethod = '/profile/payment';
  static const profileFaq = '/profile/faq';
  static const profileAbout = '/profile/about';
}

/// A wizard step opened from the summary saves and returns instead of moving
/// on to the next step.
bool _isEditingStep(GoRouterState state) =>
    state.uri.queryParameters['edit'] == '1';

void _backOrHome(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(AppRoutes.home);
  }
}

String _editing(String route) => '$route?edit=1';

/// Stores the edits of a trip opened from «Мои поездки», keeping its state.
Future<void> _saveEditedTrip(
  BuildContext context,
  Ref ref, {
  bool leave = true,
}) async {
  final id = ref.read(editedDriverTripProvider);
  if (id == null) return;
  await ref
      .read(driverTripsProvider.notifier)
      .updateTripPersisted(id, ref.read(tripDraftProvider));
  if (!context.mounted) return;
  showSavedChangesSnackBar(context);
  if (!leave) return;
  ref.read(editedDriverTripProvider.notifier).clear();
  context.go(AppRoutes.driverTrips);
}

/// Opens the conversation with a passenger, creating it on the first visit.
void _openPassengerChat(
  BuildContext context,
  Ref ref,
  DriverTripPassengerBooking passenger, {
  String? tripId,
}) {
  final threadId = ref
      .read(chatsProvider.notifier)
      .openThread(
        peerId: passenger.passengerId,
        peerName: passenger.passengerName,
        peerAvatarAsset: passenger.passengerAvatarAsset,
        tripId: tripId,
      );
  context.push('${AppRoutes.chats}/$threadId');
}

void _leaveCreateTrip(BuildContext context) {
  if (context.canPop()) {
    context.pop();
    return;
  }
  context.go(AppRoutes.driverTrips);
}

void _startPassengerOrder(BuildContext context, Ref ref) {
  ref.read(passengerOrderDraftProvider.notifier).reset();
  context.push(AppRoutes.createPassengerOrderType);
}

Future<void> _handlePassengerBookingSubmitted(
  BuildContext context,
  Ref ref,
  PassengerTrip trip,
  PassengerBookingRequest request,
) => _handleBookingCreated(
  context,
  ref,
  trip,
  () => ref.read(bookingControllerProvider.notifier).create(request),
  pendingMessage: 'Заявка отправлена. Ожидайте решения водителя.',
);

Future<void> _handlePassengerParcelSubmitted(
  BuildContext context,
  Ref ref,
  PassengerTrip trip,
  PassengerParcelRequest request,
) => _handleBookingCreated(
  context,
  ref,
  trip,
  () => ref.read(bookingControllerProvider.notifier).createParcel(request),
  pendingMessage: 'Заявка на посылку отправлена. Ожидайте решения водителя.',
);

/// Shared tail of both passenger requests: a seat and a parcel differ only in
/// how the booking is created, then follow the same approval/payment path.
Future<void> _handleBookingCreated(
  BuildContext context,
  Ref ref,
  PassengerTrip trip,
  Future<BookingActionResult?> Function() create, {
  required String pendingMessage,
}) async {
  final controller = ref.read(bookingControllerProvider.notifier);
  final result = await create();
  if (!context.mounted) return;
  if (result == null) {
    final error = ref.read(bookingControllerProvider).error;
    if (error is BookingFailure) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
    return;
  }
  if (result.isPaid) {
    context.push('/trips/${trip.id}/booking/success');
    return;
  }
  if (result.status == PassengerBookingStatus.pendingDriver) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(pendingMessage)));
    return;
  }
  final pay = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Бронирование ожидает оплаты'),
      content: const Text(
        'Оплата выполняется в тестовом режиме, без списания денег.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Позже'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Оплатить'),
        ),
      ],
    ),
  );
  if (pay != true || !context.mounted) return;
  final paid = await controller.pay(result);
  if (!context.mounted) return;
  if (paid?.isPaid == true) {
    context.push('/trips/${trip.id}/booking/success');
  } else {
    final error = ref.read(bookingControllerProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error is BookingFailure
              ? error.message
              : 'Оплата ещё не подтверждена. Попробуйте ещё раз.',
        ),
      ),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(previewSessionProvider, (_, _) => refresh.value++);
  final router = GoRouter(
    refreshListenable: refresh,
    redirect: (context, state) {
      final path = state.uri.path;
      final public =
          path == AppRoutes.welcome ||
          path.startsWith('/onboarding/') ||
          path.startsWith('/auth/') ||
          path.startsWith('/legal/') ||
          path == AppRoutes.accountBlocked;
      if (!public && !ref.read(previewSessionProvider)) {
        return AppRoutes.phoneAuth;
      }
      if ((path == AppRoutes.otpVerify || path == AppRoutes.termsAcceptance) &&
          state.extra is! String &&
          ref.read(onboardingDraftProvider).phone == null) {
        return AppRoutes.phoneAuth;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => WelcomeScreen(
          onStart: () {
            ref.read(onboardingDraftProvider.notifier).beginRegistration();
            ref.read(profileDraftProvider.notifier).reset();
            context.go(AppRoutes.onboardingSlideOne);
          },
          onSignIn: () {
            ref.read(onboardingDraftProvider.notifier).beginSignIn();
            ref.read(profileDraftProvider.notifier).reset();
            context.go(AppRoutes.phoneAuth);
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.onboardingSlideOne,
        builder: (context, state) => OnboardingSlideOneScreen(
          onContinue: () => context.go(AppRoutes.onboardingSlideTwo),
        ),
      ),
      GoRoute(
        path: AppRoutes.onboardingSlideTwo,
        builder: (context, state) => OnboardingSlideTwoScreen(
          onContinue: () => context.go(AppRoutes.phoneAuth),
        ),
      ),
      GoRoute(
        path: AppRoutes.onboardingSlideThree,
        builder: (context, state) => OnboardingSlideThreeScreen(
          onDriverSelected: () {
            ref
                .read(onboardingDraftProvider.notifier)
                .selectRole(OnboardingRole.driver);
            context.go(AppRoutes.city);
          },
          onPassengerSelected: () {
            ref
                .read(onboardingDraftProvider.notifier)
                .selectRole(OnboardingRole.passenger);
            context.go(AppRoutes.city);
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.city,
        builder: (context, state) => CitySelectionPage(
          onContinue: (city) async {
            ref
                .read(onboardingDraftProvider.notifier)
                .selectCity(id: city.id, name: city.name);
            final draft = ref.read(onboardingDraftProvider);
            final profile = ref.read(userProfileProvider).profile;
            try {
              final record = await ref
                  .read(previewSessionProvider.notifier)
                  .updateProfile(
                    name: profile.name,
                    cityId: city.id,
                    role: draft.role?.name ?? 'passenger',
                  );
              if (!context.mounted) return;
              ref
                  .read(userProfileProvider.notifier)
                  .loadFromServerRecord(record);
              context.go(AppRoutes.home);
            } on AuthFailure catch (error) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(error.message)));
            }
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.phoneAuth,
        builder: (context, state) => PhoneAuthScreen(
          onCodeRequested: (phone) async {
            final normalized = RussianPhoneFormatter.normalize(phone);
            try {
              await ref
                  .read(previewSessionProvider.notifier)
                  .requestCode(normalized);
              if (!context.mounted) return;
              ref.read(onboardingDraftProvider.notifier).setPhone(normalized);
              context.push(AppRoutes.termsAcceptance, extra: normalized);
            } on AuthFailure catch (error) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(error.message)));
            }
          },
          onOpenTermsOfService: () => context.push(AppRoutes.termsOfService),
          onOpenPrivacyPolicy: () => context.push(AppRoutes.privacyPolicy),
        ),
      ),
      GoRoute(
        path: AppRoutes.termsAcceptance,
        builder: (context, state) {
          final phone = state.extra is String
              ? state.extra! as String
              : ref.read(onboardingDraftProvider).phone!;
          return LegalDocumentScreen(
            title: 'Условия использования',
            sections: termsOfServiceSections,
            onBack: () => _backOrHome(context),
            onAccept: () =>
                context.pushReplacement(AppRoutes.otpVerify, extra: phone),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.termsOfService,
        builder: (context, state) => LegalDocumentScreen(
          title: 'Условия использования',
          sections: termsOfServiceSections,
          onBack: () => _backOrHome(context),
        ),
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        builder: (context, state) => LegalDocumentScreen(
          title: 'Политика конфиденциальности',
          sections: privacyPolicySections,
          onBack: () => _backOrHome(context),
        ),
      ),
      GoRoute(
        path: AppRoutes.otpVerify,
        builder: (context, state) {
          final phone = state.extra is String
              ? state.extra! as String
              : ref.read(onboardingDraftProvider).phone!;
          return SmsCodeScreen(
            phone: phone,
            expectedCode: previewValidSmsCode,
            onVerified: () async {
              final entryMode = ref.read(
                onboardingDraftProvider.select((draft) => draft.authEntryMode),
              );
              try {
                final result = await ref
                    .read(previewSessionProvider.notifier)
                    .verifyCode(
                      phone,
                      previewValidSmsCode,
                      previewProfileCompleted:
                          entryMode != AuthEntryMode.registration,
                    );
                if (!context.mounted) return;
                ref
                    .read(userProfileProvider.notifier)
                    .loadFromServerRecord(result.record);
                if (entryMode != AuthEntryMode.registration ||
                    result.profileCompleted) {
                  ref
                      .read(onboardingDraftProvider.notifier)
                      .selectRole(
                        result.record['primary_role'] == 'driver'
                            ? OnboardingRole.driver
                            : OnboardingRole.passenger,
                      );
                }
                context.go(
                  result.profileCompleted
                      ? AppRoutes.home
                      : AppRoutes.createProfile,
                );
              } on AuthFailure catch (error) {
                if (!context.mounted) return;
                if (error.code == 'ACCOUNT_BLOCKED') {
                  context.go(AppRoutes.accountBlocked);
                  return;
                }
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(error.message)));
              }
            },
            onBack: () => _backOrHome(context),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.accountBlocked,
        builder: (context, state) => const AccountBlockedScreen(),
      ),
      GoRoute(
        path: AppRoutes.createProfile,
        builder: (context, state) => CreateProfileScreen(
          onContinue: () {
            ref
                .read(userProfileProvider.notifier)
                .completeRegistration(
                  ref.read(profileDraftProvider),
                  ref.read(onboardingDraftProvider).phone ?? '',
                );
            context.go(AppRoutes.profileLoading);
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.profileLoading,
        builder: (context, state) => ProfileLoadingScreen(
          onCompleted: () => context.go(AppRoutes.onboardingSlideThree),
        ),
      ),
      GoRoute(
        path: AppRoutes.home,
        // The driver section of the app is trip creation (PRODUCT_RULES 5-6).
        redirect: (context, state) {
          final role = ref.read(
            onboardingDraftProvider.select((draft) => draft.role),
          );
          return role == OnboardingRole.driver ? AppRoutes.createTrip : null;
        },
        // Only a passenger reaches the builder: a driver is redirected above.
        builder: (context, state) => PassengerTripsPage(
          onOrders: () => context.go(AppRoutes.orders),
          onCreate: () => _startPassengerOrder(context, ref),
          onChats: () => context.go(AppRoutes.chats),
          onProfile: () => context.go(AppRoutes.profile),
          onTripSelected: (trip) =>
              context.push('/trips/${trip.id}', extra: trip),
        ),
      ),
      GoRoute(
        path: AppRoutes.driverTrips,
        builder: (context, state) => NewBookingRequestWatcher(
          onOpenRequest: (request) => context.push(
            '${AppRoutes.driverTrips}/${request.trip.id}/requests'
            '/${request.booking.id}',
          ),
          onOpenPaidTrip: (paid) =>
              context.push('/driver-trips/${paid.trip.id}'),
          child: DriverTripsScreen(
            onBack: () => context.canPop()
                ? context.pop()
                : context.go(AppRoutes.profile),
            onCreateTrip: () {
              ref.read(tripDraftProvider.notifier).reset();
              ref.read(editedDriverTripProvider.notifier).clear();
              context.push(AppRoutes.createTrip);
            },
            onEdit: (trip) {
              ref.read(tripDraftProvider.notifier).load(trip.draft);
              ref.read(editedDriverTripProvider.notifier).select(trip.id);
              context.push(_editing(AppRoutes.createTripRoute));
            },
            onPublish: (trip) async {
              await ref
                  .read(driverTripsProvider.notifier)
                  .publishPersisted(trip.draft, id: trip.id);
            },
            onTripSelected: (trip) => context.push('/driver-trips/${trip.id}'),
            onPassengerProfile: (booking) => context.push(
              '/passengers/${booking.passengerId}',
              extra: booking,
            ),
            onPassengerChat: (booking) =>
                _openPassengerChat(context, ref, booking),
            onDriverBlocked: () => context.go(AppRoutes.accountBlocked),
            onTrips: () => context.go(AppRoutes.home),
            onOrders: () {},
            onChats: () => context.go(AppRoutes.chats),
            onProfile: () => context.go(AppRoutes.profile),
            onCreateReturnTrip: (trip) {
              ref.read(tripDraftProvider.notifier)
                ..load(trip.draft)
                ..startReturnTrip(sourceTripId: trip.id);
              ref.read(editedDriverTripProvider.notifier).clear();
              context.push(AppRoutes.createReturnTrip);
            },
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.driverBookingRequest,
        builder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          final bookingId = state.pathParameters['bookingId']!;
          final trip = ref.read(driverTripsProvider.notifier).findById(tripId);
          final booking = trip?.passengerBookings
              .where((item) => item.id == bookingId)
              .firstOrNull;
          if (trip == null || booking == null) {
            return const PendingFlowScreen(title: 'Отклик не найден');
          }
          return DriverBookingRequestScreen(
            trip: trip,
            booking: booking,
            onBack: () => _backOrHome(context),
            onOpenPassenger: () => context.push(
              '/passengers/${booking.passengerId}',
              extra: booking,
            ),
            // The decision lands the driver on the trip itself, where the
            // passenger list already shows what changed.
            onApprove: () async {
              final approved = await ref
                  .read(driverTripsProvider.notifier)
                  .approvePassengerBookingPersisted(
                    tripId: tripId,
                    bookingId: bookingId,
                  );
              if (!context.mounted) return;
              if (!approved) {
                showSavedChangesSnackBar(
                  context,
                  message: 'Недостаточно мест или заявка больше недоступна.',
                );
                return;
              }
              context.pushReplacement('/driver-trips/$tripId');
              showSavedChangesSnackBar(context, message: 'Бронь подтверждена');
            },
            onReject: () async {
              await ref
                  .read(driverTripsProvider.notifier)
                  .rejectPassengerBookingPersisted(
                    tripId: tripId,
                    bookingId: bookingId,
                  );
              if (!context.mounted) return;
              context.pushReplacement('/driver-trips/$tripId');
              showSavedChangesSnackBar(context, message: 'Бронь отклонена');
            },
          );
        },
      ),
      GoRoute(
        path: '/driver-trips/:tripId',
        builder: (context, state) {
          final id = state.pathParameters['tripId']!;
          final trip = ref.read(driverTripsProvider.notifier).findById(id);
          if (trip == null) {
            return const PendingFlowScreen(title: 'Поездка не найдена');
          }
          return DriverTripDetailsScreen(
            trip: trip,
            onBack: () => _backOrHome(context),
            onEdit: () {
              ref.read(tripDraftProvider.notifier).load(trip.draft);
              ref.read(editedDriverTripProvider.notifier).select(trip.id);
              context.push(_editing(AppRoutes.createTripRoute));
            },
            onRepeatTrip: () {
              ref
                  .read(tripDraftProvider.notifier)
                  .load(
                    trip.draft.copyWith(
                      clearDepartureAt: true,
                      clearArrivalAt: true,
                      clearPairedTripId: true,
                    ),
                  );
              ref.read(editedDriverTripProvider.notifier).clear();
              context.push(AppRoutes.createTripRoute);
            },
            onSeatCapacityChanged: (value) async {
              await ref
                  .read(driverTripsProvider.notifier)
                  .setSeatCapacityPersisted(trip.id, value);
              if (!context.mounted) return;
              context.pushReplacement('/driver-trips/${trip.id}');
              showSavedChangesSnackBar(context);
            },
            onClosePassengerRegistration: () async {
              await ref
                  .read(driverTripsProvider.notifier)
                  .closePassengerRegistrationPersisted(trip.id);
              if (!context.mounted) return;
              context.pushReplacement('/driver-trips/${trip.id}');
              showSavedChangesSnackBar(
                context,
                message: 'Приём пассажиров завершён',
              );
            },
            onPassenger: (booking) => context.push(
              '/passengers/${booking.passengerId}',
              extra: booking,
            ),
            onCancelTrip: () async {
              final outcome = await ref
                  .read(driverTripsProvider.notifier)
                  .cancelPersisted(trip.id);
              if (!context.mounted) return;
              switch (outcome) {
                case DriverTripCancellationOutcome.removed:
                  context.go(AppRoutes.driverTrips);
                case DriverTripCancellationOutcome.warningIssued:
                  context.go(AppRoutes.driverTrips);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Поездка отменена. Отмена с пассажирами засчитана.',
                      ),
                    ),
                  );
                case DriverTripCancellationOutcome.blocked:
                  context.go(AppRoutes.accountBlocked);
              }
            },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.createTrip,
        builder: (context, state) {
          final editing = _isEditingStep(state);
          return CreateTripTypeScreen(
            isEditing: editing,
            onBack: () => _leaveCreateTrip(context),
            onContinue: editing
                ? () => _backOrHome(context)
                : () => context.push(AppRoutes.createTripRoute),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.createTripRoute,
        builder: (context, state) {
          final editing = _isEditingStep(state);
          return CreateTripRouteScreen(
            isEditing: editing,
            onBack: () => _leaveCreateTrip(context),
            onContinue: () => context.push(AppRoutes.createTripPricing),
            onEditPricing: () => context.push(AppRoutes.editTripPricing),
            onSave: () => _saveEditedTrip(context, ref),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.editTripPricing,
        builder: (context, state) => EditTripPricingScreen(
          onBack: () => _backOrHome(context),
          onSave: () async {
            await _saveEditedTrip(context, ref, leave: false);
            if (!context.mounted) return;
            context.pop();
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.createTripPricing,
        builder: (context, state) {
          final editing = _isEditingStep(state);
          return CreateTripPricingScreen(
            isEditing: editing,
            onBack: () => _backOrHome(context),
            onContinue: editing
                ? () => _backOrHome(context)
                : () => context.push(AppRoutes.createTripVehicle),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.createTripVehicle,
        builder: (context, state) {
          final editing = _isEditingStep(state);
          return CreateTripVehicleScreen(
            isEditing: editing,
            onBack: () => _backOrHome(context),
            onAddVehicle: () => context.push(AppRoutes.profileVehicles),
            onContinue: editing
                ? () => _backOrHome(context)
                : () => context.push(AppRoutes.createTripExtras),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.createTripExtras,
        builder: (context, state) {
          final editing = _isEditingStep(state);
          return CreateTripExtrasScreen(
            isEditing: editing,
            onBack: () => _backOrHome(context),
            onContinue: editing
                ? () => _backOrHome(context)
                : () => context.push(AppRoutes.createTripBooking),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.createTripBooking,
        builder: (context, state) => CreateTripBookingModeScreen(
          onBack: () => _backOrHome(context),
          onPublish: () async {
            final id = await ref
                .read(driverTripsProvider.notifier)
                .publishPersisted(
                  ref.read(tripDraftProvider),
                  id: ref.read(editedDriverTripProvider),
                );
            if (!context.mounted) return;
            ref.read(editedDriverTripProvider.notifier).clear();
            context.push(AppRoutes.tripPublished, extra: id);
          },
          onSaveTemplate: () async {
            await ref
                .read(driverTripsProvider.notifier)
                .saveDraftPersisted(
                  ref.read(tripDraftProvider),
                  id: ref.read(editedDriverTripProvider),
                );
            if (!context.mounted) return;
            ref.read(editedDriverTripProvider.notifier).clear();
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Шаблон сохранён')));
            context.go(AppRoutes.driverTrips);
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.createTripSummary,
        builder: (context, state) => CreateTripSummaryScreen(
          onBack: () => _backOrHome(context),
          onPublish: () async {
            final id = await ref
                .read(driverTripsProvider.notifier)
                .publishPersisted(
                  ref.read(tripDraftProvider),
                  id: ref.read(editedDriverTripProvider),
                );
            if (!context.mounted) return;
            ref.read(editedDriverTripProvider.notifier).clear();
            context.push(AppRoutes.tripPublished, extra: id);
          },
          onSaveDraft: () async {
            await ref
                .read(driverTripsProvider.notifier)
                .saveDraftPersisted(
                  ref.read(tripDraftProvider),
                  id: ref.read(editedDriverTripProvider),
                );
            if (!context.mounted) return;
            ref.read(editedDriverTripProvider.notifier).clear();
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Черновик сохранён')));
            context.go(AppRoutes.driverTrips);
          },
          onEditType: () => context.push(_editing(AppRoutes.createTrip)),
          onEditRoute: () => context.push(_editing(AppRoutes.createTripRoute)),
          onEditPricing: () =>
              context.push(_editing(AppRoutes.createTripPricing)),
          onEditVehicle: () =>
              context.push(_editing(AppRoutes.createTripVehicle)),
          onEditServices: () =>
              context.push(_editing(AppRoutes.createTripExtras)),
        ),
      ),
      GoRoute(
        path: AppRoutes.createReturnTrip,
        builder: (context, state) => CreateReturnTripScreen(
          onBack: () => _backOrHome(context),
          onPublish: () async {
            final draft = ref.read(tripDraftProvider);
            final id = await ref
                .read(driverTripsProvider.notifier)
                .publishReturnPersisted(draft);
            if (!context.mounted) return;
            context.push(AppRoutes.tripPublished, extra: id);
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.tripPublished,
        builder: (context, state) => TripPublishedScreen(
          isPreview: AppConfig.isPreviewMode,
          onMyTrips: () {
            ref.read(tripDraftProvider.notifier).reset();
            context.go(AppRoutes.driverTrips);
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.tripDetails,
        builder: (context, state) {
          final id = state.pathParameters['tripId']!;
          final trip = state.extra is PassengerTrip
              ? state.extra! as PassengerTrip
              : ref.read(tripCatalogRepositoryProvider).findById(id);
          if (trip == null) {
            return const PendingFlowScreen(title: 'Поездка не найдена');
          }
          return Consumer(
            builder: (context, widgetRef, _) => TripDetailsScreen(
              isBooking: widgetRef.watch(bookingControllerProvider).isLoading,
              trip: trip,
              onBack: () => _backOrHome(context),
              onDriver: () => context.push('/drivers/${trip.id}'),
              onBookingSubmitted: (booking) =>
                  _handlePassengerBookingSubmitted(context, ref, trip, booking),
              onParcelSubmitted: (parcel) =>
                  _handlePassengerParcelSubmitted(context, ref, trip, parcel),
            ),
          );
        },
      ),
      GoRoute(
        path: '/drivers/:tripId',
        builder: (context, state) {
          final id = state.pathParameters['tripId']!;
          final trip =
              ref.read(tripCatalogRepositoryProvider).findById(id) ??
              (AppConfig.isPreviewMode
                  ? previewPassengerOrders
                        .where((order) => order.trip.id == id)
                        .firstOrNull
                        ?.trip
                  : null);
          if (trip == null) {
            return const PendingFlowScreen(title: 'Водитель не найден');
          }
          return DriverProfileScreen(
            trip: trip,
            onBack: () => _backOrHome(context),
          );
        },
      ),
      GoRoute(
        path: '/passengers/:passengerId',
        builder: (context, state) {
          final id = state.pathParameters['passengerId']!;
          final passenger = state.extra is DriverTripPassengerBooking
              ? state.extra! as DriverTripPassengerBooking
              : _findDriverTripPassenger(ref, id);
          if (passenger == null) {
            return const PendingFlowScreen(title: 'Пассажир не найден');
          }
          return PassengerProfileScreen(
            passenger: passenger,
            onBack: () => _backOrHome(context),
            onChat: () => _openPassengerChat(context, ref, passenger),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.bookingSuccess,
        redirect: (_, state) =>
            ref
                    .read(bookingControllerProvider.notifier)
                    .forTrip(state.pathParameters['tripId']!)
                    ?.isPaid ==
                true
            ? null
            : '/trips/${state.pathParameters['tripId']}',
        builder: (context, state) => PassengerBookingSuccessScreen(
          onOrders: () => context.go(AppRoutes.orders),
          onChatDriver: () => context.go(AppRoutes.chats),
        ),
      ),
      GoRoute(
        path: AppRoutes.orders,
        builder: (context, state) => Consumer(
          builder: (context, widgetRef, _) => widgetRef
              .watch(passengerOrdersProvider)
              .when(
                data: (orders) => PassengerOrdersScreen(
                  orders: orders,
                  onTrips: () => context.go(AppRoutes.home),
                  onCreate: () => _startPassengerOrder(context, ref),
                  onChats: () => context.go(AppRoutes.chats),
                  onProfile: () => context.go(AppRoutes.profile),
                  onOrderSelected: (order) =>
                      context.push('/orders/${order.id}', extra: order),
                ),
                loading: () =>
                    const Scaffold(body: SafeArea(child: SystemLoadingView())),
                error: (_, _) => Scaffold(
                  body: SafeArea(
                    child: SystemFailureView(
                      onRetry: () =>
                          widgetRef.invalidate(passengerOrdersProvider),
                    ),
                  ),
                ),
              ),
        ),
      ),
      GoRoute(
        path: AppRoutes.orderDetails,
        builder: (context, state) {
          final id = state.pathParameters['orderId']!;
          final order = state.extra is PassengerOrder
              ? state.extra! as PassengerOrder
              : ref
                        .read(passengerOrdersProvider)
                        .value
                        ?.where((item) => item.id == id)
                        .firstOrNull ??
                    (AppConfig.isPreviewMode
                        ? findPreviewPassengerOrderById(id)
                        : null);
          if (order == null) {
            return const PendingFlowScreen(title: 'Заказ не найден');
          }
          return Consumer(
            builder: (context, widgetRef, _) => PassengerOrderDetailsScreen(
              isCancelling: widgetRef
                  .watch(bookingCancellationProvider)
                  .isLoading,
              order: order,
              onBack: () => _backOrHome(context),
              onDriver: () => context.push('/drivers/${order.trip.id}'),
              onCancellationCompleted: (_) async {
                final receipt = await ref
                    .read(bookingCancellationProvider.notifier)
                    .cancel(order.id);
                if (!context.mounted) return;
                if (receipt == null) {
                  final error = ref.read(bookingCancellationProvider).error;
                  if (error is BookingFailure) {
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(SnackBar(content: Text(error.message)));
                  }
                  return;
                }
                if (!receipt.refundRequested && !receipt.bookingBlocked) {
                  ref.invalidate(passengerOrdersProvider);
                  context.go(AppRoutes.orders);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Бронирование отменено')),
                  );
                  return;
                }
                context.go(
                  '/orders/${order.id}/${receipt.bookingBlocked ? 'blocked' : 'cancelled'}',
                  extra: receipt,
                );
                ref.invalidate(passengerOrdersProvider);
              },
              onChatDriver: () => context.go(AppRoutes.chats),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.createPassengerOrderType,
        builder: (context, state) => PassengerOrderTypeScreen(
          onBack: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.orders),
          onContinue: () =>
              context.push(AppRoutes.createPassengerOrderSchedule),
        ),
      ),
      GoRoute(
        path: AppRoutes.createPassengerOrderSchedule,
        builder: (context, state) => PassengerOrderScheduleScreen(
          onBack: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.orders),
          onContinue: () => context.push(AppRoutes.createPassengerOrderExtras),
        ),
      ),
      GoRoute(
        path: AppRoutes.createPassengerOrderExtras,
        builder: (context, state) => PassengerOrderExtrasScreen(
          onBack: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.orders),
          onContinue: () => context.push(AppRoutes.createPassengerOrderSummary),
        ),
      ),
      GoRoute(
        path: AppRoutes.createPassengerOrderSummary,
        builder: (context, state) => PassengerOrderSummaryScreen(
          onBack: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.orders),
          onFindTrips: (draft) {
            ref.read(passengerTripSearchProvider.notifier)
              ..selectTransport(draft.transportType)
              ..applyFilters(
                origin: draft.points.first.address,
                destination: draft.points.last.address,
              );
            context.go(AppRoutes.home);
          },
        ),
      ),
      GoRoute(
        path: '/orders/:orderId/cancelled',
        redirect: (_, state) =>
            state.extra is BookingCancellationResult ? null : AppRoutes.orders,
        builder: (context, state) {
          return PassengerBookingCancellationResultScreen(
            outcome: PassengerCancellationOutcome.refundRequested,
            refundAmountRubles:
                (state.extra as BookingCancellationResult).refundAmountRubles,
            onDone: () => context.go(AppRoutes.home),
          );
        },
      ),
      GoRoute(
        path: '/orders/:orderId/blocked',
        redirect: (_, state) =>
            state.extra is BookingCancellationResult ? null : AppRoutes.orders,
        builder: (context, state) => PassengerBookingCancellationResultScreen(
          outcome: PassengerCancellationOutcome.bookingBlocked,
          onDone: () => context.go(AppRoutes.home),
        ),
      ),
      GoRoute(
        path: AppRoutes.chats,
        builder: (context, state) => ChatsScreen(
          onTrips: () => context.go(AppRoutes.home),
          onOrders: () => context.go(
            ref.read(onboardingDraftProvider).role == OnboardingRole.driver
                ? AppRoutes.driverTrips
                : AppRoutes.orders,
          ),
          onCreate: () =>
              ref.read(onboardingDraftProvider).role == OnboardingRole.driver
              ? context.go(AppRoutes.createTrip)
              : _startPassengerOrder(context, ref),
          onProfile: () => context.go(AppRoutes.profile),
          onOpenThread: (thread) =>
              context.push('${AppRoutes.chats}/${thread.id}'),
        ),
      ),
      GoRoute(
        path: AppRoutes.chatThread,
        builder: (context, state) => ChatScreen(
          threadId: state.pathParameters['threadId']!,
          onBack: () => _backOrHome(context),
        ),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) {
          final role = ref.read(
            onboardingDraftProvider.select((draft) => draft.role),
          );
          return ProfileScreen(
            onSwitchRole: () => context.push(AppRoutes.profileRole),
            onPersonalData: () => context.push(AppRoutes.profilePersonalData),
            onVehicles: () => context.push(AppRoutes.profileVehicles),
            onSavedRoutes: () => context.push(AppRoutes.profileSavedRoutes),
            onOrderHistory: () => context.push(AppRoutes.profileOrderHistory),
            onComplaints: () => context.push(AppRoutes.profileComplaints),
            onNotifications: () => context.push(AppRoutes.profileNotifications),
            onPaymentMethod: () => context.push(AppRoutes.profilePaymentMethod),
            onFaq: () => context.push(AppRoutes.profileFaq),
            onAbout: () => context.push(AppRoutes.profileAbout),
            onLogout: () {
              ref.read(clearStoredAuthProvider)();
              ref.read(previewSessionProvider.notifier).signOut();
              ref.read(onboardingDraftProvider.notifier).logOut();
              ref.invalidate(profileDraftProvider);
              ref.invalidate(userProfileProvider);
              ref.invalidate(bookingControllerProvider);
              ref.invalidate(bookingCancellationProvider);
              ref.invalidate(chatsProvider);
              ref.invalidate(complaintsProvider);
              ref.invalidate(notificationsProvider);
              ref.invalidate(paymentMethodsProvider);
              ref.invalidate(savedRoutesProvider);
              ref.invalidate(passengerOrdersProvider);
              ref.invalidate(driverTripsProvider);
              ref.invalidate(driverVehiclesProvider);
              ref.invalidate(tripDraftProvider);
              ref.invalidate(editedDriverTripProvider);
              ref.invalidate(passengerOrderDraftProvider);
              ref.invalidate(passengerTripSearchProvider);
              ref.invalidate(seenBookingRequestsProvider);
              ref.invalidate(locationPromptHandledProvider);
              context.go(AppRoutes.welcome);
            },
            onTrips: () => context.go(AppRoutes.home),
            onOrders: () => context.go(
              role == OnboardingRole.driver
                  ? AppRoutes.driverTrips
                  : AppRoutes.orders,
            ),
            onCreate: () => role == OnboardingRole.driver
                ? context.go(AppRoutes.createTrip)
                : _startPassengerOrder(context, ref),
            onChats: () => context.go(AppRoutes.chats),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.profileRole,
        builder: (context, state) {
          final role = ref.read(
            onboardingDraftProvider.select((draft) => draft.role),
          );
          return RoleSwitchScreen(
            currentRole: role ?? OnboardingRole.passenger,
            onBack: () => _backOrHome(context),
            onRoleSelected: (selected) async {
              try {
                await ref
                    .read(previewSessionProvider.notifier)
                    .updateRole(selected.name);
                if (!context.mounted) return;
                ref.read(onboardingDraftProvider.notifier).selectRole(selected);
                context.pop();
              } on AuthFailure catch (error) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(error.message)));
              }
            },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.profilePersonalData,
        builder: (context, state) {
          final role = ref.read(
            onboardingDraftProvider.select((draft) => draft.role),
          );
          return PersonalDataScreen(
            role: role,
            onBack: () => _backOrHome(context),
            onSaved: () => _backOrHome(context),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.profileVehicles,
        builder: (context, state) => DriverVehiclesScreen(
          onBack: () => _backOrHome(context),
          onAddVehicle: () => context.push(AppRoutes.profileVehicleNew),
          onOpenVehicle: (vehicle) =>
              context.push('${AppRoutes.profileVehicles}/${vehicle.id}'),
        ),
      ),
      // «Новое ТС» has to be matched before the vehicle id route.
      GoRoute(
        path: AppRoutes.profileVehicleNew,
        builder: (context, state) => DriverVehicleFormScreen(
          onBack: () => _backOrHome(context),
          onSaved: (id) {
            showSavedChangesSnackBar(context, message: 'Автомобиль добавлен');
            context.pushReplacement('${AppRoutes.profileVehicles}/$id');
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.profileVehicleEdit,
        builder: (context, state) => DriverVehicleFormScreen(
          vehicleId: state.pathParameters['vehicleId'],
          onBack: () => _backOrHome(context),
          onSaved: (_) {
            showSavedChangesSnackBar(context);
            context.pop();
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.profileVehicleDetails,
        builder: (context, state) {
          final id = state.pathParameters['vehicleId']!;
          return DriverVehicleDetailsScreen(
            vehicleId: id,
            onBack: () => _backOrHome(context),
            onEdit: (vehicle) =>
                context.push('${AppRoutes.profileVehicles}/${vehicle.id}/edit'),
            onDeleted: () {
              showSavedChangesSnackBar(context, message: 'ТС удалено');
              context.go(AppRoutes.profileVehicles);
            },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.profileSavedRoutes,
        builder: (context, state) => SavedRoutesScreen(
          onBack: () => _backOrHome(context),
          onRouteSelected: (route) {
            ref
                .read(passengerTripSearchProvider.notifier)
                .applyFilters(
                  origin: route.origin,
                  destination: route.destination,
                );
            context.go(AppRoutes.home);
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.profileOrderHistory,
        builder: (context, state) => OrderHistoryScreen(
          onBack: () => _backOrHome(context),
          onOrderSelected: (order) =>
              context.push('/orders/${order.id}', extra: order),
          onTripSelected: (trip) => context.push('/driver-trips/${trip.id}'),
        ),
      ),
      GoRoute(
        path: AppRoutes.profileComplaints,
        builder: (context, state) =>
            ComplaintsScreen(onBack: () => _backOrHome(context)),
      ),
      GoRoute(
        path: AppRoutes.profileNotifications,
        builder: (context, state) =>
            NotificationsScreen(onBack: () => _backOrHome(context)),
      ),
      GoRoute(
        path: AppRoutes.profilePaymentMethod,
        builder: (context, state) =>
            PaymentMethodsScreen(onBack: () => _backOrHome(context)),
      ),
      GoRoute(
        path: AppRoutes.profileFaq,
        builder: (context, state) =>
            FaqScreen(onBack: () => _backOrHome(context)),
      ),
      GoRoute(
        path: AppRoutes.profileAbout,
        builder: (context, state) => AboutAppScreen(
          onBack: () => _backOrHome(context),
          onTerms: () => context.push(AppRoutes.termsOfService),
          onPrivacy: () => context.push(AppRoutes.privacyPolicy),
        ),
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

DriverTripPassengerBooking? _findDriverTripPassenger(Ref ref, String id) {
  for (final trip in ref.read(driverTripsProvider)) {
    for (final passenger in trip.passengerBookings) {
      if (passenger.passengerId == id) return passenger;
    }
  }
  return null;
}
