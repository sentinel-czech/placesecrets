import 'package:flutter_test/flutter_test.dart';
import 'package:herodots/domain/models/city.dart';

void main() {
  group('City.fromJson', () {
    test('parses all fields including new slug fields', () {
      final json = {
        'id': 'city-1',
        'name': 'Prague',
        'country': 'Czech Republic',
        'country_code': 'CZ',
        'latitude': 50.08,
        'longitude': 14.42,
        'bounding_box_radius_km': 15.0,
        'price_eur': 2.99,
        'is_active': true,
        'slug': 'prague',
        'registered_sample_poi_id': 'poi-abc',
        'premium_bundle_price': 9.99,
      };
      final city = City.fromJson(json);
      expect(city.id, 'city-1');
      expect(city.name, 'Prague');
      expect(city.slug, 'prague');
      expect(city.registeredSamplePoiId, 'poi-abc');
      expect(city.premiumBundlePrice, 9.99);
      expect(city.priceEur, 2.99);
    });

    test('nullable fields default to null', () {
      final json = {
        'id': 'city-1',
        'name': 'Brno',
        'country': 'Czech Republic',
        'country_code': 'CZ',
        'latitude': 49.19,
        'longitude': 16.61,
      };
      final city = City.fromJson(json);
      expect(city.slug, null);
      expect(city.registeredSamplePoiId, null);
      expect(city.premiumBundlePrice, null);
    });

    test('default priceEur is 1.0', () {
      final json = {
        'id': 'city-1',
        'name': 'Plzen',
        'country': 'Czech Republic',
        'country_code': 'CZ',
        'latitude': 49.74,
        'longitude': 13.37,
      };
      final city = City.fromJson(json);
      expect(city.priceEur, 1.0);
    });

    test('default boundingBoxRadiusKm is 10.0', () {
      final json = {
        'id': 'city-1',
        'name': 'Ostrava',
        'country': 'Czech Republic',
        'country_code': 'CZ',
        'latitude': 49.82,
        'longitude': 18.16,
      };
      final city = City.fromJson(json);
      expect(city.boundingBoxRadiusKm, 10.0);
    });

    test('default isActive is true', () {
      final json = {
        'id': 'city-1',
        'name': 'Olomouc',
        'country': 'Czech Republic',
        'country_code': 'CZ',
        'latitude': 49.59,
        'longitude': 17.25,
      };
      final city = City.fromJson(json);
      expect(city.isActive, true);
    });
  });
}
