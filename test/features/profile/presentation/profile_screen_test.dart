import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/onboarding/application/onboarding_draft_controller.dart';
import 'package:vput/features/profile/presentation/profile_screen.dart';

void main() {
  Widget buildScreen({
    required VoidCallback onSwitchRole,
    required VoidCallback onPersonalData,
    required VoidCallback onLogout,
    VoidCallback? onVehicles,
  }) {
    return MaterialApp(
      home: ProfileScreen(
        onSwitchRole: onSwitchRole,
        onPersonalData: onPersonalData,
        onVehicles: onVehicles ?? () {},
        onSavedRoutes: () {},
        onOrderHistory: () {},
        onComplaints: () {},
        onNotifications: () {},
        onPaymentMethod: () {},
        onFaq: () {},
        onAbout: () {},
        onLogout: onLogout,
        onTrips: () {},
        onOrders: () {},
        onCreate: () {},
        onChats: () {},
      ),
    );
  }

  testWidgets('shows the seeded demo profile, rating and trip count', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: buildScreen(
          onSwitchRole: () {},
          onPersonalData: () {},
          onLogout: () {},
        ),
      ),
    );

    expect(find.text('Анастасия'), findsOneWidget);
    expect(find.text('5 звезд, нет отзывов'), findsOneWidget);
    expect(find.text('120 поездок'), findsOneWidget);
    expect(find.text('Перейти в режим водителя'), findsOneWidget);
  });

  testWidgets('flips the switch-role label once the role becomes driver', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container
        .read(onboardingDraftProvider.notifier)
        .selectRole(OnboardingRole.driver);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: buildScreen(
          onSwitchRole: () {},
          onPersonalData: () {},
          onLogout: () {},
        ),
      ),
    );

    expect(find.text('Перейти в режим пассажира'), findsOneWidget);
  });

  testWidgets(
    'shows the vehicles item only for the driver role, and it is tappable',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: buildScreen(
            onSwitchRole: () {},
            onPersonalData: () {},
            onLogout: () {},
          ),
        ),
      );

      expect(find.byKey(ProfileScreen.vehiclesItemKey), findsNothing);

      container
          .read(onboardingDraftProvider.notifier)
          .selectRole(OnboardingRole.driver);
      await tester.pump();

      expect(find.byKey(ProfileScreen.vehiclesItemKey), findsOneWidget);

      var vehiclesTaps = 0;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: buildScreen(
            onSwitchRole: () {},
            onPersonalData: () {},
            onLogout: () {},
            onVehicles: () => vehiclesTaps++,
          ),
        ),
      );

      await tester.tap(find.byKey(ProfileScreen.vehiclesItemKey));
      expect(vehiclesTaps, 1);
    },
  );

  testWidgets('shows the unread notifications badge from the profile', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: buildScreen(
          onSwitchRole: () {},
          onPersonalData: () {},
          onLogout: () {},
        ),
      ),
    );

    expect(find.byKey(ProfileScreen.notificationsBadgeKey), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('taps on menu items invoke their callbacks', (tester) async {
    var switchRoleTaps = 0;
    var personalDataTaps = 0;

    await tester.pumpWidget(
      ProviderScope(
        child: buildScreen(
          onSwitchRole: () => switchRoleTaps++,
          onPersonalData: () => personalDataTaps++,
          onLogout: () {},
        ),
      ),
    );

    await tester.tap(find.byKey(ProfileScreen.switchRoleItemKey));
    await tester.tap(find.byKey(ProfileScreen.personalDataItemKey));

    expect(switchRoleTaps, 1);
    expect(personalDataTaps, 1);
  });

  testWidgets('logout requires confirmation before calling onLogout', (
    tester,
  ) async {
    var logoutTaps = 0;

    await tester.pumpWidget(
      ProviderScope(
        child: buildScreen(
          onSwitchRole: () {},
          onPersonalData: () {},
          onLogout: () => logoutTaps++,
        ),
      ),
    );

    await tester.ensureVisible(find.byKey(ProfileScreen.logoutButtonKey));
    await tester.tap(find.byKey(ProfileScreen.logoutButtonKey));
    await tester.pumpAndSettle();

    expect(find.byKey(ProfileScreen.logoutDialogKey), findsOneWidget);
    expect(logoutTaps, 0);

    await tester.tap(find.byKey(ProfileScreen.logoutCancelKey));
    await tester.pumpAndSettle();

    expect(find.byKey(ProfileScreen.logoutDialogKey), findsNothing);
    expect(logoutTaps, 0);

    await tester.ensureVisible(find.byKey(ProfileScreen.logoutButtonKey));
    await tester.tap(find.byKey(ProfileScreen.logoutButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ProfileScreen.logoutConfirmKey));
    await tester.pumpAndSettle();

    expect(logoutTaps, 1);
  });
}
