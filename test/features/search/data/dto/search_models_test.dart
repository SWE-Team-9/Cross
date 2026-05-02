import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/search/data/dto/search_models.dart';

void main() {
  group('SearchResponseModel', () {
    test('fromJson parses full response and toEntity preserves values', () {
      final json = {
        'data': {
          'tracks': [
            {
              'id': '1',
              'title': 'Track One',
              'artistHandle': 'artist123',
              'artwork_url': 'track.png',
              'stream_url': 'stream.mp3',
              'duration': 120,
              'views': 10,
              'likes_count': 4,
              'genre': 'pop',
              'sharing': 'private',
              'created_at': '2024-01-01T00:00:00Z',
            },
          ],
          'users': [
            {
              'id': 'u1',
              'handle': 'user123',
              'display_name': 'User Name',
              'avatar_url': 'avatar.png',
              'followers_count': 7,
              'track_count': 3,
              'verified': true,
              'city': 'Cairo',
              'country': 'Egypt',
            }
          ],
          'playlists': [
            {
              'id': 'p1',
              'title': 'Playlist One',
              'artwork_url': 'playlist.png',
              'trackCount': 5,
              'ownerName': 'Owner',
              'is_album': true,
              'sharing': 'public',
              'duration': 2400,
              'likesCount': 12,
              'created_at': '2024-01-01T00:00:00Z',
            }
          ],
        },
        'meta': {
          'current_page': 1,
          'total_results': 3,
          'total_pages': 1,
        },
      };

      final model = SearchResponseModel.fromJson(json);

      expect(model.tracks, hasLength(1));
      expect(model.tracks.first.isPrivate, true);
      expect(model.tracks.first.duration, Duration(seconds: 120));
      expect(model.users.first.username, 'user123');
      expect(model.playlists.first.isAlbum, true);
      expect(model.meta.currentPage, 1);

      final entity = model.toEntity();
      expect(entity.tracks.first.title, 'Track One');
      expect(entity.meta.totalResults, 3);
    });

    test('fromJson handles missing arrays and fallback fields', () {
      final Map<String, dynamic> json = {
        'data': <String, dynamic>{
          'tracks': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': '2',
              'title': 'Track Two',
              'artist_handle': 'artist2',
              'coverArtUrl': 'art2.png',
              'streamUrl': 'stream2.mp3',
              'duration': 60,
              'likesCount': 1,
              'genre': 'rock',
              'isPrivate': false,
              'createdAt': '2024-01-02T00:00:00Z',
            }
          ],
          'users': <dynamic>[],
          'playlists': <dynamic>[],
        },
        'meta': <String, dynamic>{},
      };

      final model = SearchResponseModel.fromJson(json);
      expect(model.tracks.first.artistName, 'artist2');
      expect(model.tracks.first.artworkUrl, 'art2.png');
      expect(model.tracks.first.streamUrl, 'stream2.mp3');
      expect(model.meta.totalPages, 0);
    });
  });
}
