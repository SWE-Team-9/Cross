import 'package:flutter_test/flutter_test.dart';

import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/features/offline/data/repositories/offline_repository.dart';
import 'package:soundcloud_clone/features/offline/presentation/bloc/offline_cubit.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';

void main() {
  group('OfflineCubit', () {
    late _FakeOfflineRepository repository;

    setUp(() {
      repository = _FakeOfflineRepository();
    });

    test('loads saved offline tracks, details, and playlists on creation',
        () async {
      repository.downloadedTracks = <String, String>{
        'track-1': '/offline/track-1.mp3',
      };

      repository.downloadedTrackDetails = <String, Track>{
        'track-1': _track(
          id: 'track-1',
          title: 'Midnight Drive',
          localPath: '/offline/track-1.mp3',
        ),
      };

      repository.downloadedPlaylists = <String, PlaylistEntity>{
        'playlist-1': _playlist(),
      };

      final cubit = OfflineCubit(repository);
      await _flushAsync();

      expect(cubit.state.downloadedTracks, repository.downloadedTracks);
      expect(cubit.state.downloadedTrackDetails['track-1']!.title,
          'Midnight Drive');
      expect(
          cubit.state.downloadedPlaylists['playlist-1']!.title, 'Offline Mix');

      expect(repository.getDownloadedTracksCalls, 1);
      expect(repository.getDownloadedTrackDetailsCalls, 1);
      expect(repository.getDownloadedPlaylistsCalls, 1);

      await cubit.close();
    });

    test('repairs missing track details during load', () async {
      repository.downloadedTracks = <String, String>{
        'track-1': '/offline/track-1.mp3',
      };

      repository.fetchTrackDetailsResult = _track(
        id: 'track-1',
        title: 'Fetched Track',
      );

      final cubit = OfflineCubit(repository);
      await _flushAsync();

      expect(cubit.state.downloadedTrackDetails['track-1']!.title,
          'Fetched Track');
      expect(cubit.state.downloadedTrackDetails['track-1']!.localPath,
          '/offline/track-1.mp3');
      expect(repository.fetchTrackDetailsCalls, 1);
      expect(repository.saveDownloadedTrackDetailsCalls, 1);

      await cubit.close();
    });

    test('repairs stale local path during load', () async {
      repository.downloadedTracks = <String, String>{
        'track-1': '/new/track-1.mp3',
      };

      repository.downloadedTrackDetails = <String, Track>{
        'track-1': _track(
          id: 'track-1',
          title: 'Saved Track',
          localPath: '/old/track-1.mp3',
        ),
      };

      final cubit = OfflineCubit(repository);
      await _flushAsync();

      expect(cubit.state.downloadedTrackDetails['track-1']!.localPath,
          '/new/track-1.mp3');
      expect(repository.saveDownloadedTrackDetailsCalls, 1);

      await cubit.close();
    });

    test('falls back to empty state when load fails', () async {
      repository.loadError = Exception('Storage failed');

      final cubit = OfflineCubit(repository);
      await _flushAsync();

      expect(cubit.state.downloadedTracks, isEmpty);
      expect(cubit.state.downloadedTrackDetails, isEmpty);
      expect(cubit.state.downloadedPlaylists, isEmpty);

      await cubit.close();
    });

    test('download saves premium offline track path and details', () async {
      repository.downloadTrackPath = '/offline/track-1.mp3';
      repository.downloadedTrackDetails = <String, Track>{
        'track-1': _track(
          id: 'track-1',
          title: 'Downloaded Track',
          localPath: '/offline/track-1.mp3',
        ),
      };

      final cubit = OfflineCubit(repository);
      await _flushAsync();

      await cubit.download(' track-1 ');

      expect(cubit.state.downloadedTracks, <String, String>{
        'track-1': '/offline/track-1.mp3',
      });
      expect(cubit.state.downloadedTrackDetails['track-1']!.localPath,
          '/offline/track-1.mp3');

      expect(repository.downloadTrackCalls, 1);
      expect(repository.lastDownloadTrackId, 'track-1');
      expect(repository.saveDownloadedTracksCalls, 1);
      expect(repository.saveDownloadedTrackDetailsCalls, 1);

      await cubit.close();
    });

    test('download does nothing when track is already downloaded', () async {
      repository.downloadedTracks = <String, String>{
        'track-1': '/offline/track-1.mp3',
      };

      final cubit = OfflineCubit(repository);
      await _flushAsync();

      await cubit.download('track-1');

      expect(repository.downloadTrackCalls, 0);

      await cubit.close();
    });

    test('download rejects empty track id', () async {
      final cubit = OfflineCubit(repository);
      await _flushAsync();

      expect(
        () => cubit.download('   '),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('DOWNLOAD_FAILED'),
          ),
        ),
      );

      expect(repository.downloadTrackCalls, 0);

      await cubit.close();
    });

    test('download maps premium errors to UPGRADE_REQUIRED', () async {
      repository.downloadError = StateError(
        'Offline downloads require a premium subscription.',
      );

      final cubit = OfflineCubit(repository);
      await _flushAsync();

      expect(
        () => cubit.download('track-1'),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('UPGRADE_REQUIRED'),
          ),
        ),
      );

      await cubit.close();
    });

    test('download maps empty file errors to DOWNLOAD_EMPTY', () async {
      repository.downloadError = StateError('Downloaded audio file is empty.');

      final cubit = OfflineCubit(repository);
      await _flushAsync();

      expect(
        () => cubit.download('track-1'),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('DOWNLOAD_EMPTY'),
          ),
        ),
      );

      await cubit.close();
    });

    test('download maps generic errors to DOWNLOAD_FAILED', () async {
      repository.downloadError = Exception('Network failed');

      final cubit = OfflineCubit(repository);
      await _flushAsync();

      expect(
        () => cubit.download('track-1'),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('DOWNLOAD_FAILED'),
          ),
        ),
      );

      await cubit.close();
    });

    test('downloadTrack downloads missing track and saves local details',
        () async {
      repository.downloadTrackPath = '/offline/track-1.mp3';

      final cubit = OfflineCubit(repository);
      await _flushAsync();

      await cubit.downloadTrack(
        _track(
          id: 'track-1',
          title: 'Input Track',
          localPath: null,
        ),
      );

      expect(cubit.state.downloadedTracks['track-1'], '/offline/track-1.mp3');
      expect(
          cubit.state.downloadedTrackDetails['track-1']!.title, 'Input Track');
      expect(cubit.state.downloadedTrackDetails['track-1']!.localPath,
          '/offline/track-1.mp3');

      expect(repository.downloadTrackCalls, 1);
      expect(
          repository.saveDownloadedTrackDetailsCalls, greaterThanOrEqualTo(1));

      await cubit.close();
    });

    test('downloadTrack does not download again when track already exists',
        () async {
      repository.downloadedTracks = <String, String>{
        'track-1': '/offline/track-1.mp3',
      };

      final cubit = OfflineCubit(repository);
      await _flushAsync();

      await cubit.downloadTrack(
        _track(
          id: 'track-1',
          title: 'Already Saved',
        ),
      );

      expect(repository.downloadTrackCalls, 0);
      expect(cubit.state.downloadedTrackDetails['track-1']!.title,
          'Already Saved');
      expect(cubit.state.downloadedTrackDetails['track-1']!.localPath,
          '/offline/track-1.mp3');

      await cubit.close();
    });

    test('downloadTrack rejects empty track id', () async {
      final cubit = OfflineCubit(repository);
      await _flushAsync();

      expect(
        () => cubit.downloadTrack(_track(id: '   ')),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('DOWNLOAD_FAILED'),
          ),
        ),
      );

      await cubit.close();
    });

    test('saveDownloadedPlaylist persists playlist with repaired local paths',
        () async {
      repository.downloadedTracks = <String, String>{
        'track-1': '/offline/track-1.mp3',
      };

      repository.downloadedTrackDetails = <String, Track>{
        'track-1': _track(
          id: 'track-1',
          title: 'Saved Track',
          localPath: '/offline/track-1.mp3',
        ),
      };

      final cubit = OfflineCubit(repository);
      await _flushAsync();

      await cubit.saveDownloadedPlaylist(
        _playlist(
          tracks: <Track>[
            _track(
              id: 'track-1',
              title: 'Original Track',
              localPath: null,
            ),
          ],
        ),
      );

      final playlist = cubit.state.downloadedPlaylists['playlist-1']!;

      expect(playlist.tracksCount, 1);
      expect(playlist.tracks.first.title, 'Saved Track');
      expect(playlist.tracks.first.localPath, '/offline/track-1.mp3');
      expect(repository.saveDownloadedPlaylistsCalls, 1);

      await cubit.close();
    });

    test('removeDownloadedTrack removes path and details then persists',
        () async {
      repository.downloadedTracks = <String, String>{
        'track-1': '/offline/track-1.mp3',
        'track-2': '/offline/track-2.mp3',
      };

      repository.downloadedTrackDetails = <String, Track>{
        'track-1': _track(
          id: 'track-1',
          localPath: '/offline/track-1.mp3',
        ),
        'track-2': _track(
          id: 'track-2',
          localPath: '/offline/track-2.mp3',
        ),
      };

      final cubit = OfflineCubit(repository);
      await _flushAsync();

      await cubit.removeDownloadedTrack(' track-1 ');

      expect(cubit.state.downloadedTracks.containsKey('track-1'), isFalse);
      expect(cubit.state.downloadedTracks.containsKey('track-2'), isTrue);
      expect(
          cubit.state.downloadedTrackDetails.containsKey('track-1'), isFalse);
      expect(cubit.state.downloadedTrackDetails.containsKey('track-2'), isTrue);
      expect(repository.saveDownloadedTracksCalls, 1);
      expect(repository.saveDownloadedTrackDetailsCalls, 1);

      await cubit.close();
    });

    test('removeDownloadedTrack ignores empty id', () async {
      final cubit = OfflineCubit(repository);
      await _flushAsync();

      await cubit.removeDownloadedTrack('   ');

      expect(repository.saveDownloadedTracksCalls, 0);
      expect(repository.saveDownloadedTrackDetailsCalls, 0);

      await cubit.close();
    });

    test('removeDownloadedPlaylist removes playlist then persists', () async {
      repository.downloadedPlaylists = <String, PlaylistEntity>{
        'playlist-1': _playlist(),
        'playlist-2': _playlist(playlistId: 'playlist-2'),
      };

      final cubit = OfflineCubit(repository);
      await _flushAsync();

      await cubit.removeDownloadedPlaylist(' playlist-1 ');

      expect(
          cubit.state.downloadedPlaylists.containsKey('playlist-1'), isFalse);
      expect(cubit.state.downloadedPlaylists.containsKey('playlist-2'), isTrue);
      expect(repository.saveDownloadedPlaylistsCalls, 1);

      await cubit.close();
    });

    test('removeDownloadedPlaylist ignores empty id', () async {
      final cubit = OfflineCubit(repository);
      await _flushAsync();

      await cubit.removeDownloadedPlaylist('   ');

      expect(repository.saveDownloadedPlaylistsCalls, 0);

      await cubit.close();
    });

    test('reload refreshes persisted offline state', () async {
      final cubit = OfflineCubit(repository);
      await _flushAsync();

      expect(cubit.state.downloadedTracks, isEmpty);

      repository.downloadedTracks = <String, String>{
        'track-1': '/offline/track-1.mp3',
      };

      await cubit.reload();

      expect(cubit.state.downloadedTracks['track-1'], '/offline/track-1.mp3');
      expect(repository.getDownloadedTracksCalls, 2);

      await cubit.close();
    });

    test('selectors trim ids and return downloaded items', () async {
      repository.downloadedTracks = <String, String>{
        'track-1': '/offline/track-1.mp3',
      };

      repository.downloadedTrackDetails = <String, Track>{
        'track-1': _track(id: 'track-1'),
      };

      repository.downloadedPlaylists = <String, PlaylistEntity>{
        'playlist-1': _playlist(),
      };

      final cubit = OfflineCubit(repository);
      await _flushAsync();

      expect(cubit.isDownloaded(' track-1 '), isTrue);
      expect(cubit.getPath(' track-1 '), '/offline/track-1.mp3');
      expect(cubit.getDownloadedTrack(' track-1 ')!.id, 'track-1');
      expect(cubit.isPlaylistDownloaded(' playlist-1 '), isTrue);
      expect(cubit.getDownloadedPlaylist(' playlist-1 ')!.playlistId,
          'playlist-1');

      await cubit.close();
    });
  });
}

