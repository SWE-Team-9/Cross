/// Utility functions for parsing and building the location string.
/// The API stores location as a single string (e.g. "Cairo, Egypt").
/// The UI splits it into City and Country fields.
abstract class LocationUtils {

  /// Parses "Cairo, Egypt" → {city: "Cairo", country: "Egypt"}
  /// Parses "Egypt"        → {city: "", country: "Egypt"} if in country list
  /// Parses "Cairo"        → {city: "Cairo", country: ""}
  static ({String city, String country}) parse(
    String? location,
    List<String> countryList,
  ) {
    if (location == null || location.isEmpty) {
      return (city: '', country: '');
    }

    final parts = location.split(',');
    if (parts.length >= 2) {
      return (
        city: parts[0].trim(),
        country: parts[1].trim(),
      );
    }

    final trimmed = location.trim();
    if (countryList.contains(trimmed)) {
      return (city: '', country: trimmed);
    }
    return (city: trimmed, country: '');
  }

  /// Builds "Cairo, Egypt" from city and country.
  /// Returns null if both are empty (so API doesn't receive empty string).
  static String? build(String city, String country) {
    final c = city.trim();
    final co = country.trim();
    if (c.isNotEmpty && co.isNotEmpty) return '$c, $co';
    if (c.isNotEmpty) return c;
    if (co.isNotEmpty) return co;
    return null;
  }
}