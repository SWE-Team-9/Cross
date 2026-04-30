import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/shared_track_entity.dart';

void main() {
  group('SharedTrackEntity', () {
    test('stores all provided values', () {
      const entity = SharedTrackEntity(
        id: 'track-1',
        title: 'Track One',
        artist: 'Artist One',
        artworkUrl: 'https://example.com/artwork.png',
      );

      expect(entity.id, 'track-1');
      expect(entity.title, 'Track One');
      expect(entity.artist, 'Artist One');
      expect(entity.artworkUrl, 'https://example.com/artwork.png');
    });

    test('allows null artworkUrl', () {
      const entity = SharedTrackEntity(
        id: 'track-1',
        title: 'Track One',
        artist: 'Artist One',
        artworkUrl: null,
      );

      expect(entity.artworkUrl, isNull);
    });
  });
}
