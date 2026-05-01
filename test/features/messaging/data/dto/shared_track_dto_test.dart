import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/messaging/data/dto/shared_track_dto.dart';

void main() {
  group('SharedTrackDto', () {
    test('fromJson reads primary fields', () {
      final dto = SharedTrackDto.fromJson(<String, dynamic>{
        'id': 'track-1',
        'title': 'First Track',
        'artist': 'Artist One',
        'artworkUrl': 'https://example.com/artwork.png',
      });

      expect(dto.id, 'track-1');
      expect(dto.title, 'First Track');
      expect(dto.artist, 'Artist One');
      expect(dto.artworkUrl, 'https://example.com/artwork.png');
    });

    test('fromJson reads trackId and artistName aliases', () {
      final dto = SharedTrackDto.fromJson(<String, dynamic>{
        'trackId': 'track-2',
        'title': 'Second Track',
        'artistName': 'Artist Two',
        'coverArtUrl': 'https://example.com/cover.png',
      });

      expect(dto.id, 'track-2');
      expect(dto.title, 'Second Track');
      expect(dto.artist, 'Artist Two');
      expect(dto.artworkUrl, 'https://example.com/cover.png');
    });

    test('fromJson reads snake_case aliases', () {
      final dto = SharedTrackDto.fromJson(<String, dynamic>{
        'track_id': 'track-3',
        'title': 'Third Track',
        'artist_name': 'Artist Three',
        'cover_art_url': 'https://example.com/cover-3.png',
      });

      expect(dto.id, 'track-3');
      expect(dto.title, 'Third Track');
      expect(dto.artist, 'Artist Three');
      expect(dto.artworkUrl, 'https://example.com/cover-3.png');
    });

    test('fromJson reads coverUrl and cover_url artwork aliases', () {
      final camel = SharedTrackDto.fromJson(<String, dynamic>{
        'id': 'track-4',
        'coverUrl': 'https://example.com/cover-4.png',
      });

      final snake = SharedTrackDto.fromJson(<String, dynamic>{
        'id': 'track-5',
        'cover_url': 'https://example.com/cover-5.png',
      });

      expect(camel.artworkUrl, 'https://example.com/cover-4.png');
      expect(snake.artworkUrl, 'https://example.com/cover-5.png');
    });

    test('fromJson uses safe defaults for missing values', () {
      final dto = SharedTrackDto.fromJson(<String, dynamic>{});

      expect(dto.id, '');
      expect(dto.title, '');
      expect(dto.artist, '');
      expect(dto.artworkUrl, isNull);
    });

    test('fromJson converts non-string values to strings', () {
      final dto = SharedTrackDto.fromJson(<String, dynamic>{
        'id': 1,
        'title': 2,
        'artist': 3,
        'artworkUrl': 4,
      });

      expect(dto.id, '1');
      expect(dto.title, '2');
      expect(dto.artist, '3');
      expect(dto.artworkUrl, '4');
    });

    test('toEntity maps all fields', () {
      const dto = SharedTrackDto(
        id: 'track-1',
        title: 'First Track',
        artist: 'Artist One',
        artworkUrl: 'https://example.com/artwork.png',
      );

      final entity = dto.toEntity();

      expect(entity.id, dto.id);
      expect(entity.title, dto.title);
      expect(entity.artist, dto.artist);
      expect(entity.artworkUrl, dto.artworkUrl);
    });
  });
}
