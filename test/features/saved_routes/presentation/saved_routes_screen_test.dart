import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vput/features/auth/application/preview_session_controller.dart';
import 'package:vput/features/saved_routes/application/saved_routes_controller.dart';
import 'package:vput/features/saved_routes/domain/saved_route.dart';
import 'package:vput/features/saved_routes/presentation/saved_routes_screen.dart';

class _AccountController extends Notifier<String> {
  @override
  String build() => 'first';

  void select(String value) => state = value;
}

final _accountProvider = NotifierProvider<_AccountController, String>(
  _AccountController.new,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'saved routes are isolated between accounts on the same device',
    () async {
      final container = ProviderContainer(
        overrides: [
          currentLocalAccountIdProvider.overrideWith(
            (ref) => ref.watch(_accountProvider),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(savedRoutesProvider.future);
      await container
          .read(savedRoutesProvider.notifier)
          .add(title: '', origin: 'Москва', destination: 'Смоленск');
      expect(container.read(savedRoutesProvider).value, hasLength(1));

      container.read(_accountProvider.notifier).select('second');
      expect(await container.read(savedRoutesProvider.future), isEmpty);

      container.read(_accountProvider.notifier).select('first');
      expect(await container.read(savedRoutesProvider.future), hasLength(1));
    },
  );

  testWidgets('saves a route and opens the search with it', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    SavedRoute? opened;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: SavedRoutesScreen(
            onBack: () {},
            onRouteSelected: (route) => opened = route,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ProfileEmptyStateFinder.key), findsOneWidget);

    await tester.tap(find.byKey(SavedRoutesScreen.addButtonKey));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(SavedRoutesScreen.originFieldKey),
      'Москва',
    );
    await tester.enterText(
      find.byKey(SavedRoutesScreen.destinationFieldKey),
      'Тверь',
    );
    await tester.pump();
    await tester.tap(find.byKey(SavedRoutesScreen.saveButtonKey));
    await tester.pumpAndSettle();

    final routes = container.read(savedRoutesProvider).value!;
    expect(routes, hasLength(1));
    expect(routes.single.routeLabel, 'Москва → Тверь');

    await tester.tap(find.byKey(SavedRoutesScreen.routeKey(routes.single.id)));
    await tester.pump();
    expect(opened?.destination, 'Тверь');

    await tester.tap(find.byKey(SavedRoutesScreen.removeKey(routes.single.id)));
    await tester.pumpAndSettle();
    expect(container.read(savedRoutesProvider).value, isEmpty);
  });
}

/// The empty state key lives on a shared widget; named here for readability.
abstract final class ProfileEmptyStateFinder {
  static const key = Key('profile_empty_state');
}
