import 'package:flutter/foundation.dart';

enum PaymentCardBrand { visa, mastercard, mir, unknown }

/// A card the user attached for the mock payments.
///
/// Only the last four digits and the expiry are kept. The application never
/// stores a full card number: payments are a mock server action (TZ 2), and no
/// payment provider is integrated, so a PAN would be stored for nothing.
@immutable
class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.brand,
    required this.last4,
    required this.expiry,
    required this.isDefault,
  });

  final String id;
  final PaymentCardBrand brand;
  final String last4;
  final String expiry;
  final bool isDefault;

  String get maskedNumber => '•••• •••• •••• $last4';

  String get brandLabel => switch (brand) {
    PaymentCardBrand.visa => 'Visa',
    PaymentCardBrand.mastercard => 'Mastercard',
    PaymentCardBrand.mir => 'МИР',
    PaymentCardBrand.unknown => 'Карта',
  };

  PaymentMethod copyWith({bool? isDefault}) => PaymentMethod(
    id: id,
    brand: brand,
    last4: last4,
    expiry: expiry,
    isDefault: isDefault ?? this.isDefault,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'brand': brand.name,
    'last4': last4,
    'expiry': expiry,
    'is_default': isDefault,
  };

  static PaymentMethod? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final last4 = json['last4'];
    final expiry = json['expiry'];
    if (id is! String || last4 is! String || expiry is! String) return null;
    if (last4.length != 4) return null;
    return PaymentMethod(
      id: id,
      brand: PaymentCardBrand.values.firstWhere(
        (value) => value.name == json['brand'],
        orElse: () => PaymentCardBrand.unknown,
      ),
      last4: last4,
      expiry: expiry,
      isDefault: json['is_default'] == true,
    );
  }
}

/// Recognises the brand from the leading digits, the way a payment form does.
PaymentCardBrand paymentBrandFromNumber(String digits) {
  if (digits.startsWith('4')) return PaymentCardBrand.visa;
  if (digits.startsWith('2')) return PaymentCardBrand.mir;
  if (digits.startsWith('5')) return PaymentCardBrand.mastercard;
  return PaymentCardBrand.unknown;
}
