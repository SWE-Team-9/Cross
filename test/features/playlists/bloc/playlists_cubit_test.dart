import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/add_track_to_playlist_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/create_playlist_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/delete_playlist_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/get_my_playlists_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/get_playlist_details_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/get_playlist_embed_code_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/remove_track_from_playlist_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/reorder_playlist_tracks_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/resolve_secret_playlist_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/update_playlist_usecase.dart';
import 'package:soundcloud_clone/features/playlists/presentation/bloc/playlists_cubit.dart';
import 'package:soundcloud_clone/features/playlists/presentation/bloc/playlists_state.dart';

class MockGetMyPlaylistsUseCase extends Mock implements GetMyPlaylistsUseCase {}

class MockCreatePlaylistUseCase extends Mock implements CreatePlaylistUseCase {}

class MockGetPlaylistDetailsUseCase extends Mock
    implements GetPlaylistDetailsUseCase {}

class MockUpdatePlaylistUseCase extends Mock implements UpdatePlaylistUseCase {}

class MockDeletePlaylistUseCase extends Mock implements DeletePlaylistUseCase {}

class MockAddTrackToPlaylistUseCase extends Mock
    implements AddTrackToPlaylistUseCase {}

class MockRemoveTrackFromPlaylistUseCase extends Mock
    implements RemoveTrackFromPlaylistUseCase {}

class MockReorderPlaylistTracksUseCase extends Mock
    implements ReorderPlaylistTracksUseCase {}

class MockResolveSecretPlaylistUseCase extends Mock
    implements ResolveSecretPlaylistUseCase {}

class MockGetPlaylistEmbedCodeUseCase extends Mock
    implements GetPlaylistEmbedCodeUseCase {}

PlaylistEntity _playlist({
  String id = 'pl_1',
  String? title,
  List<Track> tracks = const <Track>[],
  int? count,
}) {
  return PlaylistEntity(
    playlistId: id,
    title: title ?? 'Playlist $id',
    description: 'desc',
    visibility: PlaylistVisibility.publicPlaylist,
    secretToken: null,
    coverImageUrl: null,
    owner: null,
    tracks: tracks,
    tracksCount: count ?? tracks.length,
  );
}

Track _track({String id = 'trk_1'}) {
  return Track(
    id: id,
    title: 'Track $id',
    artist: 'Artist',
    audioUrl: '',
  );
}

