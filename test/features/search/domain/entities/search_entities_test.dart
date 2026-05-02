import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/search/domain/entities/search_entities.dart';

void main() {
  group('SearchResultsEntity', () {
    test('isEmpty is true when all collections are empty', () {
      const entity = SearchResultsEntity(
        tracks: [],
        users: [],
        playlists: [],
        meta: SearchMetaEntity(currentPage: 1, totalResults: 0, totalPages: 1),
      );

      expect(entity.isEmpty, true);
      expect(entity.hasResults, false);
      expect(entity.totalCount, 0);
    });

    test('hasResults is true when at least one list is non-empty', () {
      // ❌ شيلنا const لأن TrackEntity فيها DateTime
      final entity = SearchResultsEntity(
        tracks: [
          TrackEntity(
            id: '1',
            title: 'Title',
            artistName: 'Artist',
            artworkUrl: 'art.png',
            streamUrl: 'stream.mp3',
            duration: const Duration(seconds: 10),
            playbackCount: 1,
            likesCount: 2,
            genre: 'electronic',
            isPrivate: false,
            createdAt: DateTime(2024, 1, 1),
          )
        ],
        users: const [],
        playlists: const [],
        meta: const SearchMetaEntity(currentPage: 1, totalResults: 1, totalPages: 1),
      );

      expect(entity.isEmpty, false);
      expect(entity.hasResults, true);
      expect(entity.totalCount, 1);
    });
  });

  group('SearchMetaEntity', () {
    test('hasMore returns true when currentPage is less than totalPages', () {
      const meta = SearchMetaEntity(currentPage: 1, totalResults: 10, totalPages: 2);
      expect(meta.hasMore, true);
    });

    test('hasMore returns false when currentPage equals totalPages', () {
      const meta = SearchMetaEntity(currentPage: 2, totalResults: 10, totalPages: 2);
      expect(meta.hasMore, false);
    });
  });

  group('TrackEntity', () {
    test('formattedDuration returns mm:ss for durations under an hour', () {
      // ❌ شيلنا const
      final track = TrackEntity(
        id: '1',
        title: 'Track',
        artistName: 'Artist',
        artworkUrl: 'art.png',
        streamUrl: 'stream.mp3',
        duration: const Duration(minutes: 3, seconds: 7),
        playbackCount: 5,
        likesCount: 3,
        genre: 'pop',
        isPrivate: false,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(track.formattedDuration, '03:07');
    });

    test('formattedDuration returns h:mm:ss for durations over an hour', () {
      // ❌ شيلنا const
      final track = TrackEntity(
        id: '2',
        title: 'Long',
        artistName: 'Artist',
        artworkUrl: 'art.png',
        streamUrl: 'stream.mp3',
        duration: const Duration(hours: 1, minutes: 2, seconds: 3),
        playbackCount: 5,
        likesCount: 3,
        genre: 'electronic',
        isPrivate: false,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(track.formattedDuration, '1:02:03');
    });
  });

  group('UserEntity', () {
    test('location joins city and country', () {
      const user = UserEntity(
        id: 'u1',
        username: 'user',
        displayName: 'User',
        avatarUrl: 'avatar.png',
        followersCount: 10,
        trackCount: 2,
        verified: true,
        city: 'Cairo',
        country: 'Egypt',
      );

      expect(user.location, 'Cairo, Egypt');
    });

    test('location omits empty city or country values', () {
      const user = UserEntity(
        id: 'u1',
        username: 'user',
        displayName: 'User',
        avatarUrl: 'avatar.png',
        followersCount: 10,
        trackCount: 2,
        verified: true,
        city: '',
        country: 'Egypt',
      );

      expect(user.location, 'Egypt');
    });
  });

  group('PlaylistEntity', () {
    test('kind returns Album when isAlbum is true', () {
      // ❌ شيلنا const
      final playlist = PlaylistEntity(
        id: 'p1',
        title: 'Album',
        artworkUrl: 'art.png',
        trackCount: 10,
        ownerName: 'Owner',
        isAlbum: true,
        isPrivate: false,
        duration: const Duration(minutes: 30),
        likesCount: 100,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(playlist.kind, 'Album');
    });

    test('kind returns Playlist when isAlbum is false', () {
      // ❌ شيلنا const
      final playlist = PlaylistEntity(
        id: 'p1',
        title: 'Playlist',
        artworkUrl: 'art.png',
        trackCount: 5,
        ownerName: 'Owner',
        isAlbum: false,
        isPrivate: false,
        duration: const Duration(minutes: 10),
        likesCount: 10,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(playlist.kind, 'Playlist');
    });
  });
}