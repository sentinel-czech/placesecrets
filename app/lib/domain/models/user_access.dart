import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_access.freezed.dart';
part 'user_access.g.dart';

@freezed
class UserAccess with _$UserAccess {
  const factory UserAccess({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'city_id') required String cityId,
    @JsonKey(name: 'purchased_at') required DateTime purchasedAt,
    @JsonKey(name: 'valid_until') DateTime? validUntil,
    @JsonKey(name: 'payment_method') required String paymentMethod,
    @JsonKey(name: 'transaction_id') String? transactionId,
    @JsonKey(name: 'amount_eur') double? amountEur,
  }) = _UserAccess;

  factory UserAccess.fromJson(Map<String, dynamic> json) =>
      _$UserAccessFromJson(json);
}