void main() {
  late MockGetMyPlaylistsUseCase getMy;
  late MockCreatePlaylistUseCase create;
  late MockGetPlaylistDetailsUseCase details;
  late MockUpdatePlaylistUseCase update;
  late MockDeletePlaylistUseCase del;
  late MockAddTrackToPlaylistUseCase addTrack;
  late MockRemoveTrackFromPlaylistUseCase removeTrack;
  late MockReorderPlaylistTracksUseCase reorder;
  late MockResolveSecretPlaylistUseCase resolveSecret;
  late MockGetPlaylistEmbedCodeUseCase embed;

  setUp(() {
    getMy = MockGetMyPlaylistsUseCase();
    create = MockCreatePlaylistUseCase();
    details = MockGetPlaylistDetailsUseCase();
    update = MockUpdatePlaylistUseCase();
    del = MockDeletePlaylistUseCase();
    addTrack = MockAddTrackToPlaylistUseCase();
    removeTrack = MockRemoveTrackFromPlaylistUseCase();
    reorder = MockReorderPlaylistTracksUseCase();
    resolveSecret = MockResolveSecretPlaylistUseCase();
    embed = MockGetPlaylistEmbedCodeUseCase();
  });

  PlaylistsCubit buildCubit() => PlaylistsCubit(
        getMyPlaylistsUseCase: getMy,
        createPlaylistUseCase: create,
        getPlaylistDetailsUseCase: details,
        updatePlaylistUseCase: update,
        deletePlaylistUseCase: del,
        addTrackToPlaylistUseCase: addTrack,
        removeTrackFromPlaylistUseCase: removeTrack,
        reorderPlaylistTracksUseCase: reorder,
        resolveSecretPlaylistUseCase: resolveSecret,
        getPlaylistEmbedCodeUseCase: embed,
      );

  group('PlaylistsCubit', () {
    test('initial state is defaults', () {
      final cubit = buildCubit();
      expect(cubit.state.playlists, isEmpty);
      expect(cubit.state.selectedPlaylist, isNull);
      expect(cubit.state.isSubmitting, isFalse);
      expect(cubit.state.errorMessage, isNull);
    });

    blocTest<PlaylistsCubit, PlaylistsState>(
      'loadMyPlaylists emits first paginated list',
      build: () {
        when(
          () => getMy(page: 1, limit: 20),
        ).thenAnswer((_) async => [_playlist()]);
        return buildCubit();
      },
      act: (cubit) => cubit.loadMyPlaylists(),
      expect: () => [
        isA<PlaylistsState>()
            .having((s) => s.isLoadingMyPlaylists, 'loading', isTrue)
            .having((s) => s.isLoadingMoreMyPlaylists, 'loading more', isFalse),
        isA<PlaylistsState>()
            .having((s) => s.isLoadingMyPlaylists, 'loading', isFalse)
            .having((s) => s.playlists.length, 'length', 1)
            .having((s) => s.myPlaylistsPage, 'page', 1)
            .having((s) => s.hasMoreMyPlaylists, 'has more', isFalse),
      ],
      verify: (_) {
        verify(() => getMy(page: 1, limit: 20)).called(1);
      },
    );
    blocTest<PlaylistsCubit, PlaylistsState>(
      'loadMyPlaylists emits login message on unauthorized failure',
      build: () {
        when(
          () => getMy(page: 1, limit: 20),
        ).thenThrow(Exception('401 unauthorized'));
        return buildCubit();
      },
      act: (cubit) => cubit.loadMyPlaylists(),
      expect: () => [
        isA<PlaylistsState>()
            .having((s) => s.isLoadingMyPlaylists, 'loading', isTrue),
        isA<PlaylistsState>()
            .having((s) => s.isLoadingMyPlaylists, 'loading', isFalse)
            .having((s) => s.errorMessage, 'error', 'Please log in again'),
      ],
    );

    blocTest<PlaylistsCubit, PlaylistsState>(
      'loadMoreMyPlaylists appends next unique page',
      build: () {
        when(
          () => getMy(page: 2, limit: 20),
        ).thenAnswer(
          (_) async => [
            _playlist(id: 'pl_2'),
            _playlist(id: 'pl_3'),
          ],
        );
        return buildCubit();
      },
      seed: () => PlaylistsState.initial().copyWith(
        playlists: [_playlist(id: 'pl_1')],
        myPlaylistsPage: 1,
        hasMoreMyPlaylists: true,
      ),
      act: (cubit) => cubit.loadMoreMyPlaylists(),
      expect: () => [
        isA<PlaylistsState>()
            .having((s) => s.isLoadingMoreMyPlaylists, 'loading more', isTrue),
        isA<PlaylistsState>()
            .having((s) => s.isLoadingMoreMyPlaylists, 'loading more', isFalse)
            .having((s) => s.playlists.length, 'length', 3)
            .having((s) => s.playlists.last.playlistId, 'last id', 'pl_3')
            .having((s) => s.myPlaylistsPage, 'page', 2)
            .having((s) => s.hasMoreMyPlaylists, 'has more', isFalse),
      ],
      verify: (_) {
        verify(() => getMy(page: 2, limit: 20)).called(1);
      },
    );

    blocTest<PlaylistsCubit, PlaylistsState>(
      'loadMoreMyPlaylists skips duplicate playlist ids',
      build: () {
        when(
          () => getMy(page: 2, limit: 20),
        ).thenAnswer(
          (_) async => [
            _playlist(id: 'pl_1'),
            _playlist(id: 'pl_2'),
          ],
        );
        return buildCubit();
      },
      seed: () => PlaylistsState.initial().copyWith(
        playlists: [_playlist(id: 'pl_1')],
        myPlaylistsPage: 1,
        hasMoreMyPlaylists: true,
      ),
      act: (cubit) => cubit.loadMoreMyPlaylists(),
      expect: () => [
        isA<PlaylistsState>()
            .having((s) => s.isLoadingMoreMyPlaylists, 'loading more', isTrue),
        isA<PlaylistsState>()
            .having((s) => s.isLoadingMoreMyPlaylists, 'loading more', isFalse)
            .having((s) => s.playlists.length, 'length', 2)
            .having((s) => s.playlists.first.playlistId, 'first id', 'pl_1')
            .having((s) => s.playlists.last.playlistId, 'last id', 'pl_2'),
      ],
      verify: (_) {
        verify(() => getMy(page: 2, limit: 20)).called(1);
      },
    );

    blocTest<PlaylistsCubit, PlaylistsState>(
      'loadMoreMyPlaylists does nothing when no more pages exist',
      build: buildCubit,
      seed: () => PlaylistsState.initial().copyWith(
        playlists: [_playlist(id: 'pl_1')],
        myPlaylistsPage: 1,
        hasMoreMyPlaylists: false,
      ),
      act: (cubit) => cubit.loadMoreMyPlaylists(),
      expect: () => const <PlaylistsState>[],
      verify: (_) {
        verifyZeroInteractions(getMy);
      },
    );

    blocTest<PlaylistsCubit, PlaylistsState>(
      'loadMoreMyPlaylists emits friendly error on failure',
      build: () {
        when(
          () => getMy(page: 2, limit: 20),
        ).thenThrow(Exception('network timeout'));
        return buildCubit();
      },
      seed: () => PlaylistsState.initial().copyWith(
        playlists: [_playlist(id: 'pl_1')],
        myPlaylistsPage: 1,
        hasMoreMyPlaylists: true,
      ),
      act: (cubit) => cubit.loadMoreMyPlaylists(),
      expect: () => [
        isA<PlaylistsState>()
            .having((s) => s.isLoadingMoreMyPlaylists, 'loading more', isTrue),
        isA<PlaylistsState>()
            .having((s) => s.isLoadingMoreMyPlaylists, 'loading more', isFalse)
            .having(
              (s) => s.errorMessage,
              'error',
              'Network error. Please check your connection',
            ),
      ],
    );

    blocTest<PlaylistsCubit, PlaylistsState>(
      'createPlaylist prepends created playlist',
      build: () {
        when(
          () => create(
            title: 'Focus',
            description: 'Coding',
            visibility: PlaylistVisibility.privatePlaylist,
            initialTrackIds: const <String>[],
          ),
        ).thenAnswer(
          (_) async => _playlist(id: 'pl_new', count: 0),
        );
        return buildCubit();
      },
      seed: () => PlaylistsState.initial().copyWith(
        playlists: [_playlist(id: 'pl_old', count: 2)],
      ),
      act: (cubit) => cubit.createPlaylist(
        title: 'Focus',
        description: 'Coding',
        visibility: PlaylistVisibility.privatePlaylist,
      ),
      expect: () => [
        isA<PlaylistsState>()
            .having((s) => s.isSubmitting, 'submitting', isTrue),
        isA<PlaylistsState>()
            .having((s) => s.isSubmitting, 'submitting', isFalse)
            .having((s) => s.playlists.first.playlistId, 'first id', 'pl_new')
            .having((s) => s.playlists.length, 'length', 2),
      ],
    );

    test('createPlaylist returns null and emits error on failure', () async {
      when(
        () => create(
          title: 'Focus',
          description: 'Coding',
          visibility: PlaylistVisibility.privatePlaylist,
          initialTrackIds: const <String>[],
        ),
      ).thenThrow(Exception('create failed'));

      final cubit = buildCubit();
      final created = await cubit.createPlaylist(
        title: 'Focus',
        description: 'Coding',
        visibility: PlaylistVisibility.privatePlaylist,
      );

      expect(created, isNull);
      expect(
        cubit.state.errorMessage,
        'Something went wrong. Please try again',
      );
    });

    blocTest<PlaylistsCubit, PlaylistsState>(
      'createPlaylist rejects duplicate title',
      build: buildCubit,
      seed: () => PlaylistsState.initial().copyWith(
        playlists: [_playlist(id: 'pl_1', title: 'Focus')],
      ),
      act: (cubit) => cubit.createPlaylist(
        title: ' focus ',
        description: 'Coding',
        visibility: PlaylistVisibility.publicPlaylist,
      ),
      expect: () => [
        isA<PlaylistsState>()
            .having((s) => s.errorMessage, 'error', contains('already exists')),
      ],
      verify: (_) {
        verifyZeroInteractions(create);
      },
    );

    test('createPlaylist rejects empty title before usecase call', () async {
      final cubit = buildCubit();

      final created = await cubit.createPlaylist(
        title: '   ',
        description: 'Coding',
        visibility: PlaylistVisibility.publicPlaylist,
      );

      expect(created, isNull);
      expect(cubit.state.errorMessage, 'Playlist title is required');
      verifyZeroInteractions(create);
    });

    test('createPlaylist rejects too long title before usecase call', () async {
      final cubit = buildCubit();

      final created = await cubit.createPlaylist(
        title: 'a' * 101,
        description: 'Coding',
        visibility: PlaylistVisibility.publicPlaylist,
      );

      expect(created, isNull);
      expect(
        cubit.state.errorMessage,
        'Playlist title must be 100 characters or less',
      );
      verifyZeroInteractions(create);
    });

    test('createPlaylist rejects duplicate initial track ids', () async {
      final cubit = buildCubit();

      final created = await cubit.createPlaylist(
        title: 'Focus',
        description: 'Coding',
        visibility: PlaylistVisibility.publicPlaylist,
        initialTrackIds: const <String>['trk_1', 'trk_1'],
      );

      expect(created, isNull);
      expect(
        cubit.state.errorMessage,
        'Playlist tracks contain invalid or duplicate IDs',
      );
      verifyZeroInteractions(create);
    });

    test('createPlaylist trims title and description before usecase call',
        () async {
      when(
        () => create(
          title: 'Focus',
          description: 'Coding',
          visibility: PlaylistVisibility.publicPlaylist,
          initialTrackIds: const <String>['trk_1'],
        ),
      ).thenAnswer((_) async => _playlist(id: 'pl_new'));

      final cubit = buildCubit();

      final created = await cubit.createPlaylist(
        title: '  Focus  ',
        description: '  Coding  ',
        visibility: PlaylistVisibility.publicPlaylist,
        initialTrackIds: const <String>[' trk_1 '],
      );

      expect(created, isNotNull);
      verify(
        () => create(
          title: 'Focus',
          description: 'Coding',
          visibility: PlaylistVisibility.publicPlaylist,
          initialTrackIds: const <String>['trk_1'],
        ),
      ).called(1);
    });

    blocTest<PlaylistsCubit, PlaylistsState>(
      'addTrackToPlaylist updates list count and tracks',
      build: () {
        when(
          () => addTrack(
            playlistId: 'pl_1',
            trackId: 'trk_99',
          ),
        ).thenAnswer((_) async {});
        return buildCubit();
      },
      seed: () => PlaylistsState.initial().copyWith(
        playlists: [_playlist(id: 'pl_1', tracks: const <Track>[], count: 0)],
      ),
      act: (cubit) => cubit.addTrackToPlaylist(
        playlistId: 'pl_1',
        track: _track(id: 'trk_99'),
      ),
      expect: () => [
        isA<PlaylistsState>()
            .having((s) => s.isSubmitting, 'submitting', isTrue),
        isA<PlaylistsState>()
            .having((s) => s.isSubmitting, 'submitting', isFalse)
            .having((s) => s.playlists.first.tracksCount, 'tracksCount', 1),
      ],
    );

    blocTest<PlaylistsCubit, PlaylistsState>(
      'addTrackToPlaylist updates selected playlist and reloads details',
      build: () {
        when(
          () => addTrack(
            playlistId: 'pl_1',
            trackId: 'trk_99',
          ),
        ).thenAnswer((_) async {});
        when(() => details('pl_1'))
            .thenAnswer((_) async => _playlist(id: 'pl_1', count: 4));
        return buildCubit();
      },
      seed: () => PlaylistsState.initial().copyWith(
        playlists: [_playlist(id: 'pl_1', tracks: const <Track>[], count: 0)],
        selectedPlaylist:
            _playlist(id: 'pl_1', tracks: const <Track>[], count: 0),
      ),
      act: (cubit) => cubit.addTrackToPlaylist(
        playlistId: 'pl_1',
        track: _track(id: 'trk_99'),
      ),
      expect: () => [
        isA<PlaylistsState>()
            .having((s) => s.isSubmitting, 'submitting', isTrue),
        isA<PlaylistsState>()
            .having((s) => s.isSubmitting, 'submitting', isFalse)
            .having((s) => s.selectedPlaylist?.tracksCount, 'count', 1),
        isA<PlaylistsState>()
            .having((s) => s.isLoadingDetails, 'loading details', isTrue),
        isA<PlaylistsState>()
            .having((s) => s.isLoadingDetails, 'loading details', isFalse)
            .having((s) => s.selectedPlaylist?.tracksCount, 'details count', 4),
      ],
    );

    test('addTrackToPlaylist returns false on failure', () async {
      when(
        () => addTrack(
          playlistId: 'pl_1',
          trackId: 'trk_fail',
        ),
      ).thenThrow(Exception('403 forbidden'));

      final cubit = buildCubit();
      final added = await cubit.addTrackToPlaylist(
        playlistId: 'pl_1',
        track: _track(id: 'trk_fail'),
      );

      expect(added, isFalse);
      expect(
        cubit.state.errorMessage,
        'You do not have permission to do this',
      );
    });

    test('addTrackToPlaylist rejects empty track id before usecase call',
        () async {
      final cubit = buildCubit();

      final added = await cubit.addTrackToPlaylist(
        playlistId: 'pl_1',
        track: _track(id: '   '),
      );

      expect(added, isFalse);
      expect(cubit.state.errorMessage, 'Track ID is required');
      verifyZeroInteractions(addTrack);
    });

    test(
        'addTrackToPlaylist ignores duplicate selected track before usecase call',
        () async {
      final existingTrack = _track(id: 'trk_1');
      final cubit = buildCubit();

      cubit.emit(
        PlaylistsState.initial().copyWith(
          selectedPlaylist: _playlist(
            id: 'pl_1',
            tracks: [existingTrack],
            count: 1,
          ),
        ),
      );

      final added = await cubit.addTrackToPlaylist(
        playlistId: 'pl_1',
        track: _track(id: ' trk_1 '),
      );

      expect(added, isFalse);
      expect(cubit.state.infoMessage, 'Track is already in this playlist');
      verifyZeroInteractions(addTrack);
    });
    blocTest<PlaylistsCubit, PlaylistsState>(
      'loadPlaylistDetails upserts selected playlist',
      build: () {
        when(() => details('pl_1'))
            .thenAnswer((_) async => _playlist(id: 'pl_1', count: 3));
        return buildCubit();
      },
      seed: () => PlaylistsState.initial().copyWith(
        playlists: [_playlist(id: 'pl_2', count: 1)],
      ),
      act: (cubit) => cubit.loadPlaylistDetails('pl_1'),
      expect: () => [
        isA<PlaylistsState>()
            .having((s) => s.isLoadingDetails, 'loading details', isTrue),
        isA<PlaylistsState>()
            .having((s) => s.isLoadingDetails, 'loading details', isFalse)
            .having((s) => s.selectedPlaylist?.playlistId, 'selected', 'pl_1')
            .having(
                (s) => s.playlists.first.playlistId, 'first list id', 'pl_1'),
      ],
    );

    blocTest<PlaylistsCubit, PlaylistsState>(
      'updatePlaylist refreshes selected playlist details',
      build: () {
        when(
          () => update(
            playlistId: 'pl_1',
            title: 'Renamed',
            description: null,
            visibility: null,
            genreId: null,
          ),
        ).thenAnswer((_) async {});
        when(() => details('pl_1'))
            .thenAnswer((_) async => _playlist(id: 'pl_1', count: 5));
        return buildCubit();
      },
      seed: () => PlaylistsState.initial().copyWith(
        playlists: [_playlist(id: 'pl_1', count: 1)],
        selectedPlaylist: _playlist(id: 'pl_1', count: 1),
      ),
      act: (cubit) => cubit.updatePlaylist(
        playlistId: 'pl_1',
        title: 'Renamed',
      ),
      expect: () => [
        isA<PlaylistsState>()
            .having((s) => s.isSubmitting, 'submitting', isTrue),
        isA<PlaylistsState>()
            .having((s) => s.isSubmitting, 'submitting', isFalse)
            .having((s) => s.infoMessage, 'info', 'Playlist updated')
            .having((s) => s.selectedPlaylist?.title, 'title', 'Renamed'),
        isA<PlaylistsState>()
            .having((s) => s.isLoadingDetails, 'loading details', isTrue),
        isA<PlaylistsState>()
            .having((s) => s.isLoadingDetails, 'loading details', isFalse)
            .having((s) => s.selectedPlaylist?.tracksCount, 'details count', 5),
      ],
    );

    test('updatePlaylist emits error when request fails', () async {
      when(
        () => update(
          playlistId: 'pl_1',
          title: 'New',
          description: null,
          visibility: null,
          genreId: null,
        ),
      ).thenThrow(Exception('400 validation failed'));
      final cubit = buildCubit();
      await cubit.updatePlaylist(playlistId: 'pl_1', title: 'New');

      expect(cubit.state.errorMessage, 'Invalid playlist data');
      expect(cubit.state.isSubmitting, isFalse);
    });

    blocTest<PlaylistsCubit, PlaylistsState>(
      'updatePlaylist rejects duplicate title',
      build: buildCubit,
      seed: () => PlaylistsState.initial().copyWith(
        playlists: [
          _playlist(id: 'pl_1', title: 'Focus'),
          _playlist(id: 'pl_2', title: 'Chill'),
        ],
      ),
      act: (cubit) => cubit.updatePlaylist(
        playlistId: 'pl_2',
        title: ' focus ',
      ),
      expect: () => [
        isA<PlaylistsState>()
            .having((s) => s.errorMessage, 'error', contains('already exists')),
      ],
      verify: (_) {
        verifyZeroInteractions(update);
      },
    );

    test('updatePlaylist rejects empty title before usecase call', () async {
      final cubit = buildCubit();

      await cubit.updatePlaylist(
        playlistId: 'pl_1',
        title: '   ',
      );

      expect(cubit.state.errorMessage, 'Playlist title is required');
      verifyZeroInteractions(update);
    });

    test('updatePlaylist rejects too long description before usecase call',
        () async {
      final cubit = buildCubit();

      await cubit.updatePlaylist(
        playlistId: 'pl_1',
        description: 'a' * 501,
      );

      expect(
        cubit.state.errorMessage,
        'Playlist description must be 500 characters or less',
      );
      verifyZeroInteractions(update);
    });

    test('updatePlaylist trims title and description before usecase call',
        () async {
      when(
        () => update(
          playlistId: 'pl_1',
          title: 'Renamed',
          description: 'Updated description',
          visibility: null,
          genreId: null,
        ),
      ).thenAnswer((_) async {});

      when(() => details('pl_1')).thenAnswer(
        (_) async => _playlist(id: 'pl_1', title: 'Renamed'),
      );

      final cubit = buildCubit();

      await cubit.updatePlaylist(
        playlistId: 'pl_1',
        title: '  Renamed  ',
        description: '  Updated description  ',
      );

      verify(
        () => update(
          playlistId: 'pl_1',
          title: 'Renamed',
          description: 'Updated description',
          visibility: null,
          genreId: null,
        ),
      ).called(1);
    });

    blocTest<PlaylistsCubit, PlaylistsState>(
      'deletePlaylist removes entry and clears selected playlist',
      build: () {
        when(() => del('pl_1')).thenAnswer((_) async {});
        return buildCubit();
      },
      seed: () => PlaylistsState.initial().copyWith(
        playlists: [_playlist(id: 'pl_1'), _playlist(id: 'pl_2')],
        selectedPlaylist: _playlist(id: 'pl_1'),
      ),
      act: (cubit) => cubit.deletePlaylist('pl_1'),
      expect: () => [
        isA<PlaylistsState>()
            .having((s) => s.isSubmitting, 'submitting', isTrue),
        isA<PlaylistsState>()
            .having((s) => s.isSubmitting, 'submitting', isFalse)
            .having((s) => s.playlists.length, 'remaining', 1)
            .having((s) => s.selectedPlaylist, 'selected cleared', isNull)
            .having((s) => s.infoMessage, 'info', 'Playlist deleted'),
      ],
    );

    test('deletePlaylist emits error on failure', () async {
      when(() => del('pl_1')).thenThrow(Exception('404 not found'));
      final cubit = buildCubit();
      await cubit.deletePlaylist('pl_1');

      expect(cubit.state.errorMessage, 'Playlist not found');
      expect(cubit.state.isSubmitting, isFalse);
    });

    blocTest<PlaylistsCubit, PlaylistsState>(
      'removeTrackFromPlaylist applies optimistic update then confirms',
      build: () {
        when(
          () => removeTrack(
            playlistId: 'pl_1',
            trackId: 'trk_1',
          ),
        ).thenAnswer((_) async {});
        return buildCubit();
      },
      seed: () {
        final t1 = _track(id: 'trk_1');
        final t2 = _track(id: 'trk_2');
        final selected = _playlist(id: 'pl_1', tracks: [t1, t2], count: 2);
        return PlaylistsState.initial().copyWith(
          selectedPlaylist: selected,
          playlists: [selected],
        );
      },
      act: (cubit) => cubit.removeTrackFromPlaylist(
        playlistId: 'pl_1',
        trackId: 'trk_1',
      ),
      expect: () => [
        isA<PlaylistsState>()
            .having((s) => s.isSubmitting, 'submitting', isTrue)
            .having(
                (s) => s.selectedPlaylist?.tracks.length, 'optimistic len', 1),
        isA<PlaylistsState>()
            .having((s) => s.isSubmitting, 'submitting', isFalse)
            .having((s) => s.playlists.first.tracksCount, 'count', 1)
            .having(
                (s) => s.infoMessage, 'info', 'Track removed from playlist'),
      ],
    );

    blocTest<PlaylistsCubit, PlaylistsState>(
      'removeTrackFromPlaylist rolls back selected playlist on failure',
      build: () {
        when(
          () => removeTrack(
            playlistId: 'pl_1',
            trackId: 'trk_1',
          ),
        ).thenThrow(Exception('remove failed'));
        return buildCubit();
      },
      seed: () {
        final t1 = _track(id: 'trk_1');
        final t2 = _track(id: 'trk_2');
        final selected = _playlist(id: 'pl_1', tracks: [t1, t2], count: 2);
        return PlaylistsState.initial().copyWith(
          selectedPlaylist: selected,
          playlists: [selected],
        );
      },
      act: (cubit) => cubit.removeTrackFromPlaylist(
        playlistId: 'pl_1',
        trackId: 'trk_1',
      ),
      expect: () => [
        isA<PlaylistsState>()
            .having((s) => s.isSubmitting, 'submitting', isTrue)
            .having(
                (s) => s.selectedPlaylist?.tracks.length, 'optimistic len', 1),
        isA<PlaylistsState>()
            .having((s) => s.isSubmitting, 'submitting', isFalse)
            .having(
                (s) => s.selectedPlaylist?.tracks.length, 'rolled back len', 2)
            .having(
              (s) => s.errorMessage,
              'error',
              'Something went wrong. Please try again',
            ),
      ],
    );

    blocTest<PlaylistsCubit, PlaylistsState>(
      'removeTrackFromPlaylist deletes playlist when last track is removed',
      build: () {
        when(
          () => removeTrack(
            playlistId: 'pl_1',
            trackId: 'trk_1',
          ),
        ).thenAnswer((_) async {});
        when(() => del('pl_1')).thenAnswer((_) async {});
        return buildCubit();
      },
      seed: () {
        final t1 = _track(id: 'trk_1');
        final selected = _playlist(id: 'pl_1', tracks: [t1], count: 1);
        return PlaylistsState.initial().copyWith(
          selectedPlaylist: selected,
          playlists: [selected],
        );
      },
      act: (cubit) => cubit.removeTrackFromPlaylist(
        playlistId: 'pl_1',
        trackId: 'trk_1',
      ),
      expect: () => [
        isA<PlaylistsState>()
            .having((s) => s.isSubmitting, 'submitting', isTrue)
            .having(
                (s) => s.selectedPlaylist?.tracks.length, 'optimistic len', 0),
        isA<PlaylistsState>()
            .having((s) => s.isSubmitting, 'submitting', isFalse)
            .having((s) => s.playlists, 'playlists', isEmpty)
            .having((s) => s.selectedPlaylist, 'selected', isNull)
            .having((s) => s.infoMessage, 'info', 'Playlist deleted'),
      ],
      verify: (_) {
        verify(() => del('pl_1')).called(1);
      },
    );

    blocTest<PlaylistsCubit, PlaylistsState>(
      'reorderTracks rolls back on failure',
      build: () {
        when(
          () => reorder(
            playlistId: 'pl_1',
            orderedTrackIds: ['trk_2', 'trk_1'],
          ),
        ).thenThrow(Exception('reorder failed'));
        return buildCubit();
      },
      seed: () {
        final t1 = _track(id: 'trk_1');
        final t2 = _track(id: 'trk_2');
        return PlaylistsState.initial().copyWith(
          selectedPlaylist: _playlist(id: 'pl_1', tracks: [t1, t2], count: 2),
        );
      },
      act: (cubit) {
        final t1 = _track(id: 'trk_1');
        final t2 = _track(id: 'trk_2');
        return cubit.reorderTracks(
          playlistId: 'pl_1',
          orderedTracks: [t2, t1],
        );
      },
      expect: () => [
        isA<PlaylistsState>()
            .having((s) => s.isReordering, 'reordering', isTrue),
        isA<PlaylistsState>()
            .having((s) => s.isReordering, 'reordering', isFalse)
            .having(
                (s) => s.selectedPlaylist!.tracks.first.id, 'first', 'trk_1')
            .having(
              (s) => s.errorMessage,
              'error',
              'Something went wrong. Please try again',
            ),
      ],
    );

    blocTest<PlaylistsCubit, PlaylistsState>(
      'reorderTracks emits success info when usecase succeeds',
      build: () {
        when(
          () => reorder(
            playlistId: 'pl_1',
            orderedTrackIds: ['trk_2', 'trk_1'],
          ),
        ).thenAnswer((_) async {});
        return buildCubit();
      },
      seed: () {
        final t1 = _track(id: 'trk_1');
        final t2 = _track(id: 'trk_2');
        return PlaylistsState.initial().copyWith(
          selectedPlaylist: _playlist(id: 'pl_1', tracks: [t1, t2], count: 2),
        );
      },
      act: (cubit) {
        final t1 = _track(id: 'trk_1');
        final t2 = _track(id: 'trk_2');
        return cubit.reorderTracks(
          playlistId: 'pl_1',
          orderedTracks: [t2, t1],
        );
      },
      expect: () => [
        isA<PlaylistsState>()
            .having((s) => s.isReordering, 'reordering', isTrue),
        isA<PlaylistsState>()
            .having((s) => s.isReordering, 'reordering', isFalse)
            .having((s) => s.infoMessage, 'info', 'Playlist reordered'),
      ],
    );

    blocTest<PlaylistsCubit, PlaylistsState>(
      'resolveSecretPlaylist loads and upserts playlist',
      build: () {
        when(() => resolveSecret('token_1'))
            .thenAnswer((_) async => _playlist(id: 'pl_secret', count: 4));
        return buildCubit();
      },
      act: (cubit) => cubit.resolveSecretPlaylist('token_1'),
      expect: () => [
        isA<PlaylistsState>()
            .having((s) => s.isLoadingDetails, 'loading details', isTrue),
        isA<PlaylistsState>()
            .having((s) => s.isLoadingDetails, 'loading details', isFalse)
            .having(
                (s) => s.selectedPlaylist?.playlistId, 'selected', 'pl_secret')
            .having((s) => s.playlists.first.playlistId, 'first list id',
                'pl_secret'),
      ],
    );

    test('resolveSecretPlaylist emits error on failure', () async {
      when(() => resolveSecret('bad_token'))
          .thenThrow(Exception('secret failed'));

      final cubit = buildCubit();
      await cubit.resolveSecretPlaylist('bad_token');

      expect(
        cubit.state.errorMessage,
        'Something went wrong. Please try again',
      );
      expect(cubit.state.isLoadingDetails, isFalse);
    });

    blocTest<PlaylistsCubit, PlaylistsState>(
      'loadEmbedCode stores embed snippet on success',
      build: () {
        when(() => embed('pl_1'))
            .thenAnswer((_) async => '<iframe src="embed"></iframe>');
        return buildCubit();
      },
      act: (cubit) => cubit.loadEmbedCode('pl_1'),
      expect: () => [
        isA<PlaylistsState>()
            .having((s) => s.isSubmitting, 'submitting', isTrue),
        isA<PlaylistsState>()
            .having((s) => s.isSubmitting, 'submitting', isFalse)
            .having((s) => s.embedCode, 'embed', contains('<iframe')),
      ],
    );

    blocTest<PlaylistsCubit, PlaylistsState>(
      'loadEmbedCode emits permission message on forbidden failure',
      build: () {
        when(() => embed('pl_1')).thenThrow(Exception('403 permission denied'));
        return buildCubit();
      },
      act: (cubit) => cubit.loadEmbedCode('pl_1'),
      expect: () => [
        isA<PlaylistsState>()
            .having((s) => s.isSubmitting, 'submitting', isTrue),
        isA<PlaylistsState>()
            .having((s) => s.isSubmitting, 'submitting', isFalse)
            .having(
              (s) => s.errorMessage,
              'error',
              'You do not have permission to do this',
            ),
      ],
    );

    blocTest<PlaylistsCubit, PlaylistsState>(
      'clearFeedback clears info and error messages',
      build: buildCubit,
      seed: () => PlaylistsState.initial().copyWith(
        errorMessage: 'error',
        infoMessage: 'info',
      ),
      act: (cubit) => cubit.clearFeedback(),
      expect: () => [
        isA<PlaylistsState>()
            .having((s) => s.errorMessage, 'error', isNull)
            .having((s) => s.infoMessage, 'info', isNull),
      ],
    );
  });
}
