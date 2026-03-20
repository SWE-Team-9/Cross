import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/ManagedTrack.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/TrackManagementVisibility.dart';

void main() {
  group('ManagedTrack', () {
    const track = ManagedTrack(
      id: 'track-1',
      title: 'Demo Track',
      description: 'Description',
      genreId: 1,
      genreName: 'Ambient',
      tags: <String>['demo', 'local'],
      visibility: TrackManagementVisibility.publicTrack,
      artworkUrl: 'https://example.com/art.jpg',
      durationInSeconds: 120,
    );

    test('supports value equality', () {
      const second = ManagedTrack(
        id: 'track-1',
        title: 'Demo Track',
        description: 'Description',
        genreId: 1,
        genreName: 'Ambient',
        tags: <String>['demo', 'local'],
        visibility: TrackManagementVisibility.publicTrack,
        artworkUrl: 'https://example.com/art.jpg',
        durationInSeconds: 120,
      );

      expect(track, second);
    });

    test('copyWith updates provided fields', () {
      final updated = track.copyWith(
        title: 'Updated Track',
        visibility: TrackManagementVisibility.privateTrack,
        tags: const <String>['edited'],
      );

      expect(updated.title, 'Updated Track');
      expect(updated.visibility, TrackManagementVisibility.privateTrack);
      expect(updated.tags, const <String>['edited']);
      expect(updated.description, 'Description');
    });

    test('copyWith clears nullable fields when requested', () {
      final updated = track.copyWith(
        clearDescription: true,
        clearGenreId: true,
        clearGenreName: true,
        clearArtworkUrl: true,
        clearDurationInSeconds: true,
      );

      expect(updated.description, isNull);
      expect(updated.genreId, isNull);
      expect(updated.genreName, isNull);
      expect(updated.artworkUrl, isNull);
      expect(updated.durationInSeconds, isNull);
    });
  });
}
