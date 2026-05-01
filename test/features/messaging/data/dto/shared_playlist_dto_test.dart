import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/messaging/data/dto/shared_playlist_dto.dart';

void main() {
  group('SharedPlaylistDto', () {
    test('fromJson reads primary fields', () {
      final dto = SharedPlaylistDto.fromJson(<String, dynamic>{
        'id': 'playlist-1',
        'title': 'First Playlist',
        'tracksCount': 12,
        'artworkUrl': 'https://example.com/artwork.png',
      });

      expect(dto.id, 'playlist-1');
      expect(dto.title, 'First Playlist');
      expect(dto.tracksCount, 12);
      expect(dto.artworkUrl, 'https://example.com/artwork.png');
    });

    test('fromJson reads playlistId and coverArtUrl aliases', () {
      final dto = SharedPlaylistDto.fromJson(<String, dynamic>{
        'playlistId': 'playlist-2',
        'title': 'Second Playlist',
        'count': '8',
        'coverArtUrl': 'https://example.com/cover.png',
      });

      expect(dto.id, 'playlist-2');
      expect(dto.title, 'Second Playlist');
      expect(dto.tracksCount, 8);
      expect(dto.artworkUrl, 'https://example.com/cover.png');
    });

    test('fromJson reads snake_case aliases', () {
      final dto = SharedPlaylistDto.fromJson(<String, dynamic>{
        'playlist_id': 'playlist-3',
        'title': 'Third Playlist',
        'tracks_count': 4.6,
        'cover_art_url': 'https://example.com/cover-3.png',
      });

      expect(dto.id, 'playlist-3');
      expect(dto.title, 'Third Playlist');
      expect(dto.tracksCount, 5);
      expect(dto.artworkUrl, 'https://example.com/cover-3.png');
    });

    test('fromJson reads coverUrl and cover_url aliases', () {
      final camel = SharedPlaylistDto.fromJson(<String, dynamic>{
        'id': 'playlist-4',
        'coverUrl': 'https://example.com/cover-4.png',
      });

      final snake = SharedPlaylistDto.fromJson(<String, dynamic>{
        'id': 'playlist-5',
        'cover_url': 'https://example.com/cover-5.png',
      });

      expect(camel.artworkUrl, 'https://example.com/cover-4.png');
      expect(snake.artworkUrl, 'https://example.com/cover-5.png');
    });

    test('fromJson uses safe defaults for missing and invalid count values',
        () {
      final dto = SharedPlaylistDto.fromJson(<String, dynamic>{
        'tracksCount': 'not-a-number',
      });

      expect(dto.id, '');
      expect(dto.title, '');
      expect(dto.tracksCount, 0);
      expect(dto.artworkUrl, isNull);
    });

    test('fromJson converts non-string values to strings', () {
      final dto = SharedPlaylistDto.fromJson(<String, dynamic>{
        'id': 1,
        'title': 2,
        'artworkUrl': 3,
      });

      expect(dto.id, '1');
      expect(dto.title, '2');
      expect(dto.artworkUrl, '3');
    });

    test('toEntity maps all fields', () {
      const dto = SharedPlaylistDto(
        id: 'playlist-1',
        title: 'First Playlist',
        tracksCount: 12,
        artworkUrl: 'https://example.com/artwork.png',
      );

      final entity = dto.toEntity();

      expect(entity.id, dto.id);
      expect(entity.title, dto.title);
      expect(entity.tracksCount, dto.tracksCount);
      expect(entity.artworkUrl, dto.artworkUrl);
    });
  });
}
