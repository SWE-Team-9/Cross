import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/ManagedTrack.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/TrackManagementVisibility.dart';

void main() {
  const baseTrack = ManagedTrack(
    id: 'track-1',
    title: 'Midnight Echoes',
    description: 'Original description',
    genreId: 1,
    genreName: 'Ambient',
    tags: <String>['ambient', 'night'],
    visibility: TrackManagementVisibility.publicTrack,
    artworkUrl: 'https://example.com/art.png',
    durationInSeconds: 212,
    isDeleted: false,
  );

  group('ManagedTrack', () {
    test('supports value equality', () {
      const sameTrack = ManagedTrack(
        id: 'track-1',
        title: 'Midnight Echoes',
        description: 'Original description',
        genreId: 1,
        genreName: 'Ambient',
        tags: <String>['ambient', 'night'],
        visibility: TrackManagementVisibility.publicTrack,
        artworkUrl: 'https://example.com/art.png',
        durationInSeconds: 212,
        isDeleted: false,
      );

      expect(baseTrack, sameTrack);
      expect(baseTrack.props, sameTrack.props);
    });

    test('copyWith updates provided fields', () {
      final updated = baseTrack.copyWith(
        title: 'City Lights',
        visibility: TrackManagementVisibility.privateTrack,
        isDeleted: true,
      );

      expect(updated.id, 'track-1');
      expect(updated.title, 'City Lights');
      expect(updated.visibility, TrackManagementVisibility.privateTrack);
      expect(updated.isDeleted, isTrue);
      expect(updated.description, 'Original description');
    });

    test('copyWith clears nullable fields when clear flags are used', () {
      final updated = baseTrack.copyWith(
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

    test('copyWith replaces tags list', () {
      final updated = baseTrack.copyWith(
        tags: const <String>['electronic'],
      );

      expect(updated.tags, const <String>['electronic']);
    });

    test('copyWith preserves original values when nothing is passed', () {
      final updated = baseTrack.copyWith();

      expect(updated, baseTrack);
    });
  });
}
