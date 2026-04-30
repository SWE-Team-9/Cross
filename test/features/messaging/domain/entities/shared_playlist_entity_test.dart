import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/shared_playlist_entity.dart';

void main() {
  group('SharedPlaylistEntity', () {
    test('stores all provided values', () {
      const entity = SharedPlaylistEntity(
        id: 'playlist-1',
        title: 'Playlist One',
        tracksCount: 12,
        artworkUrl: 'https://example.com/artwork.png',
      );

      expect(entity.id, 'playlist-1');
      expect(entity.title, 'Playlist One');
      expect(entity.tracksCount, 12);
      expect(entity.artworkUrl, 'https://example.com/artwork.png');
    });

    test('allows null artworkUrl', () {
      const entity = SharedPlaylistEntity(
        id: 'playlist-1',
        title: 'Playlist One',
        tracksCount: 12,
        artworkUrl: null,
      );

      expect(entity.artworkUrl, isNull);
    });
  });
}
