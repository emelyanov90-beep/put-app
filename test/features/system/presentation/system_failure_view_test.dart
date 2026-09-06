import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/system/data/device_connectivity_service.dart';
import 'package:vput/features/system/domain/connectivity_service.dart';
import 'package:vput/features/system/presentation/system_failure_view.dart';
import 'package:vput/features/system/presentation/system_message_view.dart';

class _FakeConnectivityService implements ConnectivityService {
  _FakeConnectivityService(this._online);

  final bool _online;

  @override
  Future<bool> hasConnection() async => _online;

  @override
  Stream<bool> watchConnection() => Stream.value(_online);
}

class _UnavailableConnectivityService implements ConnectivityService {
  @override
  Future<bool> hasConnection() async => true;

  @override
  Stream<bool> watchConnection() => const Stream.empty();
}

void main() {
  Future<void> pumpFailureView(
    WidgetTester tester, {
    required ConnectivityService service,
    VoidCallback? onRetry,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [connectivityServiceProvider.overrideWithValue(service)],
        child: MaterialApp(
          home: Scaffold(body: SystemFailureView(onRetry: onRetry ?? () {})),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('offline device gets the no-internet copy', (tester) async {
    await pumpFailureView(tester, service: _FakeConnectivityService(false));

    expect(find.byKey(SystemFailureView.noInternetKey), findsOneWidget);
    expect(find.byKey(SystemFailureView.errorKey), findsNothing);
    expect(find.text('Нет интернет-соединения'), findsOneWidget);
    expect(find.text('Обновить'), findsOneWidget);
  });

  testWidgets('online device gets the generic error copy', (tester) async {
    await pumpFailureView(tester, service: _FakeConnectivityService(true));

    expect(find.byKey(SystemFailureView.errorKey), findsOneWidget);
    expect(find.byKey(SystemFailureView.noInternetKey), findsNothing);
    expect(find.text('Не удалось выполнить действие'), findsOneWidget);
  });

  testWidgets('undetermined connectivity does not blame the network', (
    tester,
  ) async {
    await pumpFailureView(tester, service: _UnavailableConnectivityService());

    expect(find.byKey(SystemFailureView.errorKey), findsOneWidget);
    expect(find.byKey(SystemFailureView.noInternetKey), findsNothing);
  });

  testWidgets('keeps the Figma anchors on a 375x812 viewport', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectivityServiceProvider.overrideWithValue(
            _FakeConnectivityService(false),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(body: SystemFailureView(onRetry: () {})),
        ),
      ),
    );
    await tester.pump();

    expect(
      tester.getSize(find.byKey(SystemMessageView.imageKey)),
      const Size(90, 80),
    );

    final button = tester.getRect(find.byKey(SystemFailureView.retryButtonKey));
    expect(button.width, 343);
    expect(button.height, 48);
    expect(button.bottom, 812 - 16);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the refresh action reports a retry', (tester) async {
    var retries = 0;
    await pumpFailureView(
      tester,
      service: _FakeConnectivityService(false),
      onRetry: () => retries++,
    );

    await tester.tap(find.byKey(SystemFailureView.retryButtonKey));
    expect(retries, 1);
  });
}
