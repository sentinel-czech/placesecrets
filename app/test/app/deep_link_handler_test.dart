import 'package:flutter_test/flutter_test.dart';
import 'package:placesecrets/app/deep_link_handler.dart';

void main() {
  group('DeepLinkHandler.resolveUri', () {
    test('placesecrets://purchase/success → PurchaseSuccessResult', () {
      final uri = Uri.parse('placesecrets://purchase/success');
      final result = DeepLinkHandler.resolveUri(uri);
      expect(result, isA<PurchaseSuccessResult>());
    });

    test('placesecrets://purchase/cancel → PurchaseCancelResult', () {
      final uri = Uri.parse('placesecrets://purchase/cancel');
      final result = DeepLinkHandler.resolveUri(uri);
      expect(result, isA<PurchaseCancelResult>());
    });

    test('https purchase/success → PurchaseSuccessResult', () {
      final uri =
          Uri.parse('https://placesecrets.app/purchase/success');
      final result = DeepLinkHandler.resolveUri(uri);
      expect(result, isA<PurchaseSuccessResult>());
    });

    test('https purchase/cancel → PurchaseCancelResult', () {
      final uri =
          Uri.parse('https://placesecrets.app/purchase/cancel');
      final result = DeepLinkHandler.resolveUri(uri);
      expect(result, isA<PurchaseCancelResult>());
    });

    test('https://placesecrets.app/cz/prague/bridge → PlaceResult', () {
      final uri =
          Uri.parse('https://placesecrets.app/cz/prague/charles-bridge');
      final result = DeepLinkHandler.resolveUri(uri);
      expect(result, isA<PlaceResult>());
      final place = result as PlaceResult;
      expect(place.countryCode, 'cz');
      expect(place.citySlug, 'prague');
      expect(place.poiSlug, 'charles-bridge');
    });

    test('unknown path → null', () {
      final uri = Uri.parse('placesecrets://unknown/path');
      expect(DeepLinkHandler.resolveUri(uri), isNull);
    });

    test('single segment path → null', () {
      final uri = Uri.parse('https://placesecrets.app/cz');
      expect(DeepLinkHandler.resolveUri(uri), isNull);
    });

    test('two segment path → null', () {
      final uri = Uri.parse('https://placesecrets.app/cz/prague');
      expect(DeepLinkHandler.resolveUri(uri), isNull);
    });

    test('first segment longer than 2 chars is not a country code → null', () {
      final uri = Uri.parse('https://placesecrets.app/admin/some/path');
      expect(DeepLinkHandler.resolveUri(uri), isNull);
    });

    test('purchase path with extra segments is not matched', () {
      final uri = Uri.parse('https://placesecrets.app/purchase/success/extra');
      // "purchase" is longer than 2 chars so not a country code, and
      // path /purchase/success/extra doesn't exactly match purchase patterns
      expect(DeepLinkHandler.resolveUri(uri), isNull);
    });

    test('extra path segments are ignored (first 3 used)', () {
      final uri = Uri.parse(
          'https://placesecrets.app/cz/prague/bridge/extra/stuff');
      final result = DeepLinkHandler.resolveUri(uri);
      expect(result, isA<PlaceResult>());
      final place = result as PlaceResult;
      expect(place.countryCode, 'cz');
      expect(place.citySlug, 'prague');
      expect(place.poiSlug, 'bridge');
    });

    test('empty URI → null', () {
      final uri = Uri.parse('');
      expect(DeepLinkHandler.resolveUri(uri), isNull);
    });
  });
}
