import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/features/playlists/data/local/recent_playlists_store.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const store = RecentPlaylistsStore();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('RecentPlaylistsStore', () {
    test('returns empty list when no recent playlists are cached', () async {
      final playlists = await store.load();

      expect(playlists, isEmpty);
    });

    test('loads cached playlists and applies limit', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'recent_playlists_local': jsonEncode([
          _playlistJson('pl_1', title: 'First'),
          _playlistJson('pl_2', title: 'Second'),
          <String, dynamic>{'title': 'Missing id'},
        ]),
      });

      final playlists = await store.load(limit: 1);

      expect(playlists, hasLength(1));
      expect(playlists.single.playlistId, 'pl_1');
      expect(playlists.single.title, 'First');
      expect(playlists.single.description, 'Description pl_1');
      expect(playlists.single.visibility, PlaylistVisibility.privatePlaylist);
      expect(playlists.single.genre, 'Jazz');
      expect(playlists.single.genreId, 3);
      expect(playlists.single.slug, 'slug-pl_1');
      expect(playlists.single.playlistType, 'SET');
      expect(playlists.single.releaseDate, DateTime.utc(2026, 2, 3));
      expect(playlists.single.tags, ['late', 'set']);
      expect(playlists.single.secretToken, 'secret-pl_1');
      expect(playlists.single.coverImageUrl, 'https://cdn.example/pl_1.jpg');
      expect(playlists.single.owner?.id, 'owner_pl_1');
      expect(playlists.single.owner?.displayName, 'Owner pl_1');
      expect(playlists.single.tracks, hasLength(1));
      expect(playlists.single.tracks.single.id, 'track_pl_1');
      expect(playlists.single.tracks.single.title, 'Track pl_1');
      expect(playlists.single.tracks.single.likesCount, 6);
      expect(playlists.single.tracksCount, 9);
      expect(playlists.single.likesCount, 11);
      expect(playlists.single.isLiked, isTrue);
    });

    test('returns empty list for malformed cache payloads', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'recent_playlists_local': jsonEncode(<String, dynamic>{'bad': true}),
      });

      expect(await store.load(), isEmpty);

      SharedPreferences.setMockInitialValues(<String, Object>{
        'recent_playlists_local': '[',
      });

      expect(await store.load(), isEmpty);
    });

    test('record stores newest playlist first and removes duplicates',
        () async {
      await store.record(_playlist('pl_1'), limit: 3);
      await store.record(_playlist('pl_2'), limit: 3);
      await store.record(_playlist('pl_1', title: 'Updated'), limit: 3);

      final playlists = await store.load();

      expect(playlists.map((playlist) => playlist.playlistId), [
        'pl_1',
        'pl_2',
      ]);
      expect(playlists.first.title, 'Updated');
    });

    test('record keeps only the requested number of playlists', () async {
      await store.record(_playlist('pl_1'), limit: 2);
      await store.record(_playlist('pl_2'), limit: 2);
      await store.record(_playlist('pl_3'), limit: 2);

      final playlists = await store.load();

      expect(playlists.map((playlist) => playlist.playlistId), [
        'pl_3',
        'pl_2',
      ]);
    });
  });
}

Map<String, dynamic> _playlistJson(String id, {required String title}) {
  return <String, dynamic>{
    'playlistId': id,
    'title': title,
    'description': 'Description $id',
    'visibility': 'PRIVATE',
    'genre': 'Jazz',
    'genreId': 3.2,
    'slug': 'slug-$id',
    'playlistType': 'SET',
    'releaseDate': '2026-02-03T00:00:00.000Z',
    'tags': ['late', '', 'set'],
    'secretToken': 'secret-$id',
    'coverImageUrl': 'https://cdn.example/$id.jpg',
    'owner': <String, dynamic>{
      'id': 'owner_$id',
      'displayName': 'Owner $id',
    },
    'tracks': <dynamic>[
      <String, dynamic>{
        'id': 'track_$id',
        'title': 'Track $id',
        'artist': 'Artist $id',
        'audioUrl': 'https://cdn.example/track_$id.mp3',
        'artworkUrl': 'https://cdn.example/track_$id.jpg',
        'handle': 'artist_$id',
        'artistId': 'artist-id-$id',
        'likesCount': '6',
        'repostsCount': '2',
        'durationMs': 123000.5,
        'localPath': '/tmp/track_$id.mp3',
      },
      <String, dynamic>{'title': 'Missing id'},
    ],
    'tracksCount': '9',
    'likesCount': 11.8,
    'isLiked': true,
  };
}

PlaylistEntity _playlist(String id, {String? title}) {
  return PlaylistEntity(
    playlistId: id,
    title: title ?? 'Playlist $id',
    description: 'Description $id',
    visibility: PlaylistVisibility.publicPlaylist,
    genre: 'Pop',
    genreId: 6,
    slug: 'playlist-$id',
    playlistType: 'PLAYLIST',
    releaseDate: DateTime.utc(2026, 4, 1),
    tags: const ['new'],
    secretToken: null,
    coverImageUrl: 'https://cdn.example/$id.jpg',
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
    likesCount: 3,
    isLiked: false,
  );
}
