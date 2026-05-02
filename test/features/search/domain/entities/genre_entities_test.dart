import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/search/domain/entities/genre_entities.dart';
import 'package:soundcloud_clone/core/models/track.dart';

void main() {
  group('Genre entity classes', () {
    test('AlbumEntity props include all values', () {
      const album = AlbumEntity(
        id: 'a1',
        title: 'Album Title',
        artistName: 'Artist',
        artworkUrl: 'cover.png',
        trackCount: 9,
        releaseYear: 2025,
      );

      expect(album.props, [
        'a1',
        'Album Title',
        'Artist',
        'cover.png',
        9,
        2025,
      ]);
    });

    test('GenreProfileEntity props include all values', () {
      const profile = GenreProfileEntity(
        id: 'u1',
        username: 'user',
        displayName: 'User Name',
        avatarUrl: 'avatar.png',
        isVerified: true,
      );

      expect(profile.props, ['u1', 'user', 'User Name', 'avatar.png', true]);
    });

    test('GenrePageData default values are empty collection defaults', () {
      const data = GenrePageData();
      expect(data.headerImageUrl, '');
      expect(data.trending, isEmpty);
      expect(data.albums, isEmpty);
      expect(data.profiles, isEmpty);
      expect(data.followingIds, isEmpty);
    });

    test('GenrePageData stores provided values', () {
      const track = Track(
        id: 't1',
        title: 'Track',
        artist: 'Artist',
        audioUrl: 'audio.mp3',
        artworkUrl: 'art.png',
        likesCount: 1,
        repostsCount: 0,
      );
      final data = GenrePageData(
        headerImageUrl: 'header.png',
        trending: [track],
        playlists: const [],
        albums: const [],
        profiles: const [],
        discoverMore: const [],
        followingIds: const {'u1'},
      );

      expect(data.headerImageUrl, 'header.png');
      expect(data.trending, [track]);
      expect(data.followingIds, {'u1'});
    });
  });
}
