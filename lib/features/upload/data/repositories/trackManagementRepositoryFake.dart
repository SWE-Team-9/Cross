import '../../domain/entities/ManagedTrack.dart';
import '../../domain/entities/TrackManagementForm.dart';
import '../../domain/entities/TrackManagementVisibility.dart';
import '../../domain/repositories/trackManagementRepository.dart';

enum MockTrackManagementMode {
  success,
  alwaysFail,
  failOnce,
}

class TrackManagementRepositoryFake implements TrackManagementRepository {
  TrackManagementRepositoryFake({
    this.mode = MockTrackManagementMode.success,
  });

  final MockTrackManagementMode mode;

  final Map<String, ManagedTrack> _tracks = <String, ManagedTrack>{};
  bool _hasFailedOnce = false;

  @override
  Future<ManagedTrack> updateTrackMetadata({
    required String trackId,
    required TrackManagementForm form,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _maybeThrow();

    final ManagedTrack currentTrack = _resolveTrack(trackId);

    final ManagedTrack updatedTrack = currentTrack.copyWith(
      title: form.normalizedTitle,
      description: form.normalizedDescription,
      clearDescription: form.normalizedDescription == null,
      genreId: form.genreId,
      clearGenreId: form.genreId == null,
      genreName: form.genreName,
      clearGenreName: form.genreName == null,
      tags: form.sanitizedTags,
      visibility: form.visibility,
    );

    _tracks[trackId] = updatedTrack;

    return updatedTrack;
  }

  @override
  Future<ManagedTrack> updateTrackVisibility({
    required String trackId,
    required TrackManagementVisibility visibility,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _maybeThrow();

    final ManagedTrack updatedTrack = _resolveTrack(trackId).copyWith(
      visibility: visibility,
    );

    _tracks[trackId] = updatedTrack;

    return updatedTrack;
  }

  @override
  Future<void> deleteTrack({
    required String trackId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _maybeThrow();

    _tracks.remove(trackId);
  }

  ManagedTrack _resolveTrack(String trackId) {
    return _tracks[trackId] ??
        ManagedTrack(
          id: trackId,
          title: 'Demo Track',
          description: 'A local demo track used for Sprint 2 testing.',
          genreId: 1,
          genreName: 'Ambient',
          tags: const <String>['demo', 'local'],
          visibility: TrackManagementVisibility.publicTrack,
          durationInSeconds: 212,
        );
  }

  void _maybeThrow() {
    switch (mode) {
      case MockTrackManagementMode.success:
        return;
      case MockTrackManagementMode.alwaysFail:
        throw Exception('Mock track action failed. Please try again.');
      case MockTrackManagementMode.failOnce:
        if (!_hasFailedOnce) {
          _hasFailedOnce = true;
          throw Exception('Mock track action failed once. Please retry.');
        }
        return;
    }
  }
}
