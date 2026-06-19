import 'package:flutter_test/flutter_test.dart';
import 'package:placesecrets/domain/models/payment_receipt.dart';

void main() {
  group('PaymentReceipt.fromJson', () {
    test('parses a city receipt with all fields', () {
      final r = PaymentReceipt.fromJson({
        'id': 'rec-1',
        'user_id': 'u1',
        'city_id': 'c1',
        'item_type': 'city',
        'item_label': 'Prague — city access',
        'purchased_at': '2026-02-01T10:00:00Z',
        'payment_method': 'google_pay',
        'amount_eur': 4.99,
        'currency': 'EUR',
        'status': 'completed',
        'receipt_number': 'PS-2026-0001',
        'receipt_pdf_url': 'https://x/r.pdf',
        'created_at': '2026-02-01T10:00:00Z',
      });
      expect(r.itemType, 'city');
      expect(r.itemLabel, 'Prague — city access');
      expect(r.amountEur, 4.99);
      expect(r.receiptPdfUrl, 'https://x/r.pdf');
    });

    test('parses a POI receipt with null city_id (generalized schema)', () {
      final r = PaymentReceipt.fromJson({
        'id': 'rec-2',
        'user_id': 'u1',
        'city_id': null,
        'item_type': 'poi',
        'item_label': 'Premium place: Old Town',
        'purchased_at': '2026-02-02T10:00:00Z',
        'payment_method': 'comgate',
        'amount_eur': 1.99,
        'created_at': '2026-02-02T10:00:00Z',
      });
      expect(r.cityId, isNull);
      expect(r.itemType, 'poi');
      expect(r.itemLabel, 'Premium place: Old Town');
      expect(r.currency, 'EUR'); // default
    });
  });
}