Future<void> _flushAsync() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

Track _track({
  String id = 'track-1',
  String title = 'Midnight Drive',
  String artist = 'DJ Nova',
  String audioUrl = 'https://example.com/audio.mp3',
  String? artworkUrl = 'https://example.com/cover.jpg',
  String? handle = 'djnova',
  String? artistId = 'artist-1',
  int likesCount = 12,
  int repostsCount = 4,
  int? durationMs = 214000,
  String? localPath,
}) {
  return Track(
    id: id,
    title: title,
    artist: artist,
    audioUrl: audioUrl,
    artworkUrl: artworkUrl,
    handle: handle,
    artistId: artistId,
    likesCount: likesCount,
    repostsCount: repostsCount,
    durationMs: durationMs,
    localPath: localPath,
  );
}

PlaylistEntity _playlist({
  String playlistId = 'playlist-1',
  List<Track> tracks = const <Track>[],
}) {
  return PlaylistEntity(
    playlistId: playlistId,
    title: 'Offline Mix',
    description: 'Saved playlist',
    visibility: PlaylistVisibility.publicPlaylist,
    genre: 'Electronic',
    genreId: 7,
    slug: 'offline-mix',
    playlistType: 'PLAYLIST',
    releaseDate: DateTime.parse('2026-04-01T00:00:00.000Z'),
    tags: const <String>['electronic', 'mix'],
    secretToken: 'secret-token',
    coverImageUrl: 'https://example.com/playlist.jpg',
    owner: const PlaylistOwner(
      id: 'owner-1',
      displayName: 'DJ Nova',
    ),
    tracks: tracks,
    tracksCount: tracks.length,
    likesCount: 10,
    isLiked: true,
  );
}

