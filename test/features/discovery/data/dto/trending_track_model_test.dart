import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/discovery/data/dto/trending_track_model.dart';

void main() {
  group('TrendingTrackModel', () {
    test('parses global trending track response', () {
      final model = TrendingTrackModel.fromJson({
        'id': 'trk_1',
        'title': 'Layali El Qahira',
        'genre': {
          'slug': 'electronic',
          'name': 'Electronic',
        },
        'audioUrl': 'https://cdn.test/audio.mp3',
        'coverArtUrl': 'https://cdn.test/cover.jpg',
        'velocityScore': 98.5,
        'recentPlays': 1200,
        'recentLikes': 95,
        'recentReposts': 12,
        'commentsCount': 8,
        'liked': true,
        'uploader': {
          'userId': 'usr_1',
          'profile': {
            'handle': 'ali-beats',
            'displayName': 'Ali Beats',
          },
        },
      });

      expect(model.id, 'trk_1');
      expect(model.title, 'Layali El Qahira');
      expect(model.genre, 'electronic');
      expect(model.audioUrl, 'https://cdn.test/audio.mp3');
      expect(model.coverUrl, 'https://cdn.test/cover.jpg');
      expect(model.trendingScore, 98.5);
      expect(model.playCount, 1200);
      expect(model.likesCount, 95);
      expect(model.repostsCount, 12);
      expect(model.commentsCount, 8);
      expect(model.isLiked, true);
      expect(model.ownerId, 'usr_1');
      expect(model.ownerHandle, 'ali-beats');
      expect(model.ownerDisplayName, 'Ali Beats');
    });

    test('parses genre trending track response with fallback fields', () {
      final model = TrendingTrackModel.fromJson({
        'trackId': 'trk_2',
        'title': 'Night Drive',
        'genre': 'lo-fi',
        'streamUrl': 'https://cdn.test/stream.mp3',
        'coverUrl': 'https://cdn.test/cover-2.jpg',
        'trending_score': '42.75',
        'playsCount': '300',
        'likesCount': '21',
        'repostsCount': '5',
        'stats': {
          'commentsCount': '4',
        },
        'artist': {
          'id': 'usr_2',
          'handle': 'night-artist',
          'displayName': 'Night Artist',
        },
      });

      expect(model.id, 'trk_2');
      expect(model.genre, 'lo-fi');
      expect(model.audioUrl, 'https://cdn.test/stream.mp3');
      expect(model.coverUrl, 'https://cdn.test/cover-2.jpg');
      expect(model.trendingScore, 42.75);
      expect(model.playCount, 300);
      expect(model.likesCount, 21);
      expect(model.repostsCount, 5);
      expect(model.commentsCount, 4);
      expect(model.ownerId, 'usr_2');
      expect(model.ownerHandle, 'night-artist');
      expect(model.ownerDisplayName, 'Night Artist');
    });

    test('uses safe defaults for missing optional fields', () {
      final model = TrendingTrackModel.fromJson({
        'id': 'trk_3',
        'title': 'Minimal Track',
      });

      expect(model.id, 'trk_3');
      expect(model.title, 'Minimal Track');
      expect(model.genre, '');
      expect(model.audioUrl, '');
      expect(model.coverUrl, '');
      expect(model.trendingScore, 0.0);
      expect(model.playCount, 0);
      expect(model.likesCount, 0);
      expect(model.repostsCount, 0);
      expect(model.commentsCount, 0);
      expect(model.isLiked, false);
      expect(model.ownerId, '');
      expect(model.ownerHandle, '');
      expect(model.ownerDisplayName, '');
    });
  });
}
