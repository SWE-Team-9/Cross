import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/ManagedTrack.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/TrackManagementVisibility.dart';
import 'package:soundcloud_clone/features/upload/presentation/models/applyTrackManagementResult.dart';
import 'package:soundcloud_clone/features/upload/presentation/models/trackManagementResult.dart';

void main() {
  group('applyTrackManagementResult', () {
    const trackOne = ManagedTrack(
      id: 'track-1',
      title: 'First Track',
      visibility: TrackManagementVisibility.publicTrack,
      genreId: 1,
      genreName: 'Ambient',
      tags: <String>['first'],
    );

    const trackTwo = ManagedTrack(
      id: 'track-2',
      title: 'Second Track',
      visibility: TrackManagementVisibility.privateTrack,
      genreId: 2,
      genreName: 'Electronic',
      tags: <String>['second'],
    );

    test('replaces the matching track for TrackUpdatedResult', () {
      const updatedTrackOne = ManagedTrack(
        id: 'track-1',
        title: 'First Track Updated',
        visibility: TrackManagementVisibility.privateTrack,
        genreId: 3,
        genreName: 'Hip-Hop',
        tags: <String>['updated'],
      );

      final result = applyTrackManagementResult(
        tracks: const [trackOne, trackTwo],
        result: const TrackUpdatedResult(updatedTrackOne),
      );

      expect(result.length, 2);
      expect(result[0], updatedTrackOne);
      expect(result[1], trackTwo);
    });

    test('removes the matching track for TrackDeletedResult', () {
      final result = applyTrackManagementResult(
        tracks: const [trackOne, trackTwo],
        result: const TrackDeletedResult('track-1'),
      );

      expect(result.length, 1);
      expect(result.first, trackTwo);
    });
  });
}
