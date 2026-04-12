import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/track_management_visibility.dart';

void main() {
  group('TrackManagementVisibility', () {
    test('publicTrack apiValue and displayLabel', () {
      final visibility = TrackManagementVisibility.publicTrack;

      expect(visibility.apiValue, 'PUBLIC');
      expect(visibility.displayLabel, 'Public');
    });

    test('privateTrack apiValue and displayLabel', () {
      final visibility = TrackManagementVisibility.privateTrack;

      expect(visibility.apiValue, 'PRIVATE');
      expect(visibility.displayLabel, 'Private');
    });

    test('fromApiValue returns publicTrack for PUBLIC', () {
      final result = trackManagementVisibilityFromApiValue('PUBLIC');
      expect(result, TrackManagementVisibility.publicTrack);
    });

    test('fromApiValue returns privateTrack for PRIVATE', () {
      final result = trackManagementVisibilityFromApiValue('PRIVATE');
      expect(result, TrackManagementVisibility.privateTrack);
    });

    test('fromApiValue defaults to publicTrack', () {
      final result = trackManagementVisibilityFromApiValue(null);
      expect(result, TrackManagementVisibility.publicTrack);
    });
  });
}
