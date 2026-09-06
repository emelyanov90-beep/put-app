import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/core/storage/local_json_store.dart';
import 'package:vput/features/auth/application/preview_session_controller.dart';
import 'package:vput/features/payment/domain/payment_method.dart';

/// Cards attached for the mock payments. They stay on the device: the backend
/// has no payment-provider integration to register them with.
class PaymentMethodsController extends AsyncNotifier<List<PaymentMethod>> {
  LocalJsonStore get _store => LocalJsonStore(
    'vput_payment_methods_${ref.read(currentLocalAccountIdProvider)}',
  );

  @override
  Future<List<PaymentMethod>> build() async {
    ref.watch(currentLocalAccountIdProvider);
    final rows = await _store.read();
    return rows
        .map(PaymentMethod.fromJson)
        .whereType<PaymentMethod>()
        .toList(growable: false);
  }

  Future<void> add({required String number, required String expiry}) async {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return;
    final current = state.value ?? const <PaymentMethod>[];
    final card = PaymentMethod(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      brand: paymentBrandFromNumber(digits),
      // Only the tail is persisted; the entered number is dropped here.
      last4: digits.substring(digits.length - 4),
      expiry: expiry.trim(),
      isDefault: current.isEmpty,
    );
    await _persist([...current, card]);
  }

  Future<void> remove(String id) async {
    final current = state.value ?? const <PaymentMethod>[];
    var next = current.where((card) => card.id != id).toList(growable: false);
    if (next.isNotEmpty && next.every((card) => !card.isDefault)) {
      next = [next.first.copyWith(isDefault: true), ...next.skip(1)];
    }
    await _persist(next);
  }

  Future<void> makeDefault(String id) async {
    final current = state.value ?? const <PaymentMethod>[];
    await _persist([
      for (final card in current) card.copyWith(isDefault: card.id == id),
    ]);
  }

  Future<void> _persist(List<PaymentMethod> cards) async {
    await _store.write([for (final card in cards) card.toJson()]);
    state = AsyncData(cards);
  }
}

final paymentMethodsProvider =
    AsyncNotifierProvider<PaymentMethodsController, List<PaymentMethod>>(
      PaymentMethodsController.new,
    );
