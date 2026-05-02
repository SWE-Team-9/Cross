import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/features/playlists/data/local/liked_playlists_store.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const store = LikedPlaylistsStore();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('LikedPlaylistsStore', () {
    test('returns empty list when nothing is cached', () async {
      final playlists = await store.load();

      expect(playlists, isEmpty);
    });

    test('loads cached playlists and skips invalid entries', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'liked_playlists_local': jsonEncode([
          <String, dynamic>{
            'playlistId': 'pl_1',
            'title': 'Road Trip',
            'description': 'Long drive picks',
            'visibility': 'SECRET',
            'genre': 'Rock',
            'genreId': '12',
            'slug': 'road-trip',
            'playlistType': 'ALBUM',
            'releaseDate': '2026-04-05T00:00:00.000Z',
            'tags': ['drive', '  ', 'night'],
            'secretToken': 'secret_1',
            'coverImageUrl': 'https://cdn.example/cover.jpg',
            'owner': <String, dynamic>{
              'id': 'owner_1',
              'displayName': 'Mona',
            },
            'tracks': <dynamic>[
              <String, dynamic>{
                'id': 'trk_1',
                'title': 'Lights',
                'artist': 'The Drivers',
                'audioUrl': 'https://cdn.example/trk_1.mp3',
                'artworkUrl': 'https://cdn.example/trk_1.jpg',
                'handle': 'drivers',
                'artistId': 'artist_1',
                'likesCount': '7',
                'repostsCount': 3.8,
                'durationMs': '180000',
                'localPath': '/tracks/trk_1.mp3',
              },
              <String, dynamic>{'title': 'No id'},
            ],
            'tracksCount': null,
            'likesCount': '4',
            'isLiked': false,
          },
          <String, dynamic>{'title': 'Missing id'},
        ]),
      });

      final playlists = await store.load(limit: 5);

      expect(playlists, hasLength(1));
      expect(playlists.single.playlistId, 'pl_1');
      expect(playlists.single.title, 'Road Trip');
      expect(playlists.single.visibility, PlaylistVisibility.privatePlaylist);
      expect(playlists.single.genre, 'Rock');
      expect(playlists.single.genreId, 12);
      expect(playlists.single.slug, 'road-trip');
      expect(playlists.single.playlistType, 'ALBUM');
      expect(playlists.single.releaseDate, DateTime.utc(2026, 4, 5));
      expect(playlists.single.tags, ['drive', 'night']);
      expect(playlists.single.secretToken, 'secret_1');
      expect(playlists.single.coverImageUrl, 'https://cdn.example/cover.jpg');
      expect(playlists.single.owner?.displayName, 'Mona');
      expect(playlists.single.tracks, hasLength(1));
      expect(playlists.single.tracks.single.id, 'trk_1');
      expect(playlists.single.tracks.single.artist, 'The Drivers');
      expect(playlists.single.tracks.single.likesCount, 7);
      expect(playlists.single.tracks.single.repostsCount, 3);
      expect(playlists.single.tracks.single.durationMs, 180000);
      expect(playlists.single.tracks.single.localPath, '/tracks/trk_1.mp3');
      expect(playlists.single.tracksCount, 1);
      expect(playlists.single.likesCount, 4);
      expect(playlists.single.isLiked, isFalse);
    });

    test('returns empty list when cached payload is not a list', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'liked_playlists_local': jsonEncode(<String, dynamic>{'bad': true}),
      });

      final playlists = await store.load();

      expect(playlists, isEmpty);
    });

    test('returns empty list when cached payload is invalid json', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'liked_playlists_local': '{',
      });

      final playlists = await store.load();

      expect(playlists, isEmpty);
    });

    test('saveLiked marks playlist liked, increments likes, and de-duplicates',
        () async {
      await store.saveLiked(_playlist('pl_old', likesCount: 2), limit: 3);
      await store.saveLiked(_playlist('pl_1', likesCount: 4), limit: 3);
      await store.saveLiked(
        _playlist('pl_1', title: 'Updated', likesCount: 10, isLiked: true),
        limit: 3,
      );

      final playlists = await store.load();

      expect(playlists.map((playlist) => playlist.playlistId), [
        'pl_1',
        'pl_old',
      ]);
      expect(playlists.first.title, 'Updated');
      expect(playlists.first.isLiked, isTrue);
      expect(playlists.first.likesCount, 10);
      expect(await store.isLiked('pl_1'), isTrue);
      expect(await store.isLiked('missing'), isFalse);
    });

    test('saveLiked respects the supplied limit', () async {
      await store.saveLiked(_playlist('pl_1'), limit: 2);
      await store.saveLiked(_playlist('pl_2'), limit: 2);
      await store.saveLiked(_playlist('pl_3'), limit: 2);

      final playlists = await store.load();

      expect(playlists.map((playlist) => playlist.playlistId), [
        'pl_3',
        'pl_2',
      ]);
    });

    test('remove deletes the matching playlist only', () async {
      await store.saveLiked(_playlist('pl_1'));
      await store.saveLiked(_playlist('pl_2'));

      await store.remove('pl_1');

      final playlists = await store.load();
      expect(playlists.map((playlist) => playlist.playlistId), ['pl_2']);
    });
  });
}

PlaylistEntity _playlist(
  String id, {
  String? title,
  int likesCount = 0,
  bool isLiked = false,
}) {
  return PlaylistEntity(
    playlistId: id,
    title: title ?? 'Playlist $id',
    description: 'Description $id',
    visibility: PlaylistVisibility.publicPlaylist,
    genre: 'Electronic',
    genreId: 5,
    slug: 'playlist-$id',
    playlistType: 'PLAYLIST',
    releaseDate: DateTime.utc(2026, 1, 2),
    tags: const ['one', 'two'],
    secretToken: null,
    coverImageUrl: null,
    owner: const PlaylistOwner(id: 'owner_1', displayName: 'Owner'),
    tracks: [
      Track(
        id: 'track_$id',
        title: 'Track $id',
        artist: 'Artist',
        audioUrl: 'https://cdn.example/$id.mp3',
      ),
    ],
    tracksCount: 1,
    likesCount: likesCount,
    isLiked: isLiked,
  );
}
