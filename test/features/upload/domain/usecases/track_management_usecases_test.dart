import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/upload/data/repositories/trackManagementRepositoryFake.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/TrackManagementForm.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/TrackManagementVisibility.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/deleteTrackUseCase.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/updateTrackMetadataUseCase.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/updateTrackVisibilityUseCase.dart';

void main() {
  group('Track Management UseCases', () {
    final repository = TrackManagementRepositoryFake(
      mode: MockTrackManagementMode.success,
    );

    final updateMetadataUseCase = UpdateTrackMetadataUseCase(repository);
    final updateVisibilityUseCase = UpdateTrackVisibilityUseCase(repository);
    final deleteTrackUseCase = DeleteTrackUseCase(repository);

    const form = TrackManagementForm(
      title: 'Updated Title',
      description: 'Updated Description',
      genreId: 2,
      genreName: 'Electronic',
      tags: <String>['edited'],
      visibility: TrackManagementVisibility.privateTrack,
    );

    test('UpdateTrackMetadataUseCase returns updated track', () async {
      final result = await updateMetadataUseCase(
        trackId: 'track-1',
        form: form,
      );

      expect(result.title, 'Updated Title');
      expect(result.genreId, 2);
    });

    test('UpdateTrackVisibilityUseCase returns updated track', () async {
      final result = await updateVisibilityUseCase(
        trackId: 'track-1',
        visibility: TrackManagementVisibility.privateTrack,
      );

      expect(result.visibility, TrackManagementVisibility.privateTrack);
    });

    test('DeleteTrackUseCase completes successfully', () async {
      await deleteTrackUseCase(trackId: 'track-1');
    });
  });
}
