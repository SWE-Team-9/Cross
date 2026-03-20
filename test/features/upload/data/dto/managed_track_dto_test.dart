import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/upload/data/dto/ManagedTrackDto.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/TrackManagementVisibility.dart';

void main() {
  group('ManagedTrackDto', () {
    test('fromJson parses flat fields', () {
      final dto = ManagedTrackDto.fromJson(
        <String, dynamic>{
          'id': 'track-1',
          'title': 'Track Title',
          'description': 'Track Description',
          'genreId': 3,
          'genreName': 'Hip-Hop',
          'tags': <String>['demo', 'mix'],
          'visibility': 'PRIVATE',
          'artworkUrl': 'https://example.com/art.jpg',
          'durationInSeconds': 220,
        },
      );

      expect(dto.id, 'track-1');
      expect(dto.title, 'Track Title');
      expect(dto.description, 'Track Description');
      expect(dto.genreId, 3);
      expect(dto.genreName, 'Hip-Hop');
      expect(dto.tags, const <String>['demo', 'mix']);
      expect(dto.visibility, TrackManagementVisibility.privateTrack);
      expect(dto.artworkUrl, 'https://example.com/art.jpg');
      expect(dto.durationInSeconds, 220);
    });

    test('fromJson parses nested genre and tag maps', () {
      final dto = ManagedTrackDto.fromJson(
        <String, dynamic>{
          'id': 'track-2',
          'title': 'Track',
          'genre': <String, dynamic>{
            'id': 2,
            'name': 'Electronic',
          },
          'tags': <dynamic>[
            <String, dynamic>{'name': 'demo'},
            <String, dynamic>{
              'tag': <String, dynamic>{'name': 'nested'},
            },
          ],
          'visibility': 'PUBLIC',
        },
      );

      expect(dto.genreId, 2);
      expect(dto.genreName, 'Electronic');
      expect(dto.tags, const <String>['demo', 'nested']);
      expect(dto.visibility, TrackManagementVisibility.publicTrack);
    });

    test('toEntity maps dto to domain entity', () {
      const dto = ManagedTrackDto(
        id: 'track-3',
        title: 'Track',
        description: 'Desc',
        genreId: 1,
        genreName: 'Ambient',
        tags: <String>['demo'],
        visibility: TrackManagementVisibility.publicTrack,
        artworkUrl: 'https://example.com/art.jpg',
        durationInSeconds: 180,
      );

      final entity = dto.toEntity();

      expect(entity.id, 'track-3');
      expect(entity.title, 'Track');
      expect(entity.description, 'Desc');
      expect(entity.genreId, 1);
      expect(entity.genreName, 'Ambient');
      expect(entity.tags, const <String>['demo']);
      expect(entity.visibility, TrackManagementVisibility.publicTrack);
      expect(entity.artworkUrl, 'https://example.com/art.jpg');
      expect(entity.durationInSeconds, 180);
      expect(entity.isDeleted, isFalse);
    });
  });
}