class _FakeOfflineRepository implements OfflineRepository {
  @override
  DioClient get dio => throw UnimplementedError();

  Map<String, String> downloadedTracks = <String, String>{};
  Map<String, Track> downloadedTrackDetails = <String, Track>{};
  Map<String, PlaylistEntity> downloadedPlaylists = <String, PlaylistEntity>{};

  String downloadTrackPath = '/offline/default-track.mp3';
  Object? downloadError;
  Object? loadError;
  Track? fetchTrackDetailsResult;

  int downloadTrackCalls = 0;
  int fetchTrackDetailsCalls = 0;
  int saveDownloadedTracksCalls = 0;
  int saveDownloadedTrackDetailsCalls = 0;
  int saveDownloadedPlaylistsCalls = 0;
  int getDownloadedTracksCalls = 0;
  int getDownloadedTrackDetailsCalls = 0;
  int getDownloadedPlaylistsCalls = 0;

  String? lastDownloadTrackId;
  String? lastFetchTrackDetailsId;

  @override
  Future<String> downloadTrack(String trackId) async {
    downloadTrackCalls++;
    lastDownloadTrackId = trackId;

    final error = downloadError;
    if (error != null) {
      throw error;
    }

    downloadedTracks[trackId] = downloadTrackPath;

    downloadedTrackDetails.putIfAbsent(
      trackId,
      () => _track(
        id: trackId,
        title: 'Downloaded Track',
        localPath: downloadTrackPath,
      ),
    );

    return downloadTrackPath;
  }

