import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/core/utils/location_utils.dart';

void main() {
  group('LocationUtils.parse', () {
    const countries = <String>[
      'Egypt',
      'Saudi Arabia',
      'United States',
    ];

    test('returns empty city and country for null location', () {
      final result = LocationUtils.parse(null, countries);

      expect(result.city, '');
      expect(result.country, '');
    });

    test('returns empty city and country for empty location', () {
      final result = LocationUtils.parse('', countries);

      expect(result.city, '');
      expect(result.country, '');
    });

    test('parses city and country when both are present', () {
      final result = LocationUtils.parse('Cairo, Egypt', countries);

      expect(result.city, 'Cairo');
      expect(result.country, 'Egypt');
    });

    test('parses only country when value matches country list', () {
      final result = LocationUtils.parse('Egypt', countries);

      expect(result.city, '');
      expect(result.country, 'Egypt');
    });

    test('parses only city when value does not match country list', () {
      final result = LocationUtils.parse('Cairo', countries);

      expect(result.city, 'Cairo');
      expect(result.country, '');
    });

    test('trims spaces around city and country', () {
      final result = LocationUtils.parse('  Cairo  ,   Egypt  ', countries);

      expect(result.city, 'Cairo');
      expect(result.country, 'Egypt');
    });
  });

  group('LocationUtils.build', () {
    test('returns full location when city and country are present', () {
      final result = LocationUtils.build('Cairo', 'Egypt');

      expect(result, 'Cairo, Egypt');
    });

    test('returns city only when country is empty', () {
      final result = LocationUtils.build('Cairo', '');

      expect(result, 'Cairo');
    });

    test('returns country only when city is empty', () {
      final result = LocationUtils.build('', 'Egypt');

      expect(result, 'Egypt');
    });

    test('returns null when both city and country are empty', () {
      final result = LocationUtils.build('', '');

      expect(result, isNull);
    });

    test('trims spaces before building', () {
      final result = LocationUtils.build('  Cairo  ', '  Egypt  ');

      expect(result, 'Cairo, Egypt');
    });
  });
}
