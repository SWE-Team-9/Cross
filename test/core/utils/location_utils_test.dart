import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/core/utils/location_utils.dart';

void main() {
  group('LocationUtils.parse', () {
    const countries = ['Egypt', 'Germany', 'France'];

    test('returns empty city and country when location is null', () {
      final result = LocationUtils.parse(null, countries);

      expect(result.city, '');
      expect(result.country, '');
    });

    test('returns empty city and country when location is empty', () {
      final result = LocationUtils.parse('', countries);

      expect(result.city, '');
      expect(result.country, '');
    });

    test('parses city and country when both are present', () {
      final result = LocationUtils.parse('Cairo, Egypt', countries);

      expect(result.city, 'Cairo');
      expect(result.country, 'Egypt');
    });

    test('trims city and country when both are present', () {
      final result = LocationUtils.parse('  Cairo  ,  Egypt  ', countries);

      expect(result.city, 'Cairo');
      expect(result.country, 'Egypt');
    });

    test('treats a known country-only value as country', () {
      final result = LocationUtils.parse('Egypt', countries);

      expect(result.city, '');
      expect(result.country, 'Egypt');
    });

    test('treats unknown single value as city', () {
      final result = LocationUtils.parse('Cairo', countries);

      expect(result.city, 'Cairo');
      expect(result.country, '');
    });
  });

  group('LocationUtils.build', () {
    test('returns combined city and country when both are present', () {
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

    test('returns null when both are empty', () {
      final result = LocationUtils.build('', '');

      expect(result, isNull);
    });

    test('trims whitespace before building', () {
      final result = LocationUtils.build('  Cairo ', ' Egypt  ');

      expect(result, 'Cairo, Egypt');
    });
  });
}
