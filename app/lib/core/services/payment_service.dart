import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:pay/pay.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/models/payment_config.dart';

enum PaymentMethod { googlePay, applePay, revolut }

class PaymentResult {
  final bool success;

  /// Payment was initiated but not yet confirmed (e.g. Revolut, where the grant
  /// arrives later via webhook). Not a success and not an error — the UI should
  /// tell the user access unlocks once the payment is confirmed.
  final bool pending;
  final String? transactionId;
  final String? error;

  const PaymentResult({
    required this.success,
    this.pending = false,
    this.transactionId,
    this.error,
  });
}

class PaymentService {
  final SupabaseClient _supabase;

  PaymentService(this._supabase);

  Future<PaymentResult> pay({
    required String cityId,
    required double amountEur,
    required String cityName,
    required PaymentMethod method,
    required PaymentConfig config,
  }) async {
    switch (method) {
      case PaymentMethod.googlePay:
        return _payWithGooglePay(cityId, amountEur, cityName, config);
      case PaymentMethod.applePay:
        return _payWithApplePay(cityId, amountEur, cityName, config);
      case PaymentMethod.revolut:
        return _payWithRevolut(cityId, amountEur, cityName, config);
    }
  }

  Future<PaymentResult> _payWithGooglePay(
    String cityId,
    double amountEur,
    String cityName,
    PaymentConfig config,
  ) async {
    if (!Platform.isAndroid) {
      return const PaymentResult(
          success: false, error: 'Google Pay is only available on Android');
    }

    try {
      final paymentItems = [
        PaymentItem(
          label: 'PlaceSecrets: $cityName',
          amount: amountEur.toStringAsFixed(2),
          status: PaymentItemStatus.final_price,
        ),
      ];

      final googlePayConfig = PaymentConfiguration.fromJsonString(
        jsonEncode({
          'provider': 'google_pay',
          'data': {
            'environment': 'PRODUCTION',
            'apiVersion': 2,
            'apiVersionMinor': 0,
            'allowedPaymentMethods': [
              {
                'type': 'CARD',
                'parameters': {
                  'allowedAuthMethods': ['PAN_ONLY', 'CRYPTOGRAM_3DS'],
                  'allowedCardNetworks': ['VISA', 'MASTERCARD'],
                },
                'tokenizationSpecification': {
                  'type': 'PAYMENT_GATEWAY',
                  'parameters': {
                    'gateway': 'stripe',
                    'stripe:publishableKey':
                        config.stripePublishableKey ?? '',
                  },
                },
              },
            ],
            'merchantInfo': {
              'merchantId': config.googlePayMerchantId ?? '',
              'merchantName': config.operatorName,
            },
            'transactionInfo': {
              'totalPriceStatus': 'FINAL',
              'totalPrice': amountEur.toStringAsFixed(2),
              'currencyCode': 'EUR',
              'countryCode': 'CZ',
            },
          },
        }),
      );

      final payClient = Pay({PayProvider.google_pay: googlePayConfig});
      final result = await payClient.showPaymentSelector(
        PayProvider.google_pay,
        paymentItems,
      );

      return _confirmPayment(
        cityId: cityId,
        amountEur: amountEur,
        method: 'google_pay',
        transactionData: result,
      );
    } catch (e) {
      debugPrint('Google Pay error: $e');
      return PaymentResult(success: false, error: e.toString());
    }
  }

  Future<PaymentResult> _payWithApplePay(
    String cityId,
    double amountEur,
    String cityName,
    PaymentConfig config,
  ) async {
    if (!Platform.isIOS) {
      return const PaymentResult(
          success: false, error: 'Apple Pay is only available on iOS');
    }

    try {
      final paymentItems = [
        PaymentItem(
          label: 'PlaceSecrets: $cityName',
          amount: amountEur.toStringAsFixed(2),
          status: PaymentItemStatus.final_price,
        ),
      ];

      final applePayConfig = PaymentConfiguration.fromJsonString(
        jsonEncode({
          'provider': 'apple_pay',
          'data': {
            'merchantIdentifier': config.applePayMerchantId ?? '',
            'displayName': config.operatorName,
            'merchantCapabilities': ['3DS', 'debit', 'credit'],
            'supportedNetworks': ['visa', 'masterCard'],
            'countryCode': 'CZ',
            'currencyCode': 'EUR',
          },
        }),
      );

      final payClient = Pay({PayProvider.apple_pay: applePayConfig});
      final result = await payClient.showPaymentSelector(
        PayProvider.apple_pay,
        paymentItems,
      );

      return _confirmPayment(
        cityId: cityId,
        amountEur: amountEur,
        method: 'apple_pay',
        transactionData: result,
      );
    } catch (e) {
      debugPrint('Apple Pay error: $e');
      return PaymentResult(success: false, error: e.toString());
    }
  }

  Future<PaymentResult> _payWithRevolut(
    String cityId,
    double amountEur,
    String cityName,
    PaymentConfig config,
  ) async {
    final username = config.revolutUsername;
    if (username == null || username.isEmpty) {
      return const PaymentResult(
          success: false, error: 'Revolut payments not configured');
    }

    final amount = amountEur.toStringAsFixed(2);
    final uri = Uri.parse('https://revolut.me/$username/$amount/EUR');

    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        return const PaymentResult(
            success: false, error: 'Could not open Revolut');
      }

      // Revolut grant is confirmed server-side via webhook, so this is PENDING,
      // not a success — the user is told access unlocks once payment confirms.
      final response =
          await _supabase.functions.invoke('create-payment-intent', body: {
        'city_id': cityId,
        'amount_eur': amountEur,
        'payment_method': 'revolut',
      });

      final data = response.data as Map<String, dynamic>?;
      return PaymentResult(
        success: false,
        pending: true,
        transactionId: data?['payment_id'] as String?,
      );
    } catch (e) {
      debugPrint('Revolut error: $e');
      return PaymentResult(success: false, error: e.toString());
    }
  }

  Future<PaymentResult> _confirmPayment({
    required String cityId,
    required double amountEur,
    required String method,
    required Map<String, dynamic> transactionData,
  }) async {
    try {
      final response =
          await _supabase.functions.invoke('confirm-payment', body: {
        'city_id': cityId,
        'amount_eur': amountEur,
        'payment_method': method,
        'transaction_data': transactionData,
      });

      final data = response.data as Map<String, dynamic>?;
      if (data?['success'] == true) {
        return PaymentResult(
          success: true,
          transactionId: data?['transaction_id'] as String?,
        );
      }
      return PaymentResult(
        success: false,
        error: data?['error'] as String? ?? 'Payment confirmation failed',
      );
    } catch (e) {
      return PaymentResult(success: false, error: e.toString());
    }
  }

  List<PaymentMethod> get availableMethods {
    final methods = <PaymentMethod>[];
    if (Platform.isAndroid) methods.add(PaymentMethod.googlePay);
    if (Platform.isIOS) methods.add(PaymentMethod.applePay);
    methods.add(PaymentMethod.revolut);
    return methods;
  }
}
