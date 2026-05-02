import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/features/offline/presentation/bloc/offline_cubit.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';

import '../../fakes/fake_offline_repository.dart';

void main() {
  late OfflineCubit cubit;
  late FakeOfflineRepository repo;

  setUp(() {
    repo = FakeOfflineRepository();
    cubit = OfflineCubit(repo);
  });

  test('initial state is empty', () {
    expect(cubit.state.downloadedTracks, isEmpty);
  });

  test('download adds track to state and persists', () async {
    await cubit.download('t1');

    expect(cubit.isDownloaded('t1'), true);
    expect(cubit.getPath('t1'), '/fake/t1.mp3');

    final saved = await repo.getDownloadedTracks();
    expect(saved.containsKey('t1'), true);
  });

  test('load restores saved tracks', () async {
    await repo.saveDownloadedTracks({'t1': '/fake/t1.mp3'});

    final newCubit = OfflineCubit(repo);

    await Future.delayed(const Duration(milliseconds: 10));

    expect(newCubit.isDownloaded('t1'), true);
  });

  test('download failure throws DOWNLOAD_FAILED', () async {
    final brokenRepo = _BrokenRepo();
    final brokenCubit = OfflineCubit(brokenRepo);

    expect(
      () => brokenCubit.download('t1'),
      throwsException,
    );
  });

  test('download maps subscription failures to UPGRADE_REQUIRED', () async {
    final brokenRepo = _BrokenRepo(Exception('403 forbidden'));
    final brokenCubit = OfflineCubit(brokenRepo);

    expect(
      () => brokenCubit.download('t1'),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('UPGRADE_REQUIRED'),
        ),
      ),
    );
  });

  test('download returns early when track is already downloaded', () async {
    final scriptedRepo = _ScriptedOfflineRepository(
      savedTracks: <String, String>{'t1': '/saved/t1.mp3'},
    );
    final scriptedCubit = OfflineCubit(scriptedRepo);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    await scriptedCubit.download('t1');

    expect(scriptedRepo.downloadCalls, isZero);
    expect(scriptedCubit.getPath('t1'), '/saved/t1.mp3');
  });

  test('downloadTrack saves track details with local path', () async {
    final track = _track('t1');

    await cubit.downloadTrack(track);

    final saved = await repo.getDownloadedTrackDetails();
    expect(saved['t1']?.localPath, '/fake/t1.mp3');
    expect(cubit.state.downloadedTrackDetails['t1']?.title, 'Track t1');
  });

  test('saveDownloadedPlaylist snapshots downloaded track details', () async {
    final track = _track('t1');
    final playlist = _playlist('p1', tracks: <Track>[track]);

    await cubit.downloadTrack(track);
    await cubit.saveDownloadedPlaylist(playlist);

    final saved = await repo.getDownloadedPlaylists();
    expect(saved['p1']?.tracksCount, 1);
    expect(saved['p1']?.tracks.single.localPath, '/fake/t1.mp3');
    expect(cubit.state.downloadedPlaylists['p1']?.title, 'Playlist p1');
  });

  test('load repairs missing track details from repository', () async {
    final scriptedRepo = _ScriptedOfflineRepository(
      savedTracks: <String, String>{'t1': '/saved/t1.mp3'},
      fetchedTracks: <String, Track>{'t1': _track('t1')},
    );

    final scriptedCubit = OfflineCubit(scriptedRepo);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(scriptedCubit.state.downloadedTrackDetails['t1']?.localPath,
        '/saved/t1.mp3');
    expect(scriptedRepo.savedDetails['t1']?.title, 'Track t1');
  });

  test('load falls back to empty state when repository throws', () async {
    final scriptedRepo = _ScriptedOfflineRepository(throwOnLoad: true);

    final scriptedCubit = OfflineCubit(scriptedRepo);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(scriptedCubit.state.downloadedTracks, isEmpty);
    expect(scriptedCubit.state.downloadedTrackDetails, isEmpty);
    expect(scriptedCubit.state.downloadedPlaylists, isEmpty);
  });
}

/// Helper broken repo
class _BrokenRepo extends FakeOfflineRepository {
  final Object error;

  _BrokenRepo([this.error = const FormatException('fail')]);

  @override
  Future<String> downloadTrack(String trackId) async {
    throw error;
  }
}

Track _track(String id, {String? localPath}) {
  return Track(
    id: id,
    title: 'Track $id',
    artist: 'Artist $id',
    audioUrl: 'https://example.com/$id.mp3',
    localPath: localPath,
  );
}

PlaylistEntity _playlist(String id, {required List<Track> tracks}) {
  return PlaylistEntity(
    playlistId: id,
    title: 'Playlist $id',
    description: 'Description $id',
    visibility: PlaylistVisibility.publicPlaylist,
    secretToken: null,
    coverImageUrl: null,
    owner: null,
    tracks: tracks,
    tracksCount: tracks.length,
  );
}

class _ScriptedOfflineRepository extends FakeOfflineRepository {
  final Map<String, String> savedTracks;
  final Map<String, Track> savedDetails;
  final Map<String, PlaylistEntity> savedPlaylists;
  final Map<String, Track> fetchedTracks;
  final bool throwOnLoad;
  int downloadCalls = 0;

  _ScriptedOfflineRepository({
    Map<String, String>? savedTracks,
    Map<String, Track>? savedDetails,
    Map<String, PlaylistEntity>? savedPlaylists,
    Map<String, Track>? fetchedTracks,
    this.throwOnLoad = false,
  })  : savedTracks = Map<String, String>.from(savedTracks ?? const {}),
        savedDetails = Map<String, Track>.from(savedDetails ?? const {}),
        savedPlaylists =
            Map<String, PlaylistEntity>.from(savedPlaylists ?? const {}),
        fetchedTracks = Map<String, Track>.from(fetchedTracks ?? const {});

  @override
  Future<String> downloadTrack(String trackId) async {
    downloadCalls += 1;
    final path = '/scripted/$trackId.mp3';
    savedTracks[trackId] = path;
    return path;
  }

  @override
  Future<Track?> fetchTrackDetails(String trackId) async {
    return fetchedTracks[trackId];
  }

  @override
  Future<Map<String, String>> getDownloadedTracks() async {
    if (throwOnLoad) throw Exception('load failed');
    return savedTracks;
  }

  @override
  Future<void> saveDownloadedTracks(Map<String, String> data) async {
    savedTracks
      ..clear()
      ..addAll(data);
  }

  @override
  Future<Map<String, Track>> getDownloadedTrackDetails() async {
    return savedDetails;
  }

  @override
  Future<void> saveDownloadedTrackDetails(Map<String, Track> data) async {
    savedDetails
      ..clear()
      ..addAll(data);
  }

  @override
  Future<Map<String, PlaylistEntity>> getDownloadedPlaylists() async {
    return savedPlaylists;
  }

  @override
  Future<void> saveDownloadedPlaylists(Map<String, PlaylistEntity> data) async {
    savedPlaylists
      ..clear()
      ..addAll(data);
  }
}
