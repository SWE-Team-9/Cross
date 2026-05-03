import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/search/data/dto/search_models.dart';

void main() {
  group('SearchResponseModel', () {
    test('parses grouped discovery search response', () {
      final model = SearchResponseModel.fromJson({
        'tracks': [
          {
            'id': 'trk_1',
            'title': 'Layali',
            'durationMs': 143000,
            'coverArtUrl': 'https://cdn.test/cover.jpg',
            'audioUrl': 'https://cdn.test/audio.mp3',
            'genre': {'slug': 'electronic'},
            'stats': {'playsCount': 55, 'likesCount': 7},
            'uploader': {
              'profile': {
                'displayName': 'Ali Beats',
                'handle': 'ali-beats',
              },
            },
            'createdAt': '2026-05-01T10:00:00.000Z',
          }
        ],
        'users': [
          {
            'id': 'usr_1',
            'handle': 'ali',
            'displayName': 'Ali',
            'avatarUrl': 'https://cdn.test/avatar.jpg',
            'followersCount': 12,
            'trackCount': 3,
            'verified': true,
          }
        ],
        'playlists': [
          {
            'id': 'pl_1',
            'title': 'Night Mix',
            'trackCount': 8,
            'ownerName': 'Ali',
            'coverArtUrl': 'https://cdn.test/pl.jpg',
            'durationMs': 120000,
            'likesCount': 4,
            'createdAt': '2026-05-01T10:00:00.000Z',
          }
        ],
        'meta': {
          'current_page': 2,
          'total_results': 30,
          'total_pages': 3,
        },
      });

      expect(model.tracks, hasLength(1));
      expect(model.users, hasLength(1));
      expect(model.playlists, hasLength(1));

      expect(model.tracks.first.id, 'trk_1');
      expect(model.tracks.first.artistName, 'Ali Beats');
      expect(model.tracks.first.genre, 'electronic');
      expect(model.tracks.first.duration, const Duration(milliseconds: 143000));
      expect(model.tracks.first.playbackCount, 55);
      expect(model.tracks.first.likesCount, 7);

      expect(model.users.first.id, 'usr_1');
      expect(model.users.first.username, 'ali');
      expect(model.users.first.verified, true);

      expect(model.playlists.first.id, 'pl_1');
      expect(model.playlists.first.trackCount, 8);

      expect(model.meta.currentPage, 2);
      expect(model.meta.totalResults, 30);
      expect(model.meta.totalPages, 3);
    });

    test('parses response when groups are nested under data', () {
      final model = SearchResponseModel.fromJson({
        'data': {
          'tracks': [
            {'id': 'trk_1', 'title': 'Track'}
          ],
          'users': [
            {'id': 'usr_1', 'handle': 'user'}
          ],
          'playlists': [
            {'id': 'pl_1', 'title': 'Playlist'}
          ],
        },
        'meta': {
          'page': 1,
          'total': 3,
          'totalPages': 1,
        },
      });

      expect(model.tracks.single.id, 'trk_1');
      expect(model.users.single.id, 'usr_1');
      expect(model.playlists.single.id, 'pl_1');
      expect(model.meta.currentPage, 1);
      expect(model.meta.totalResults, 3);
      expect(model.meta.totalPages, 1);
    });

    test('returns empty groups when response has no lists', () {
      final model = SearchResponseModel.fromJson({
        'meta': {'page': 1, 'total': 0, 'totalPages': 0},
      });

      expect(model.tracks, isEmpty);
      expect(model.users, isEmpty);
      expect(model.playlists, isEmpty);
      expect(model.meta.totalResults, 0);
    });
  });
}
