// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_receipt.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PaymentReceiptImpl _$$PaymentReceiptImplFromJson(Map<String, dynamic> json) =>
    _$PaymentReceiptImpl(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      cityId: json['city_id'] as String,
      purchasedAt: DateTime.parse(json['purchased_at'] as String),
      paymentMethod: json['payment_method'] as String,
      transactionId: json['transaction_id'] as String?,
      amountEur: (json['amount_eur'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'EUR',
      status: json['status'] as String? ?? 'completed',
      receiptNumber: json['receipt_number'] as String?,
      receiptPdfUrl: json['receipt_pdf_url'] as String?,
      receiptSentAt: json['receipt_sent_at'] == null
          ? null
          : DateTime.parse(json['receipt_sent_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$PaymentReceiptImplToJson(
        _$PaymentReceiptImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'city_id': instance.cityId,
      'purchased_at': instance.purchasedAt.toIso8601String(),
      'payment_method': instance.paymentMethod,
      'transaction_id': instance.transactionId,
      'amount_eur': instance.amountEur,
      'currency': instance.currency,
      'status': instance.status,
      'receipt_number': instance.receiptNumber,
      'receipt_pdf_url': instance.receiptPdfUrl,
      'receipt_sent_at': instance.receiptSentAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
    };
