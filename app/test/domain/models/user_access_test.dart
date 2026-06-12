import 'package:flutter_test/flutter_test.dart';
import 'package:herodots/domain/models/user_access.dart';

void main() {
  group('UserAccess.fromJson', () {
    test('parses all fields', () {
      final json = {
        'id': 'ua-1',
        'user_id': 'user-1',
        'city_id': 'city-1',
        'purchased_at': '2025-06-01T12:00:00.000Z',
        'valid_until': '2026-06-01T12:00:00.000Z',
        'payment_method': 'stripe',
        'transaction_id': 'tx-123',
        'amount_eur': 2.99,
      };
      final access = UserAccess.fromJson(json);
      expect(access.id, 'ua-1');
      expect(access.userId, 'user-1');
      expect(access.cityId, 'city-1');
      expect(access.purchasedAt, DateTime.utc(2025, 6, 1, 12, 0, 0));
      expect(access.validUntil, DateTime.utc(2026, 6, 1, 12, 0, 0));
      expect(access.paymentMethod, 'stripe');
      expect(access.transactionId, 'tx-123');
      expect(access.amountEur, 2.99);
    });

    test('nullable fields parse as null', () {
      final json = {
        'id': 'ua-2',
        'user_id': 'user-2',
        'city_id': 'city-2',
        'purchased_at': '2025-06-01T00:00:00.000Z',
        'payment_method': 'revolut',
      };
      final access = UserAccess.fromJson(json);
      expect(access.validUntil, null);
      expect(access.transactionId, null);
      expect(access.amountEur, null);
    });

    test('validUntil parses correctly', () {
      final json = {
        'id': 'ua-3',
        'user_id': 'user-3',
        'city_id': 'city-3',
        'purchased_at': '2020-01-01T00:00:00.000Z',
        'valid_until': '2020-06-01T00:00:00.000Z',
        'payment_method': 'stripe',
      };
      final access = UserAccess.fromJson(json);
      expect(access.validUntil, DateTime.utc(2020, 6, 1));
    });

    test('validUntil far future parses correctly', () {
      final json = {
        'id': 'ua-4',
        'user_id': 'user-4',
        'city_id': 'city-4',
        'purchased_at': '2025-01-01T00:00:00.000Z',
        'valid_until': '2099-01-01T00:00:00.000Z',
        'payment_method': 'google_pay',
      };
      final access = UserAccess.fromJson(json);
      expect(access.validUntil, DateTime.utc(2099, 1, 1));
    });
  });
}
