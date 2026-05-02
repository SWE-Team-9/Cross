import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/managed_track.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/track_management_visibility.dart';
import 'package:soundcloud_clone/features/upload/presentation/models/track_management_result.dart';

void main() {
  final track = ManagedTrack(
    id: 'track-1',
    title: 'Midnight Echoes',
    description: 'Demo track',
    genreId: 1,
    genreName: 'Ambient',
    tags: <String>['demo', 'ambient'],
    visibility: TrackManagementVisibility.publicTrack,
    durationInSeconds: 212,
  );

  group('TrackManagementResult', () {
    test('TrackUpdatedResult stores the updated track', () {
      final result = TrackUpdatedResult(track);

      expect(result.track.id, 'track-1');
      expect(result.track.title, 'Midnight Echoes');
      expect(result, isA<TrackManagementResult>());
      expect(result, isA<TrackUpdatedResult>());
    });

    test('TrackDeletedResult stores the deleted track id', () {
      final result = TrackDeletedResult('track-1');

      expect(result.trackId, 'track-1');
      expect(result, isA<TrackManagementResult>());
      expect(result, isA<TrackDeletedResult>());
    });
  });
}
