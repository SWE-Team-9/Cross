import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/upload/data/repositories/track_management_repository_fake.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/track_management_form.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/track_management_visibility.dart';

void main() {
  group('TrackManagementRepositoryFake', () {
    const form = TrackManagementForm(
      title: 'Edited Title',
      description: 'Edited Description',
      genreId: 2,
      genreName: 'Electronic',
      tags: <String>['edited', 'demo'],
      visibility: TrackManagementVisibility.privateTrack,
    );

    test('updateTrackMetadata succeeds in success mode', () async {
      final repository = TrackManagementRepositoryFake(
        mode: MockTrackManagementMode.success,
      );

      final track = await repository.updateTrackMetadata(
        trackId: 'track-1',
        form: form,
      );

      expect(track.title, 'Edited Title');
      expect(track.description, 'Edited Description');
      expect(track.genreId, 2);
      expect(track.genreName, 'Electronic');
      expect(track.tags, const <String>['edited', 'demo']);
      expect(track.visibility, TrackManagementVisibility.privateTrack);
    });

    test('updateTrackVisibility succeeds in success mode', () async {
      final repository = TrackManagementRepositoryFake(
        mode: MockTrackManagementMode.success,
      );

      final track = await repository.updateTrackVisibility(
        trackId: 'track-1',
        visibility: TrackManagementVisibility.privateTrack,
      );

      expect(track.visibility, TrackManagementVisibility.privateTrack);
    });

    test('deleteTrack succeeds in success mode', () async {
      final repository = TrackManagementRepositoryFake(
        mode: MockTrackManagementMode.success,
      );

      await repository.deleteTrack(trackId: 'track-1');
    });

    test('alwaysFail mode throws exception', () async {
      final repository = TrackManagementRepositoryFake(
        mode: MockTrackManagementMode.alwaysFail,
      );

      expect(
        () => repository.updateTrackMetadata(
          trackId: 'track-1',
          form: form,
        ),
        throwsA(
          isA<Exception>().having(
            (exception) => exception.toString(),
            'message',
            contains('Mock track action failed'),
          ),
        ),
      );
    });

    test('failOnce mode fails first then succeeds', () async {
      final repository = TrackManagementRepositoryFake(
        mode: MockTrackManagementMode.failOnce,
      );

      expect(
        () => repository.updateTrackVisibility(
          trackId: 'track-1',
          visibility: TrackManagementVisibility.privateTrack,
        ),
        throwsA(
          isA<Exception>().having(
            (exception) => exception.toString(),
            'message',
            contains('Mock track action failed once'),
          ),
        ),
      );

      final track = await repository.updateTrackVisibility(
        trackId: 'track-1',
        visibility: TrackManagementVisibility.privateTrack,
      );

      expect(track.visibility, TrackManagementVisibility.privateTrack);
    });
  });
}
