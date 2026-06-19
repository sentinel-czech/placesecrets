import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_receipt.freezed.dart';
part 'payment_receipt.g.dart';

@freezed
class PaymentReceipt with _$PaymentReceipt {
  const factory PaymentReceipt({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'city_id') String? cityId,
    @JsonKey(name: 'item_type') String? itemType,
    @JsonKey(name: 'item_label') String? itemLabel,
    @JsonKey(name: 'purchased_at') required DateTime purchasedAt,
    @JsonKey(name: 'payment_method') required String paymentMethod,
    @JsonKey(name: 'transaction_id') String? transactionId,
    @JsonKey(name: 'amount_eur') required double amountEur,
    @Default('EUR') String currency,
    @Default('completed') String status,
    @JsonKey(name: 'receipt_number') String? receiptNumber,
    @JsonKey(name: 'receipt_pdf_url') String? receiptPdfUrl,
    @JsonKey(name: 'receipt_sent_at') DateTime? receiptSentAt,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _PaymentReceipt;

  factory PaymentReceipt.fromJson(Map<String, dynamic> json) =>
      _$PaymentReceiptFromJson(json);
}
