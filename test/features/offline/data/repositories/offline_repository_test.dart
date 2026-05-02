import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import '../../fakes/fake_offline_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/network/api_constants.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/features/offline/data/repositories/offline_repository.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  late FakeOfflineRepository repo;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    repo = FakeOfflineRepository();
  });

  test('downloadTrack stores file path', () async {
    final path = await repo.downloadTrack('t1');

    expect(path, '/fake/t1.mp3');

    final stored = await repo.getDownloadedTracks();
    expect(stored['t1'], '/fake/t1.mp3');
  });

  test('saveDownloadedTracks persists data', () async {
    await repo.saveDownloadedTracks({
      't1': '/fake/t1.mp3',
    });

    final stored = await repo.getDownloadedTracks();

    expect(stored.length, 1);
    expect(stored['t1'], '/fake/t1.mp3');
  });

  test('getDownloadedTracks returns empty if nothing saved', () async {
    final stored = await repo.getDownloadedTracks();
    expect(stored, isEmpty);
  });

  group('OfflineRepository persistence', () {
    late OfflineRepository repository;
    late MockDioClient dioClient;

    setUp(() {
      dioClient = MockDioClient();
      repository = OfflineRepository(dioClient);
    });

    test('saveDownloadedTracks persists track file paths', () async {
      await repository.saveDownloadedTracks({
        'trk_1': '/music/trk_1.mp3',
        'trk_2': '/music/trk_2.mp3',
      });

      final stored = await repository.getDownloadedTracks();

      expect(stored, {
        'trk_1': '/music/trk_1.mp3',
        'trk_2': '/music/trk_2.mp3',
      });
    });

    test('getDownloadedTracks returns empty when nothing is saved', () async {
      final stored = await repository.getDownloadedTracks();

      expect(stored, isEmpty);
    });

    test('saveDownloadedTrackDetails round-trips track metadata', () async {
      await repository.saveDownloadedTrackDetails({
        'trk_1': const Track(
          id: 'trk_1',
          title: 'Midnight',
          artist: 'Laila',
          audioUrl: 'https://cdn.example/trk_1.mp3',
          artworkUrl: 'https://cdn.example/trk_1.jpg',
          handle: 'laila',
          artistId: 'artist_1',
          likesCount: 12,
          repostsCount: 5,
          durationMs: 245000,
          localPath: '/music/trk_1.mp3',
        ),
      });

      final stored = await repository.getDownloadedTrackDetails();

      expect(stored.keys, ['trk_1']);
      expect(stored['trk_1']?.id, 'trk_1');
      expect(stored['trk_1']?.title, 'Midnight');
      expect(stored['trk_1']?.artist, 'Laila');
      expect(stored['trk_1']?.audioUrl, 'https://cdn.example/trk_1.mp3');
      expect(stored['trk_1']?.artworkUrl, 'https://cdn.example/trk_1.jpg');
      expect(stored['trk_1']?.handle, 'laila');
      expect(stored['trk_1']?.artistId, 'artist_1');
      expect(stored['trk_1']?.likesCount, 12);
      expect(stored['trk_1']?.repostsCount, 5);
      expect(stored['trk_1']?.durationMs, 245000);
      expect(stored['trk_1']?.localPath, '/music/trk_1.mp3');
    });

    test('getDownloadedTrackDetails returns empty for invalid payload',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'offline_track_details': '[]',
      });

      final stored = await repository.getDownloadedTrackDetails();

      expect(stored, isEmpty);
    });

    test('saveDownloadedPlaylists round-trips playlists and tracks', () async {
      await repository.saveDownloadedPlaylists({
        'pl_1': _playlist(),
      });

      final stored = await repository.getDownloadedPlaylists();

      expect(stored.keys, ['pl_1']);
      expect(stored['pl_1']?.playlistId, 'pl_1');
      expect(stored['pl_1']?.title, 'Offline Mix');
      expect(stored['pl_1']?.description, 'Saved locally');
      expect(
        stored['pl_1']?.visibility,
        PlaylistVisibility.privatePlaylist,
      );
      expect(stored['pl_1']?.genre, 'Ambient');
      expect(stored['pl_1']?.genreId, 8);
      expect(stored['pl_1']?.slug, 'offline-mix');
      expect(stored['pl_1']?.playlistType, 'PLAYLIST');
      expect(stored['pl_1']?.releaseDate, DateTime.utc(2026, 3, 4));
      expect(stored['pl_1']?.tags, ['sleep', 'focus']);
      expect(stored['pl_1']?.secretToken, 'secret_1');
      expect(stored['pl_1']?.coverImageUrl, 'https://cdn.example/pl_1.jpg');
      expect(stored['pl_1']?.owner?.displayName, 'Ali');
      expect(stored['pl_1']?.tracks, hasLength(1));
      expect(stored['pl_1']?.tracks.single.id, 'trk_1');
      expect(stored['pl_1']?.tracksCount, 1);
      expect(stored['pl_1']?.likesCount, 13);
      expect(stored['pl_1']?.isLiked, isTrue);
    });

    test('getDownloadedPlaylists returns empty for invalid payload', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'offline_playlists': '[]',
      });

      final stored = await repository.getDownloadedPlaylists();

      expect(stored, isEmpty);
    });

    test('fetchTrackDetails parses nested data payload', () async {
      when(() => dioClient.get(ApiConstants.trackByIdPath('trk_9'))).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions:
              RequestOptions(path: ApiConstants.trackByIdPath('trk_9')),
          data: <String, dynamic>{
            'data': <String, dynamic>{
              'track_id': 'trk_9',
              'title': 'Cloud Nine',
              'artistName': 'Nour',
              'streamUrl': 'https://cdn.example/trk_9.mp3',
              'cover_art_url': 'https://cdn.example/trk_9.jpg',
              'artistHandle': 'nour',
              'artist_id': 'artist_9',
              'likesCount': '22',
              'repostsCount': 4.9,
              'durationMs': '199000',
            },
          },
        ),
      );

      final track = await repository.fetchTrackDetails('trk_9');

      expect(track?.id, 'trk_9');
      expect(track?.title, 'Cloud Nine');
      expect(track?.artist, 'Nour');
      expect(track?.audioUrl, 'https://cdn.example/trk_9.mp3');
      expect(track?.artworkUrl, 'https://cdn.example/trk_9.jpg');
      expect(track?.handle, 'nour');
      expect(track?.artistId, 'artist_9');
      expect(track?.likesCount, 22);
      expect(track?.repostsCount, 4);
      expect(track?.durationMs, 199000);
    });

    test('fetchTrackDetails returns null for empty payload and failures',
        () async {
      when(() => dioClient.get(ApiConstants.trackByIdPath('empty'))).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions:
              RequestOptions(path: ApiConstants.trackByIdPath('empty')),
          data: const <String, dynamic>{},
        ),
      );
      when(() => dioClient.get(ApiConstants.trackByIdPath('broken')))
          .thenThrow(Exception('network down'));

      expect(await repository.fetchTrackDetails('empty'), isNull);
      expect(await repository.fetchTrackDetails('broken'), isNull);
    });
  });
}

PlaylistEntity _playlist() {
  return PlaylistEntity(
    playlistId: 'pl_1',
    title: 'Offline Mix',
    description: 'Saved locally',
    visibility: PlaylistVisibility.privatePlaylist,
    genre: 'Ambient',
    genreId: 8,
    slug: 'offline-mix',
    playlistType: 'PLAYLIST',
    releaseDate: DateTime.utc(2026, 3, 4),
    tags: const ['sleep', 'focus'],
    secretToken: 'secret_1',
    coverImageUrl: 'https://cdn.example/pl_1.jpg',
    owner: const PlaylistOwner(id: 'owner_1', displayName: 'Ali'),
    tracks: const [
      Track(
        id: 'trk_1',
        title: 'Midnight',
        artist: 'Laila',
        audioUrl: 'https://cdn.example/trk_1.mp3',
        artworkUrl: 'https://cdn.example/trk_1.jpg',
        handle: 'laila',
        artistId: 'artist_1',
        likesCount: 12,
        repostsCount: 5,
        durationMs: 245000,
        localPath: '/music/trk_1.mp3',
      ),
    ],
    tracksCount: 1,
    likesCount: 13,
    isLiked: true,
  );
}