  @override
  Future<Track?> fetchTrackDetails(String trackId) async {
    fetchTrackDetailsCalls++;
    lastFetchTrackDetailsId = trackId;
    return fetchTrackDetailsResult;
  }

  @override
  Future<Map<String, String>> getDownloadedTracks() async {
    getDownloadedTracksCalls++;

    final error = loadError;
    if (error != null) {
      throw error;
    }

    return Map<String, String>.from(downloadedTracks);
  }

  @override
  Future<void> saveDownloadedTracks(Map<String, String> data) async {
    saveDownloadedTracksCalls++;
    downloadedTracks = Map<String, String>.from(data);
  }

  @override
  Future<Map<String, Track>> getDownloadedTrackDetails() async {
    getDownloadedTrackDetailsCalls++;

    final error = loadError;
    if (error != null) {
      throw error;
    }

    return Map<String, Track>.from(downloadedTrackDetails);
  }

  @override
  Future<void> saveDownloadedTrackDetails(Map<String, Track> data) async {
    saveDownloadedTrackDetailsCalls++;
    downloadedTrackDetails = Map<String, Track>.from(data);
  }

  @override
  Future<Map<String, PlaylistEntity>> getDownloadedPlaylists() async {
    getDownloadedPlaylistsCalls++;

    final error = loadError;
    if (error != null) {
      throw error;
    }

    return Map<String, PlaylistEntity>.from(downloadedPlaylists);
  }

  @override
  Future<void> saveDownloadedPlaylists(Map<String, PlaylistEntity> data) async {
    saveDownloadedPlaylistsCalls++;
    downloadedPlaylists = Map<String, PlaylistEntity>.from(data);
  }
}
