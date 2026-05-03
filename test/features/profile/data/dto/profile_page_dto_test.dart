import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/profile/data/dto/profile_page_dto.dart';

void main() {
  group('ProfilePageDto.fromJson', () {
    test(
      'parses other-user nested payload playlists and liked playlists',
      () {
        final json = <String, dynamic>{
          'data': <String, dynamic>{
            'meta': <String, dynamic>{'source': 'profile_page'},
            'profile': <String, dynamic>{
              'id': 'user-77',
              'handle': 'artist77',
              'display_name': 'Artist 77',
              'account_type': 'ARTIST',
              'favorite_genres': <String>['electronic'],
              'social_links': <String, dynamic>{},
              'visibility': 'PUBLIC',
              'track_count': 2,
            },
            'sections': <String, dynamic>{
              'created': <String, dynamic>{
                'userPlaylists': <String, dynamic>{
                  'items': <Map<String, dynamic>>[
                    <String, dynamic>{
                      'id': 'playlist-1',
                      'title': 'Created Playlist',
                      'visibility': 'PUBLIC',
                      'tracksCount': 3,
                    },
                  ],
                },
              },
              'liked': <String, dynamic>{
                'liked_playlists': <String, dynamic>{
                  'results': <Map<String, dynamic>>[
                    <String, dynamic>{
                      'id': 'liked-1',
                      'title': 'Liked Playlist',
                      'visibility': 'PUBLIC',
                      'tracksCount': 5,
                    },
                  ],
                },
              },
            },
          },
        };

        final dto = ProfilePageDto.fromJson(json);

        expect(dto.profile.handle, 'artist77');
        expect(dto.playlists, hasLength(1));
        expect(dto.playlists.single.playlistId, 'playlist-1');
        expect(dto.playlists.single.title, 'Created Playlist');
        expect(dto.likedPlaylists, hasLength(1));
        expect(dto.likedPlaylists.single.playlistId, 'liked-1');
        expect(dto.likedPlaylists.single.title, 'Liked Playlist');
      },
    );

    test('falls back to empty lists when playlists are absent', () {
      final json = <String, dynamic>{
        'data': <String, dynamic>{
          'profile': <String, dynamic>{
            'id': 'u1',
            'handle': 'plain_user',
            'display_name': 'Plain User',
            'account_type': 'LISTENER',
            'favorite_genres': <String>[],
            'social_links': <String, dynamic>{},
            'visibility': 'PUBLIC',
            'track_count': 0,
          },
        },
      };

      final dto = ProfilePageDto.fromJson(json);

      expect(dto.profile.handle, 'plain_user');
      expect(dto.playlists, isEmpty);
      expect(dto.likedPlaylists, isEmpty);
    });
  });
}
