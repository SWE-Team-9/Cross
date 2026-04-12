import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/track_management_visibility.dart';

void main() {
  group('TrackManagementVisibility', () {
    test('creates visibility with valid value', () {
      final visibility = TrackManagementVisibility(isPublic: true);
      expect(visibility.isPublic, isTrue);
    });

    test('visibility can be private', () {
      final visibility = TrackManagementVisibility(isPublic: false);
      expect(visibility.isPublic, isFalse);
    });

    test('equality works for same values', () {
      final v1 = TrackManagementVisibility(isPublic: true);
      final v2 = TrackManagementVisibility(isPublic: true);
      expect(v1, v2);
    });

    test('inequality works for different values', () {
      final v1 = TrackManagementVisibility(isPublic: true);
      final v2 = TrackManagementVisibility(isPublic: false);
      expect(v1 != v2, isTrue);
    });
  });
}
