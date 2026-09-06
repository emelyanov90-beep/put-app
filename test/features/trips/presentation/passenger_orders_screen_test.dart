import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/trips/data/preview_passenger_orders.dart';
import 'package:vput/features/trips/domain/passenger_order.dart';
import 'package:vput/features/trips/presentation/passenger_orders_screen.dart';

Widget _screen({
  List<PassengerOrder> orders = previewPassengerOrders,
  ValueChanged<PassengerOrder>? onOrderSelected,
  VoidCallback? onCreate,
}) {
  return MaterialApp(
    home: PassengerOrdersScreen(
      orders: orders,
      onTrips: () {},
      onCreate: onCreate ?? () {},
      onChats: () {},
      onProfile: () {},
      onOrderSelected: onOrderSelected ?? (_) {},
    ),
  );
}

void main() {
  testWidgets('shows the empty state and creates an order', (tester) async {
    var creates = 0;
    await tester.pumpWidget(
      _screen(orders: const [], onCreate: () => creates++),
    );

    expect(find.byKey(PassengerOrdersScreen.emptyStateKey), findsOneWidget);
    expect(find.text('У вас пока нет заказов'), findsOneWidget);

    await tester.tap(find.byKey(PassengerOrdersScreen.createOrderButtonKey));
    await tester.pump();

    expect(creates, 1);
  });

  testWidgets('shows active passenger orders and opens details', (
    tester,
  ) async {
    PassengerOrder? selected;
    await tester.pumpWidget(
      _screen(onOrderSelected: (order) => selected = order),
    );

    expect(find.text('Мои заказы'), findsOneWidget);
    expect(
      find.byKey(PassengerOrdersScreen.orderCardKey('1231')),
      findsOneWidget,
    );
    expect(find.text('Место забронировано'), findsOneWidget);
    expect(find.text('Посылка забронирована'), findsOneWidget);

    await tester.tap(find.byKey(PassengerOrdersScreen.orderCardKey('1231')));
    await tester.pump();

    expect(selected?.id, '1231');
  });

  testWidgets('filters active and completed orders', (tester) async {
    await tester.pumpWidget(_screen());

    await tester.tap(find.byKey(PassengerOrdersScreen.activeFilterKey));
    await tester.pump();

    expect(find.text('Место забронировано'), findsOneWidget);
    expect(find.text('Посылка забронирована'), findsOneWidget);
    expect(find.text('Завершен'), findsNothing);

    await tester.tap(find.byKey(PassengerOrdersScreen.completedFilterKey));
    await tester.pump();

    expect(find.text('Место забронировано'), findsNothing);
    expect(find.text('Завершен'), findsOneWidget);
  });
}
