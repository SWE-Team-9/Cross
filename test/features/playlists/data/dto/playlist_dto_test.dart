import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/playlists/data/dto/playlist_dto.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';

void main() {
  group('PlaylistDto.fromJson', () {
    test('parses playlist aliases from camelCase and snake_case fields', () {
      final dto = PlaylistDto.fromJson(
        <String, dynamic>{
          'id': 'pl_alias',
          'title': 'Alias Playlist',
          'description': 'desc',
          'visibility': 'PRIVATE',
          'genre_id': '2',
          'slug': 'alias-playlist',
          'type': 'ALBUM',
          'release_date': '2026-04-01',
          'tags': <dynamic>['focus', ' coding ', ''],
          'secret_token': 'secret_123',
          'cover_image_url': 'https://cdn.example/cover.jpg',
          'tracks_count': '4',
          'likes_count': '17',
          'is_liked': 'true',
          'owner': <String, dynamic>{
            'userId': 'owner_1',
            'display_name': 'Ahmed Hassan',
          },
        },
      );

      expect(dto.playlistId, 'pl_alias');
      expect(dto.title, 'Alias Playlist');
      expect(dto.visibility, PlaylistVisibility.privatePlaylist);
      expect(dto.genreId, 2);
      expect(dto.slug, 'alias-playlist');
      expect(dto.playlistType, 'ALBUM');
      expect(dto.releaseDate, DateTime(2026, 4));
      expect(dto.tags, <String>['focus', 'coding']);
      expect(dto.secretToken, 'secret_123');
      expect(dto.coverImageUrl, 'https://cdn.example/cover.jpg');
      expect(dto.tracksCount, 4);
      expect(dto.likesCount, 17);
      expect(dto.isLiked, isTrue);
      expect(dto.owner?.id, 'owner_1');
      expect(dto.owner?.displayName, 'Ahmed Hassan');
    });

    test('parses genre object and viewer liked state', () {
      final dto = PlaylistDto.fromJson(
        <String, dynamic>{
          'playlistId': 'pl_genre',
          'title': 'Genre Playlist',
          'visibility': 'PUBLIC',
          'genre': <String, dynamic>{
            'id': 12,
            'slug': 'electronic',
            'name': 'Electronic',
          },
          'viewer': <String, dynamic>{
            'liked': 1,
          },
        },
      );

      expect(dto.playlistId, 'pl_genre');
      expect(dto.genreId, 12);
      expect(dto.genre, 'electronic');
      expect(dto.isLiked, isTrue);
    });

    test('parses user_state liked fallback', () {
      final dto = PlaylistDto.fromJson(
        <String, dynamic>{
          'playlistId': 'pl_user_state',
          'title': 'User State Playlist',
          'visibility': 'PUBLIC',
          'user_state': <String, dynamic>{
            'liked': 'yes',
          },
        },
      );

      expect(dto.isLiked, isTrue);
    });

    test('parses rich track aliases from documented playlist details', () {
      final dto = PlaylistDto.fromJson(
        <String, dynamic>{
          'playlistId': 'pl_tracks',
          'title': 'Track Playlist',
          'visibility': 'PUBLIC',
          'tracks': <dynamic>[
            <String, dynamic>{
              'trackId': 'trk_1',
              'title': 'Layali',
              'artist': <String, dynamic>{
                'id': 'artist_1',
                'display_name': 'Ahmed Hassan',
                'handle': 'ahmedhassan',
              },
              'coverArtUrl': 'https://cdn.example/trk_1.jpg',
              'durationMs': '180000',
              'likes_count': '10',
              'repostsCount': 2,
            },
          ],
        },
      );

      expect(dto.tracks, hasLength(1));

      final track = dto.tracks.single;
      expect(track.id, 'trk_1');
      expect(track.title, 'Layali');
      expect(track.artist, 'Ahmed Hassan');
      expect(track.artistId, 'artist_1');
      expect(track.artworkUrl, 'https://cdn.example/trk_1.jpg');
      expect(track.durationMs, 180000);
      expect(track.likesCount, 10);
      expect(track.repostsCount, 2);
    });

    test('parses tracks from nested data.tracks fallback', () {
      final dto = PlaylistDto.fromJson(
        <String, dynamic>{
          'playlistId': 'pl_nested_tracks',
          'title': 'Nested Tracks',
          'visibility': 'PUBLIC',
          'data': <String, dynamic>{
            'tracks': <dynamic>[
              <String, dynamic>{
                '_id': 'trk_nested',
                'title': 'Nested Track',
                'uploader': <String, dynamic>{
                  'id': 'uploader_1',
                  'displayName': 'Uploader One',
                  'username': 'uploaderone',
                },
                'artwork_url': 'https://cdn.example/nested.jpg',
              },
            ],
          },
        },
      );

      expect(dto.tracks, hasLength(1));
      expect(dto.tracks.single.id, 'trk_nested');
      expect(dto.tracks.single.artist, 'Uploader One');
      expect(dto.tracks.single.artistId, 'uploader_1');
      expect(dto.tracks.single.handle, 'uploaderone');
      expect(dto.tracks.single.artworkUrl, 'https://cdn.example/nested.jpg');
      expect(dto.tracksCount, 1);
    });

    test('ignores invalid track objects without ids', () {
      final dto = PlaylistDto.fromJson(
        <String, dynamic>{
          'playlistId': 'pl_invalid_tracks',
          'title': 'Invalid Tracks',
          'visibility': 'PUBLIC',
          'tracks': <dynamic>[
            <String, dynamic>{
              'title': 'No ID',
            },
            <String, dynamic>{
              'id': 'trk_valid',
              'title': 'Valid Track',
            },
          ],
        },
      );

      expect(dto.tracks, hasLength(1));
      expect(dto.tracks.single.id, 'trk_valid');
    });

    test('maps unknown or missing visibility to public playlist', () {
      final dto = PlaylistDto.fromJson(
        <String, dynamic>{
          'playlistId': 'pl_visibility',
          'title': 'Visibility Playlist',
          'visibility': 'UNKNOWN',
        },
      );

      expect(dto.visibility, PlaylistVisibility.publicPlaylist);
    });
  });
}
