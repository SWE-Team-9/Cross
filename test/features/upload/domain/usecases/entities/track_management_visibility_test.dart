import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/track_management_visibility.dart';

void main() {
  group('TrackManagementVisibility', () {
    test('publicTrack maps correctly', () {
      expect(
        TrackManagementVisibility.publicTrack.apiValue,
        'PUBLIC',
      );
      expect(
        TrackManagementVisibility.publicTrack.displayLabel,
        'Public',
      );
    });

    test('privateTrack maps correctly', () {
      expect(
        TrackManagementVisibility.privateTrack.apiValue,
        'PRIVATE',
      );
      expect(
        TrackManagementVisibility.privateTrack.displayLabel,
        'Private',
      );
    });

    test('trackManagementVisibilityFromApiValue maps PUBLIC correctly', () {
      expect(
        trackManagementVisibilityFromApiValue('PUBLIC'),
        TrackManagementVisibility.publicTrack,
      );
    });

    test('trackManagementVisibilityFromApiValue maps PRIVATE correctly', () {
      expect(
        trackManagementVisibilityFromApiValue('PRIVATE'),
        TrackManagementVisibility.privateTrack,
      );
    });

    test('trackManagementVisibilityFromApiValue defaults to publicTrack', () {
      expect(
        trackManagementVisibilityFromApiValue(null),
        TrackManagementVisibility.publicTrack,
      );

      expect(
        trackManagementVisibilityFromApiValue('UNKNOWN'),
        TrackManagementVisibility.publicTrack,
      );
    });
  });
}
